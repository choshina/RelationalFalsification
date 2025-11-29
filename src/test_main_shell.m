#!/bin/sh
csv=$1
matlab -nodesktop -nosplash <<EOF
% ワークスペースの変数をクリアする
clear;
% CPSTutorialのあるリポジトリにパスを置き換える
addpath(genpath('C:\Users\onepi\Documents\test'));
% Breachを起動する
InitBreach;


% simulink model を設定する
mdl = 'nn_fuel_control_3_15_1';

% model のパラメータを設定する
fuel_inj_tol=1.0;
MAF_sensor_tol=1.0;
AF_sensor_tol=1.0;
pump_tol=1;
kappa_tol=1;
tau_ww_tol=1;
fault_time=50;
kp=0.04;
ki=0.14;
T = 50;

epsilon = 0.03;

%加えた
input_name = {'Engine_Speed', 'Pedal_Angle'};
input_range = [900, 1100; 10.0, 60];


%dimension1_LBounds = 900.0; % 最小値
%dimension1_UBounds = 1100.0; % 最大値

%dimension2_LBounds = 10.0; % 最小値
%dimension2_UBounds = 60.0; % 最大値

input_type = 'UniStep';
input_cp = 3;

time_span = 0:.01:50;

spec1 = 'alw_[0,30](AF[t] < 1.2*14.7 and AF[t] > 0.8*14.7)';
spec2 = 'not alw_[0,30](AF[t] < 1.2*14.7 and AF[t] > 0.8*14.7)';

max_time = 100; %1回あたりのcmaesの時間上限が100秒
max_fun_evals = 10; %algo2,3,4での回数の上限が10回


trials = 1;
filename = 'fuel_control_3_15_1_breach_';  % ファイル名の基本部分
D = [];
input_D = [];

best_D = 0;
input_best_D = [];

for n = 1:trials
    d = afc_algo1(mdl, epsilon, input_name, input_range, input_type, input_cp, spec1, spec2, time_span, max_time, max_fun_evals);
    %d = afc_algo2(mdl, epsilon, input_name, input_range, input_type, input_cp, spec1, spec2, time_span, max_time, max_fun_evals);
    %d = afc_algo3(mdl, epsilon, input_name, input_range, input_type, input_cp, spec1, spec2, time_span, max_time, max_fun_evals);
    %d = afc_algo4(mdl, epsilon, input_name, input_range, input_type, input_cp, spec1, spec2, time_span, max_time, max_fun_evals);
    
    %afc_only_sim(mdl, epsilon, dimension1_LBounds, dimension1_UBounds, dimension2_LBounds, dimension2_UBounds, input_type, input_cp, spec1, spec2, time_span, max_time, global_bujet);


    D = [D; d];

    if best_D < d
        best_D = d;
    end
end


spec = {spec};
filename = {filename};
result = table(filename, spec, falsified, time, obj_best);

writetable(result, '$csv', 'Delimiter', ';');
quit force
EOF