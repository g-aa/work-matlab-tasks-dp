function [ retyrn_args ] = dp_main( )
 
%error = 0; % код ошибки

% перечень основных структур:
TR = struct('S_TR',     63000,...
            'U_RMS',    [115; 10.5],...
            'I_RMS',    [],...
            'size',     2,...
            'phases',   3,...
            'type',     {{'Y0';'D'}});
        
CFG = struct('F_base',[],'F_adc',[],'points',[],'file',[]);
SIGNAL(1:TR.size) = struct('current',[],'TA',[],'points',[],'side',[]);

    % переделать, удалить!!!
    SIGNAL(1).TA = [600, 5; 600, 5; 600, 5];
    SIGNAL(2).TA = [4000, 5; 4000, 5; 4000, 5];

% вычисление номинальных токов траносформатора (токи обмоток):
for i = 1:1:TR.size
    if(strcmp(TR.type(i),'Y0')||strcmp(TR.type(i),'Y'))
        % для соединения: 'Y0'/'Y'
        TR.I_RMS(i,1) = TR.S_TR/(TR.U_RMS(i,1)*sqrt(3));
    elseif (strcmp(TR.type(i),'D'))
        % для соединения: 'D'
        TR.I_RMS(i,1) = TR.S_TR/(TR.U_RMS(i,1)*3);
    end
end


% загрузка основных данных:
[ CFG , SIGNAL, error] = data_load( CFG, SIGNAL , TR);

% проверка на успешное выполнение функции data_load:
if (error < 0)
    disp('The application was stopted!')
    retyrn_args = 0;
    return;
end


% нормализация исходных данных:
i_relative = zeros(CFG.points,TR.size*TR.phases);
%i_zeros = zeros(CFG.points,TR.seze);

for i = 1:1:TR.size
    [ i_temp, ~ ] = normalization_fun( SIGNAL(i), TR );
    
    for j = 1:1:TR.phases
        i_relative(:,j + 3*(i - 1)) = i_temp(:,j);
    end
end
clear i_temp j;


% интегральное преобразование над исходными данными:
I_RMS = zeros(CFG.points,TR.size*TR.phases);
%I_abs = zeros(CFG.points,TR.size*TR.phases);

for i = 1:1:TR.size*TR.phases
    [ I_RMS(:,i) , ~ ] = fft_fun( i_relative(:,i), 'Rectangle', CFG.F_base, CFG.F_adc );
end


% определение дифференцального тока и тока сробатывания:
Id = zeros(CFG.points,TR.phases);
Is = zeros(CFG.points,TR.phases);

for i = 1:1:TR.phases
    [ Id(:,i), Is(:,i) ] = Id_Is( I_RMS(:,i), I_RMS(:,i + 3), 'abs_sum' );
end

% дифференциальный орган, уставки (f(x) = k*x + b):
DIFF_SETS = struct( 'k',   [0; 0.37; 0.5; 0],...
                    'b',   [0.465; 0; -0.592; 7]); 
                
tf_sig = zeros(CFG.points,TR.phases);
tf_sig = diff_relay( Id , Is, DIFF_SETS);


% построение результатов расчета:
txt = struct('title',[],'label',[],'legend',[]);

% исходные данные (дискретная осцилограмма):
txt.title = {'График мгновенных значений тока i vn(t)';
             'График мгновенных значений тока i nn(t)'};
txt.label = {'точки', 'i(t), А'; 'точки', 'i(t), А'};
txt.legend = {'фаза А'; 'фаза B'; 'фаза C'};         
print_3p( [SIGNAL(1).current, SIGNAL(2).current], 2, txt);

% приведенные исходные данные (дискретная осцилограмма):
txt.title = {'График мгновенных значений приведеннго тока i vn(t)';
             'График мгновенных значений приведеннго тока i nn(t)'};
txt.label = {'точки', 'i(t), о.е.'; 'точки', 'i(t), о.е.'};
txt.legend = {'фаза А'; 'фаза B'; 'фаза C'};         
print_3p( i_relative, 2, txt);

% действующее значение сигнала:
txt.title = {'График действующего значения тока I vn(t)';
             'График действующего значения тока I nn(t)'};
txt.label = {'точки', 'I(t), о.е.'; 'точки', 'I(t), о.е.'};
txt.legend = {'фаза А'; 'фаза B'; 'фаза C'};         
print_3p( abs(I_RMS), 2, txt);


retyrn_args = 0;
end