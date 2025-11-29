classdef DPTwoInputProblem < FalsificationProblem
    properties
        epsilon

        threshold
        falsified

        X_total_log
        obj_total_log
    end

    methods
        function this = DPTwoInputProblem(BrSet, phi, ep, threshold)
            this = this@FalsificationProblem(BrSet, phi);
            this.epsilon = (this.ub - this.lb)*ep;
            this.threshold = threshold;
            this.falsified = false;
            this.X_total_log = [];
            this.obj_total_log = [];
            rng('default');
            rng(round(rem(now, 1)*1000000));
        end

        function solve(this)
            rfprintf_reset();
            % reset time
            this.ResetTimeSpent();
            this.falsified = false;

            while this.time_spent < this.max_time
                this.resetLog();
                this.x0 = this.set_X0();
                solver_opt = this.setCMAES();
                
                [x, fval, counteval, stopflag, out, bestever] = cmaes(this.objective, this.x0', [], solver_opt);
                res = struct('x',x, 'fval',fval, 'counteval', counteval,  'stopflag', stopflag, 'out', out, 'bestever', bestever);
                this.res=res;
                if min(res.fval) < -this.threshold && this.satisfy(res.x)
                    this.falsified = true;
                    res.x
                    break;
                end
            end
        end

        function resetLog(this)
            this.X_total_log = [this.X_total_log this.X_log];
            this.obj_total_log = [this.obj_total_log this.obj_log];
            this.X_log = [];
            this.obj_log = [];
            this.x_best = [];
            this.obj_best = inf;
        end

        

        function sat = satisfy(this, x)
            sat = true;
            for i = 1:numel(x)/2
                if abs(x(i) - x(i + numel(x)/2)) > this.epsilon(i)
                    sat = false;
                    break;
                end
            end
        end

        function x0 = set_X0(this)
            x1 = this.lb + rand(numel(this.lb), 1).*(this.ub - this.lb);
            x2 = this.lb + rand(numel(this.lb), 1).*(this.ub - this.lb);
            x0 = [x1; x2];
        end

        function solver_opt = setCMAES(this)
            l_ = [this.lb; this.lb];
            u_ = [this.ub; this.ub];
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
                x_real = x;

                stlv1 = this.objective_fn(x_real(1:x_num/2));
                stlv2 = this.objective_fn(x_real(x_num/2+1 : x_num));
                fval = - abs(stlv1 - stlv2);

                % logging and updating best
                this.LogX(x, fval);
 
                % update status
                if rem(this.nb_obj_eval,this.freq_update)==0
                    this.display_status();
                end
                
            end
        end

        function LogX(this, x, fval)
            this.LogX@FalsificationProblem(x, fval);
            this.nb_obj_eval= numel(this.obj_total_log) + numel(this.obj_log);
        end
        
        function b = stopping(this)
            b =  (this.time_spent >= this.max_time) ||...
            (this.nb_obj_eval>= this.max_obj_eval) ||...
            (this.obj_best < -this.threshold);
        end


    end
end