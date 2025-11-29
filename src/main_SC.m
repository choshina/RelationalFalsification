addpath('/Users/zhenya/git/AICPSRobustness/');
InitBreach

T=35;
Ts=0.1;
min_Fs=3.99;
max_Fs=4.01;
mdl = 'SC_FFNN_trainlm_10_10_10_10_Dec_8_R2021a';
Br = BreachSimulinkSystem(mdl);
Br.Sys.tspan =0:0.1:35;
input_gen.type = 'UniStep';
input_gen.cp = 3;
Br.SetInputGen(input_gen);
for cpi = 0:input_gen.cp -1
        Fs_sig = strcat('Fs_u',num2str(cpi));
        Br.SetParamRanges({Fs_sig},[3.99 4.01]);
end
spec = 'alw_[30,35](pressure[t] >= 87 and pressure[t] <= 87.5)';
phi = STL_Formula('phi',spec);
trials = 1;
filename = 'SC_FFNN_trainlm_10_10_10_10_Dec_8_R2021a_TwoInput_SC1_0.03_0.0025';
falsified = [];
time = [];
obj_best = [];
num_sim = [];
epsilon = 0.03;
threshold = 0.0025;
for n = 1:trials
        falsif_pb = TwoInputProblem(Br, phi,epsilon,threshold);
        falsif_pb.max_time = 600;
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

%result = table(filename, spec, falsified, time, num_sim, obj_best);