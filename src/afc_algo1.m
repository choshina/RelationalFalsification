function f = afc_algo1(mdl, epsilon, input_name, input_range, input_type, input_cp, spec1, spec2, time_span, max_time, max_fun_evals)

dimension_num = numel(input_name); %インプットの次元数

basis_input = ones(dimension_num,input_cp);

for d = 1:dimension_num
    for i = 1:input_cp
        basis_input(d, i) = round(input_range(d, 1) + (input_range(d, 2) - input_range(d, 1)) * rand, 1);
    end
end

%まず、基準となるインプットのSTL値を求める
% BrbasisとしてBreachSimulinkSystemクラスのインスタンスを生成する
Brbasis = BreachSimulinkSystem(mdl);
% シミュレーションのtime spanを設定する
Brbasis.Sys.tspan = time_span;
% インプットのタイプを設定する
% ここではUniStepにし、ステップ数は3にする
input_gen.type = input_type;
input_gen.cp = input_cp; %inputのステップ数を3に変更した。
% このインプットの設定をBrに渡す
Brbasis.SetInputGen(input_gen);
for d = 1:dimension_num
    for cpi = 0:input_gen.cp - 1
        input_sig = strcat(input_name{d}, '_u', num2str(cpi));
        Brbasis.SetParamRanges({input_sig},[basis_input(d, cpi+1) basis_input(d, cpi+1)]);
    end
end

% STL_Formulaクラスのインスタンスを生成し,このSTL式の名前をphiとする。
phi = STL_Formula('phi', spec1);

Brbasis.Sim();
stl_basis = Brbasis.CheckSpec(phi);
disp(mat2str(stl_basis));



%% perform falsification
% BrとしてBreachSimulinkSystemクラスのインスタンスを生成する
Br = BreachSimulinkSystem(mdl);

% シミュレーションのtime spanを設定する
Br.Sys.tspan = time_span;

% インプットのタイプを設定する
% ここではUniStepにし、ステップ数は3にする
input_gen.type = input_type;
input_gen.cp = input_cp; %inputのステップ数を3に変更した。

% このインプットの設定をBrに渡す
Br.SetInputGen(input_gen);


%基準のインプットによるεの範囲がインプットの範囲を超えている場合は調整する必要がある。
for d = 1:dimension_num
    for cpi = 0:input_gen.cp - 1
        input_sig = strcat(input_name{d}, '_u',num2str(cpi));
        if basis_input(1, cpi+1)-(input_range(d, 2) - input_range(d, 1)) * epsilon < input_range(d, 1)
            Br.SetParamRanges({input_sig},[input_range(d, 1) basis_input(d, cpi+1)+(input_range(d, 2) - input_range(d, 1)) * epsilon]);
        elseif input_range(d, 2) < basis_input(d, cpi+1)+(input_range(d, 2) - input_range(d, 1)) * epsilon
            Br.SetParamRanges({input_sig},[basis_input(d, cpi+1)-(input_range(d, 2) - input_range(d, 1)) * epsilon input_range(d, 2)]);
            elses
            Br.SetParamRanges({input_sig},[basis_input(d, cpi+1)-(input_range(d, 2) - input_range(d, 1)) * epsilon basis_input(d, cpi+1)+(input_range(d, 2) - input_range(d, 1)) * epsilon]);
        end
    end
end

%まず最小のSTL値を求める

% STL_Formulaクラスのインスタンスを生成し,このSTL式の名前をphiとする。
phi = STL_Formula('phi',spec1);

% FalsificationProblemクラスのfalsification instanceを生成し、名前をfalsif_pbとする。
falsif_pb_min = FalsificationProblem(Br,phi);

% falsificationの時間の上限を設定する
falsif_pb_min.max_time = max_time;

% 山登りアルゴリズムを設定する。ここではcmaesを使う。
falsif_pb_min.setup_solver('cmaes');

% falsificationを実行する(STL値を最小化するように変更する必要がある)
falsif_pb_min.solve();

% falsif_pb.obj_minには今までで最小のSTL値が記録されている





%次に、最大のSTL値を求める
% specification を設定する(notを先頭に着けることで目標関数の正負を反転させる)    
% STL_Formulaクラスのインスタンスを生成し,このSTL式の名前をphiとする。
phi = STL_Formula('phi',spec2);

% FalsificationProblemクラスのfalsification instanceを生成し、名前をfalsif_pbとする。
falsif_pb_max = FalsificationProblem(Br,phi);

% falsificationの時間の上限を設定する
falsif_pb_max.max_time = max_time;

% 山登りアルゴリズムを設定する。ここではcmaesを使う。
falsif_pb_max.setup_solver('cmaes');

% falsificationを実行する(ロバストネスを最大化するようにしている)
falsif_pb_max.solve();

% falsif_pb.obj_maxには今までで最大のSTL値が記録されている




%最大の差であるDを求める。
if falsif_pb_max.obj_best*(-1) - stl_basis >= stl_basis - falsif_pb_min.obj_best 
    D = falsif_pb_max.obj_best*(-1) - stl_basis;
else
    D = stl_basis - falsif_pb_min.obj_best;
end


fprintf('Dの値: %f\n', D);
f = D;
