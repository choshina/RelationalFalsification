
classdef ConstrainedProblem < FalsificationProblem

    properties
        % Relational constraint:
        % abs(u1 - u2) <= epsilon
        epsilon

        % Falsification threshold
        threshold

        % Maximum number of patternsearch iterations
        local_budget

        % Relational falsification logs.
        % Each column of X_total_log is [u1; u2].
        X_total_log
        obj_total_log

        % Best relational input pair found.
        X_best_pair

        % Robustness values corresponding to X_best_pair.
        r_best_pair

        % Whether the relational property is falsified.
        falsified
    end

    methods

        %% Constructor
        function this = ConstrainedProblem( ...
                BrSet, phi, ep, threshold, locBud)

            this = this@FalsificationProblem(BrSet, phi);

            this.epsilon = (this.ub - this.lb) * ep;
            this.threshold = threshold;
            this.local_budget = locBud;

            this.X_total_log = [];
            this.obj_total_log = [];

            this.X_best_pair = [];
            this.r_best_pair = [];

            this.falsified = false;

            % Use our relational objective wrapper.
            this.objective = @(x) this.objective_wrapper(x);

            rng('default');
            rng(round(rem(now, 1) * 1000000));

        end


        %% Solve
        function res = solve(this)

            rfprintf_reset();

            this.ResetTimeSpent();

            % Reset relational optimization state.
            this.falsified = false;

            this.X_total_log = [];
            this.obj_total_log = [];

            this.X_best_pair = [];
            this.r_best_pair = [];

            this.obj_best = inf;
            this.x_best = [];

            this.nb_obj_eval = 0;

            n = numel(this.lb);

            % -------------------------------------------------
            % Joint optimization variables:
            %
            % x = [u1; u2]
            %
            % min -abs(r(u1) - r(u2))
            %
            % subject to:
            %   lb <= u1 <= ub
            %   lb <= u2 <= ub
            %   abs(u1-u2) <= epsilon
            % -------------------------------------------------

            % Linear relational constraints:
            %
            %   u1 - u2 <= epsilon
            %   u2 - u1 <= epsilon

            I = eye(n);

            A = [ I, -I;
                 -I,  I ];

            b = [this.epsilon;
                 this.epsilon];

            % Box constraints.
            lb_joint = [this.lb; this.lb];
            ub_joint = [this.ub; this.ub];

            % Generate a feasible random initial point.
            u1 = this.lb + rand(n, 1) .* (this.ub - this.lb);

            lower_u2 = max(this.lb, u1 - this.epsilon);
            upper_u2 = min(this.ub, u1 + this.epsilon);

            u2 = lower_u2 + rand(n, 1) .* ...
                (upper_u2 - lower_u2);

            x0 = [u1; u2];

            % -------------------------------------------------
            % Pattern Search options
            % -------------------------------------------------

            nvars = 2 * n;

            % Use local_budget as the iteration budget,
            % corresponding to RandomProblem's StopIter.
            %
            % The inherited max_obj_eval is an additional
            % global evaluation limit.

            defaultMaxEval = 2000 * nvars;

            if isfinite(this.max_obj_eval)
                maxEval = min(defaultMaxEval, ...
                              max(1, this.max_obj_eval));
            else
                maxEval = defaultMaxEval;
            end

            options = optimoptions('patternsearch', ...
                'Display', 'off', ...
                'MaxIterations', this.local_budget, ...
                'MaxFunctionEvaluations', maxEval, ...
                'OutputFcn', @(optimValues, options, flag) ...
                    this.outputFcn(optimValues, options, flag));

            % -------------------------------------------------
            % Run constrained optimization
            % -------------------------------------------------

            [x, fval, exitflag, output] = patternsearch( ...
                this.objective, ...
                x0, ...
                A, b, ...
                [], [], ...
                lb_joint, ub_joint, ...
                [], ...
                options);

            % Update final time.
            this.time_spent = toc(this.time_start);

            % Best pair is maintained by objective_wrapper.
            % Use returned solution as fallback if necessary.
            if isempty(this.X_best_pair) && ...
                    numel(x) == 2*n

                this.X_best_pair = x(:);

                u1_best = x(1:n);
                u2_best = x(n+1:2*n);

                r1 = this.objective_fn(u1_best);
                r2 = this.objective_fn(u2_best);

                this.r_best_pair = [r1; r2];
                this.obj_best = -abs(r1-r2);
            end

            this.falsified = ...
                ~isempty(this.obj_best) && ...
                (this.obj_best < -this.threshold);

            % Return result.
            res = struct( ...
                'x', x, ...
                'fval', fval, ...
                'exitflag', exitflag, ...
                'output', output, ...
                'X_best_pair', this.X_best_pair, ...
                'r_best_pair', this.r_best_pair, ...
                'obj_best', this.obj_best, ...
                'falsified', this.falsified, ...
                'X_total_log', this.X_total_log, ...
                'obj_total_log', this.obj_total_log, ...
                'nb_obj_eval', this.nb_obj_eval, ...
                'time_spent', this.time_spent);

            this.res = res;

            if strcmpi(this.display, 'on')
                fprintf('\nConstrainedProblem finished.\n');
                fprintf('Objective evaluations: %d\n', ...
                    this.nb_obj_eval);
                fprintf('Best objective: %g\n', ...
                    this.obj_best);
                fprintf('Best robustness difference: %g\n', ...
                    -this.obj_best);
                fprintf('Falsified: %d\n', ...
                    this.falsified);
            end

        end


        %% Relational objective wrapper
        function fval = objective_wrapper(this, x)

            % Check stopping conditions before simulation.
            if this.stopping()
                fval = this.obj_best;
                return;
            end

            x = x(:);

            n = numel(this.lb);

            u1 = x(1:n);
            u2 = x(n+1:2*n);

            % Evaluate robustness of both inputs.
            r1 = this.objective_fn(u1);
            r2 = this.objective_fn(u2);

            % Relational objective.
            fval = -abs(r1 - r2);

            % Avoid propagating NaN to patternsearch.
            if isnan(fval)
                fval = inf;
            end

            % Log the evaluated pair.
            this.X_total_log(:, end+1) = x;
            this.obj_total_log(end+1) = fval;

            % Update evaluation count and elapsed time.
            this.nb_obj_eval = this.nb_obj_eval + 1;
            this.time_spent = toc(this.time_start);

            % Update best solution.
            if fval < this.obj_best

                this.obj_best = fval;
                this.x_best = x;

                this.X_best_pair = x;
                this.r_best_pair = [r1; r2];

            end

            % Update falsification status.
            if fval < -this.threshold
                this.falsified = true;
            end

            % Optional status display.
            if strcmpi(this.display, 'on') && ...
                    rem(this.nb_obj_eval, this.freq_update) == 0

                fprintf(['Evaluations: %d, ' ...
                         'Best objective: %g, ' ...
                         'Time: %.2f s\n'], ...
                         this.nb_obj_eval, ...
                         this.obj_best, ...
                         this.time_spent);
            end

        end


        %% Stopping condition
        function b = stopping(this)

            this.time_spent = toc(this.time_start);

            b = ...
                (this.time_spent >= this.max_time) || ...
                (this.nb_obj_eval >= this.max_obj_eval) || ...
                this.falsified;

        end


        %% Pattern Search output function
        function [stop, options, optchanged] = ...
                outputFcn(this, optimValues, options, flag)

            stop = false;
            optchanged = false;

            if strcmp(flag, 'iter') || ...
                    strcmp(flag, 'interrupt')

                stop = this.stopping();

            end

        end

    end

end

