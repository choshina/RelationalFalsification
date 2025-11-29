classdef RandomProblem < FalsificationProblem
     properties  
        epsilon

        threshold

        local_budget

        basic_X
        basic_stlv

        X_total_log
        obj_total_log

        falsified
     end

     methods
         function this = RandomProblem(BrSet, phi, ep, threshold, locBud)
             this = this@FalsificationProblem(BrSet, phi);
             this.epsilon = (this.ub - this.lb)*ep;
             this.threshold = threshold;
             this.local_budget = locBud;
             this.basic_X = [];
             this.basic_stlv = [];
             this.falsified = false;

             this.X_total_log = [];
             this.obj_total_log = [];

             rng('default');
             rng(round(rem(now, 1)*1000000));
         end

        function res = solve(this)
            rfprintf_reset();         
            % reset time
            this.ResetTimeSpent();
            this.falsified = false;
         
            while this.time_spent < this.max_time
                this.resetLog();

                this.basic_X = this.lb + rand(numel(this.lb), 1).*(this.ub - this.lb);
                this.basic_stlv = this.objective_fn(this.basic_X);
                [solver_opt, x0] = this.setCMAES();
            
                [x, fval, counteval, stopflag, out, bestever] = cmaes(this.objective, x0', [], solver_opt);
                res = struct('x',x, 'fval',fval, 'counteval', counteval,  'stopflag', stopflag, 'out', out, 'bestever', bestever);
  
                if min(res.fval) < -this.threshold
                    this.falsified = true;
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


        function [solver_opt, x0] = setCMAES(this)
            %disp('Setting options for cmaes solver - use help cmaes for details');
            l_ = this.basic_X - this.epsilon;
            for i = 1:numel(l_)
                if l_(i) < this.lb(i)
                    l_(i) = this.lb(i);
                end
            end
            u_ = this.basic_X + this.epsilon;
            for j = 1:numel(u_)
                if u_(j) >  this.ub(j)
                    u_(j) = this.ub(j);
                end
            end

            solver_opt = cmaes();
            solver_opt.Seed = round(rem(now,1)*1000000);
            solver_opt.LBounds = l_;
            solver_opt.UBounds = u_;
            solver_opt.StopIter = this.local_budget;

            x0 = l_ + rand(numel(l_), 1).*(u_ - l_);
        end


        function fval = objective_wrapper(this, x)
            if this.stopping()==true
                fval = this.obj_best;
            else
                % calling actual objective function
                %fval = this.objective_fn(x);
                stlv = this.objective_fn(x);
                fval = -abs(stlv - this.basic_stlv);
                
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