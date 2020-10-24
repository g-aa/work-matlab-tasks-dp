function [ output_args ] = main_fun( )

% перечень параметров силового трансформатора:
TR = struct('S_tr',63,'U_vn',115,'U_nn',10.5,'windings','Y0/D-11');
TA = struct('I1_vn',600,'I2_vn',5,'I1_nn',4000,'I2_nn',5);
CFG = struct('F_base',[],'F_adc',[],'size',[]);

% чтение парметров из файла:
fp = fopen('3.cfg','r');
str = textscan(fp,'%s','Delimiter','\n');
CFG.F_base = int32(str2double(str{1,1}{9,1}));
CFG.F_adc = int32(str2double(str{1,1}{11,1}));

% чтение массива данных:
Array = load('3.dat');
CFG.size = size(Array,1);

% выделение массивов токов:
i_vn = Array(:,3:5);  % Токи фаз 'А', 'B', 'C' стороны вн
i_nn = Array(:,6:8);  % Токи фаз 'А', 'B', 'C' стороны нн

% вывод результатов расчита
label_1 = {'График мгновенного значения тока i vn(t)'; 'точки'; 'i(t), А'};
label_2 = {'График мгновенного значения тока i nn(t)'; 'точки'; 'i(t), А'};
phases = {'фаза А', 'фаза B', 'фаза C'};
print_3p( i_vn, i_nn, [label_1, label_2] , phases);


% инициализация приведенного массива токов для сторон vn & nn:
i1 = zeros(CFG.size,3);
i2 = zeros(CFG.size,3);

% нормализация входных параметров:
if (strcmp(TR.windings,'Y0/D-11'))
    % корректировка по коэффициентам трансформации
    k1 = TA.I1_vn/((TR.S_tr*10^3)/(sqrt(3)*TR.U_vn));
    k2 = TA.I1_nn/((TR.S_tr*10^3)/(3*TR.U_nn));
    i1 = i_vn.*k1;
    i2 = i_nn.*k2;
    
    i0 = (i1(:,1) + i1(:,2) + i1(:,3))/3;
    for p = 1:1:3
        i1(:,p) = i1(:,p) - i0;
    end
      
    % матрица связи токов для схемы соединения треугольник
    A = [+1, +0, -1;
          -1, +1, +0;
          +0, -1, +1];
      
    inv_A = pinv(A'); % псевдообратная матрица к данной 
     
    % корректировка по схеме соединения обмоток трансофрматора 
    for p = 1:1:CFG.size
        i2(p,:) = (inv_A*i2(p,:)')';
    end
end

% вывод результатов расчита
label_1 = {'График мгновенного значения тока i 1(t)'; 'точки'; 'i(t), А'};
label_2 = {'График мгновенного значения тока i 2(t)'; 'точки'; 'i(t), А'};
phases = {'фаза А', 'фаза B', 'фаза C'};
print_3p( i1, i2, [label_1, label_2] , phases);


% преобразование Фурье над корректированными данными
I1 = zeros(CFG.size,3);
I2 = zeros(CFG.size,3);
for j = 1:3
     I1(:,j) = fft_1p(i1(:,j), CFG.F_base, CFG.F_adc);
     I2(:,j) = fft_1p(i2(:,j), CFG.F_base, CFG.F_adc);
end

% вывод результатов расчита
label_1 = {'График действующего значения тока I1 (t)'; 'точки'; 'I1(t), А'};
label_2 = {'График действующего значения тока I2 (t)'; 'точки'; 'I2(t), А'};
phases = {'фаза А', 'фаза B', 'фаза C'};
print_3p( abs(I1), abs(I2), [label_1, label_2] , phases);


% вычисление токов Id & Is
[ Id, Is ] = IdIs( I1, I2, 'abs_sum' );

% вывод результатов расчита
label_1 = {'График дифференциального тока Id (t)'; 'точки'; 'Id(t), А'};
label_2 = {'График тока торможения Is (t)'; 'точки'; 'Is(t), А'};
phases = {'фаза А', 'фаза B', 'фаза C'};
print_3p( Id, Is, [label_1, label_2] , phases);


% передача данных в дифференциальный орган
TF = zeros(CFG.size,3);
for j = 1:3
    TF(:,j) = diff_organ( Id(:,j) , Is(:,j), j );
end

% временная диограмма срабатывания дифференциального органа
figure;
title('временные диаграммы срабатывания дифференциального органа 3 фаз');
for j = 1:1:3
    subplot(3,1,j);
    plot(TF(:,j),'LineWidth',2);
end

output_args = 0;
end


% описание функции 'fft_1p'
function [ck]= fft_1p(signal, f_base, f_adc)
% signal - структура (I(t),U(t),t) - дискретно заданные цункции
% base_f - базовая частота, частота источника ЭДС системы
% asc_f - частота дискретизации АЦП
%%Ck_rms = zeros(size(signal)); % инициализация массива Ck_rms
ck = zeros(size(signal));       % инициализация массива комплексных чисел
points = f_adc/f_base; % определение числа точек на период для иследуемого сигнала
k = 1; % номер иследуемой гормоники
buffer = 0; % создание буфера значений
for i =1:1:size(signal,1)
    % инициализация коэффициентов k-той гармоники
    ak = 0;
    bk = 0;
    % заполнение буфера
    if (i < points)
        buffer(1:i,1) = signal(1:i,1);
    else
        buffer(1:points,1) = signal((i - points + 1):1:i,1);
    end
    % определение количества точек в буфере
    Nt = size(buffer,1);
    % вычисление коэффициентов k-той гармоникибез учета коэффициента 2/points
    for j =1:1:Nt
        ak = ak + buffer(j,1)*cos(k*2*pi*(j-1)/Nt);
        bk = bk + buffer(j,1)*sin(k*2*pi*(j-1)/Nt);
    end
    % определение Ck и ck значения для k-той гармоники сигнала
    ck(i,1) = complex(sqrt(2)*ak/Nt,sqrt(2)*bk/Nt);
end
end
