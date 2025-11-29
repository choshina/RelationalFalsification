function f = afc_algo2(mdl, epsilon, input_name, input_range, input_type, input_cp, spec1, spec2, time_span, max_time, MaxFunEvals)

dimension_num = length(input_name); %インプットの次元数

% CMA-ESのオプションを設定
opts = cmaes;

% 各次元ごとの下限と上限を設定
opts.LBounds = zeros(dimension_num * input_cp * 2, 1); % 下限値を初期化
opts.UBounds = zeros(dimension_num * input_cp * 2, 1); % 上限値を初期化
for d = 1:dimension_num
    for i = 0:input_cp - 1
        opts.LBounds(2*d-1 + i*dimension_num*2) = input_range(d, 1);
        opts.LBounds(2*d + i*dimension_num*2) = -(input_range(d, 2) - input_range(d, 1))*epsilon;
        opts.UBounds(2*d-1 + i*dimension_num*2) = input_range(d, 2);
        opts.UBounds(2*d + i*dimension_num*2) = (input_range(d, 2) - input_range(d, 1))*epsilon;
    end
end

opts.MaxIter = 1;  % 繰り返しの最大回数を1回に設定
opts.MaxFunEvals = MaxFunEvals;  % 関数評価の最大回数を設定

% 初期化パラメータ(インプットの範囲からランダムに設定)
x0 = zeros(dimension_num * input_cp * 2, 1);
for d = 1:dimension_num
    for i = 0:input_cp - 1
        x0(2*d-1 + i*dimension_num*2) = round(input_range(d, 1) + (input_range(d, 2) - input_range(d, 1)) * rand, 1);
        x0(2*d + i*dimension_num*2) = round((input_range(d, 2) - input_range(d, 1)) * epsilon * (2 * rand - 1), 1);
    end
end
disp(x0);

% CMA-ESアルゴリズムの実行
[xmin, fmin, counteval, stopflag, out, bestever] = cmaes(@(x) objective_function_algo2(mdl, input_name, input_range, input_type, input_cp, spec1, time_span, x), x0, [], opts);

% 結果の表示
disp(['ベストなインプット: ', mat2str(xmin)]);

mapping_input = mapping_algo2(xmin, input_cp, input_name, input_range);
disp(['マッピング後のインプット: ', mat2str(mapping_input)]);
disp(['ベストな差: ', num2str(-1*fmin)]);

f = -1*fmin;

end



function f = objective_function_algo2(mdl, input_name, input_range, input_type, input_cp, spec1, time_span, x)   
    
%インプットの調整
x = mapping_algo2(x, input_cp, input_name, input_range);


% Br1としてBr1eachSimulinkSystemクラスのインスタンスを生成する
Br1 = BreachSimulinkSystem(mdl);

% シミュレーションのtime spanを設定する
Br1.Sys.tspan = time_span;

% インプットのタイプを設定する
input_gen.type = input_type;
input_gen.cp = input_cp;

% このインプットの設定をBr1に渡す
Br1.SetInputGen(input_gen);

dimension_num = length(input_name); %インプットの次元数
% インプットの範囲を指定する
for d = 1:dimension_num
    for cpi = 0:input_gen.cp - 1
        input_sig = strcat(input_name{d}, '_u', num2str(cpi));
        Br1.SetParamRanges({input_sig},[x(2*d-1 + cpi*dimension_num*2) x(2*d-1 + cpi*dimension_num*2)]);
    end
end
    
% STL_Formulaクラスのインスタンスを生成し,このSTL式の名前をphiとする。
phi = STL_Formula('phi',spec1);

% シミュレーションを実行する
Br1.Sim();
stl1 = Br1.CheckSpec(phi);



% Br2としてBr2eachSimulinkSystemクラスのインスタンスを生成する
Br2 = BreachSimulinkSystem(mdl);

% シミュレーションのtime spanを設定する
Br2.Sys.tspan = time_span;

% インプットのタイプを設定する
input_gen.type = input_type;
input_gen.cp = input_cp;

% このインプットの設定をBr2に渡す
Br2.SetInputGen(input_gen);

% インプットの範囲を指定する
for d = 1:dimension_num
    for cpi = 0:input_gen.cp - 1
        input_sig = strcat(input_name{d}, '_u',num2str(cpi));
        Br2.SetParamRanges({input_sig},[x(2*d-1 + cpi*dimension_num*2)+x(2*d + cpi*dimension_num*2) x(2*d-1 + cpi*dimension_num*2)+x(2*d + cpi*dimension_num*2)]);
    end
end

% STL_Formulaクラスのインスタンスを生成し,このSTL式の名前をphiとする。
phi = STL_Formula('phi',spec1);

% シミュレーションを実行する
Br2.Sim();
stl2 = Br2.CheckSpec(phi);


f = - abs(stl1 - stl2);

disp(['1つ目:', num2str(stl1), ' 2つ目:', num2str(stl2), ' 差:', num2str(-1*f)]);
end

function f = mapping_algo2(x, input_cp, input_name, input_range)

dimension_num = length(input_name); %インプットの次元数
for d = 1:dimension_num
    for i = 0:input_cp - 1
        if 0 <= x(2*d + i*dimension_num*2)
            x(2*d-1 + i*dimension_num*2) = input_range(d, 1) + (x(2*d-1 + i*dimension_num*2) - input_range(d, 1)) * ((input_range(d, 2) - input_range(d, 1)) - x(2*d + i*dimension_num*2)) / (input_range(d, 2) - input_range(d, 1));
        else
            x(2*d-1 + i*dimension_num*2) = input_range(d, 1) + (x(2*d-1 + i*dimension_num*2) - input_range(d, 1)) * ((input_range(d, 2) - input_range(d, 1)) + x(2*d + i*dimension_num*2)) / (input_range(d, 2) - input_range(d, 1)) - x(2*d + i*dimension_num*2);
        end
    end
end

f = x;
end
