classdef InputEpsilonProblem < FalsificationProblem

    properties
        epsilon

        threshold
        map_param 

        falsified
    end

    methods
        function this = InputEpsilonProblem(BrSet, phi, ep, threshold, mp)
            this = this@FalsificationProblem(BrSet, phi);
            this.epsilon = (this.ub - this.lb)*ep;
            this.threshold = threshold;
            this.map_param = mp;
            this.falsified = false;

            rng('default');
            rng(round(rem(now, 1)*1000000));
        end

        function solve(this)
            rfprintf_reset();
            % reset time
            this.ResetTimeSpent();
            this.falsified = false;

            this.x0 = this.set_X0();
            solver_opt = this.setCMAES();
            
            [x, fval, counteval, stopflag, out, bestever] = cmaes(this.objective, this.x0', [], solver_opt);
            res = struct('x',x, 'fval',fval, 'counteval', counteval,  'stopflag', stopflag, 'out', out, 'bestever', bestever);
            this.res=res;
            if res.fval < -this.threshold
                this.falsified = true;
            end
        end

        function x0 = set_X0(this)
            x1 = this.lb + rand(numel(this.lb),1).*(this.ub - this.lb);
            x2 = -this.epsilon + rand(numel(this.lb), 1).*(2*this.epsilon);
            x0 = [x1 ;x2];
        end

        function solver_opt = setCMAES(this)
            l_ = [this.lb; -this.epsilon];
            u_ = [this.ub; this.epsilon];
            solver_opt = cmaes();
            solver_opt.Seed = round(rem(now,1)*1000000);
            solver_opt.LBounds = l_;
            solver_opt.UBounds = u_;
        end

        
        function fval = objective_wrapper(this, x)
            if this.stopping()==true
                fval = this.obj_best;
            else
                % calling actual objective function
                %fval = this.objective_fn(x);
                x_num = numel(x);
                x_real = this.mapping(x);

                stlv1 = this.objective_fn(x_real(1:x_num/2));
                stlv2 = this.objective_fn(x_real(1:x_num/2) + x_real((x_num/2)+1: x_num));
                fval = - abs(stlv1 - stlv2);

                % logging and updating best
                this.LogX(x, fval);
 
                % update status
                if rem(this.nb_obj_eval,this.freq_update)==0
                    this.display_status();
                end
                
            end
        end

        function x_real = mapping(this, x)
            half = numel(x)/2;
            x_real = x;
            if this.map_param == 1
                for i = 1:half % vertical mapping
                    if x(i) < this.lb(i) + this.epsilon(i)
                        x_real(i) = x(i);
                        x_real(i+half) = this.epsilon(i) - ((this.epsilon(i) - x(i+half))*(this.epsilon(i) + x(i)-this.lb(i))/(2*this.epsilon(i)));
                    elseif x(i) >  this.ub(i) - this.epsilon(i)
                        x_real(i) = x(i);
                        x_real(i+half) = ((x(i+half)+this.epsilon(i))*(this.epsilon(i) + this.ub(i) - x(i))/(2*this.epsilon(i))) - this.epsilon(i);
                    else
                        x_real(i) = x(i);
                        x_real(i+half) = x(i+half);
                    end
                        
                end
            else
                for i = 1:half % horizontal mapping
                    x_real(i+half) = x(i+half);
                    if x(i+half) > 0
                        x_real(i) = (this.ub(i) - this.lb(i) - x(i+half))*(x(i) - this.lb(i))/(this.ub(i) - this.lb(i)) + this.lb(i);
                    elseif x(i+half) < 0
                        x_real(i) = this.ub(i) - (this.ub(i) - this.lb(i) + x(i+half))*(this.ub(i) - x(i))/(this.ub(i) - this.lb(i));
                    else
                        x_real(i) = x(i);
                    end
                end
            end
            
        end
        
        function b = stopping(this)
            b =  (this.time_spent >= this.max_time) ||...
            (this.nb_obj_eval>= this.max_obj_eval) ||...
            (this.obj_best < -this.threshold);
        end


    end

end
