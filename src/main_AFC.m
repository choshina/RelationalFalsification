clear;
addpath(genpath('/Users/zhenya/git/AICPSRobustness/'));
InitBreach;

fuel_inj_tol=1.0;
MAF_sensor_tol=1.0;
AF_sensor_tol=1.0;
pump_tol=1;
kappa_tol=1;
tau_ww_tol=1;
fault_time=50;
kp=0.04;
ki=0.14;
T=50;
mdl = 'nn_fuel_control_3_15_1';
Br = BreachSimulinkSystem(mdl);
Br.Sys.tspan =0:.01:50;
input_gen.type = 'UniStep';
input_gen.cp = 3;
Br.SetInputGen(input_gen);
for cpi = 0:input_gen.cp -1
	Engine_Speed_sig = strcat('Engine_Speed_u',num2str(cpi));
	Br.SetParamRanges({Engine_Speed_sig},[900.0 1100.0]);
	Pedal_Angle_sig = strcat('Pedal_Angle_u',num2str(cpi));
	Br.SetParamRanges({Pedal_Angle_sig},[8.8 70.0]);
end
spec = 'alw_[0,30](AF[t] < 1.2*14.7 and AF[t] > 0.8*14.7)';
phi = STL_Formula('phi',spec);
trials = 1;
filename = 'nn_fuel_control_3_15_1_Random_AFC1_0.03_1';
falsified = [];
time = [];
obj_best = [];
num_sim = [];
locBudget = 10;
epsilon = 0.03;
threshold = 1;
for n = 1:trials
	falsif_pb = TwoInputProblem(Br,phi,epsilon,threshold);
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