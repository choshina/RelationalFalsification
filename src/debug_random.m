clear;
addpath(genpath('/Users/zhenya/git/AICPSRobustness'));
InitBreach;

T=50;
Ts=0.1;
v_set=30;
t_gap=1.4;
D_default=10;
x0_lead=70;
v0_lead=28;
x0_ego=10;
v0_ego=22;
amin_lead=-1;
amax_lead=1;
amin_ego=-3;
amax_ego=2;
x_offset=1;
y_offset=1;
x_gain=1;
y_gain=1;

mdl = 'nncACCsystem_4_30_R2021a';
Br = BreachSimulinkSystem(mdl);
Br.Sys.tspan =0:0.1:50;
input_gen.type = 'UniStep';
input_gen.cp = 3;
Br.SetInputGen(input_gen);
for cpi = 0:input_gen.cp -1
        in_lead_sig = strcat('in_lead_u',num2str(cpi));
        Br.SetParamRanges({in_lead_sig},[-1.0 1.0]);
end
spec = 'alw_[0,50]((d_rel[t] - 1.4 * v_ego[t] >= 10) and v_ego[t] <= 30.1)';
phi = STL_Formula('phi',spec);
trials = 10;
filename = 'nncACCsystem_4_30_R2021a_Random_ACC1_0.03_1.2';
falsified = [];
time = [];
obj_best = [];
num_sim = [];
locBudget = 3;
epsilon = 0.03;
threshold = 1.2;
for n = 1:trials
        falsif_pb = RandomProblem(Br,phi,epsilon,threshold,locBudget);
        falsif_pb.max_time = 60;
        falsif_pb.setup_solver('cmaes');
        falsif_pb.solve();
        if falsif_pb.falsified == true
                falsified = [falsified;1];
        else
                falsified = [falsified;0];
        end
        num_sim = [num_sim;falsif_pb.nb_obj_eval];
        time = [time;falsif_pb.time_spent];
        obj_best = [obj_best;falsif_pb.obj_best];
end