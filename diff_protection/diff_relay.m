function [ tf_sig ] = diff_relay( Id , Is, D_SETS)

% Id - дифференцальный ток защиты
% Is - ток торможения защиты
% D_SETS - уставки дифференцальной защиты (структура)
% tf_sig - логический сигнал, результат срабатывания реле

% цветовая палитра графиков:
color_M = [[255 165 000];
           [034 139 034];
           [255 000 000];]/255;
% перечисление фаз:
phases = {'фаза А', 'фаза B', 'фаза C'};

% иничиализация матриц коэффициентов: K, B, A:
Ks = D_SETS.k;

Bs = [D_SETS.b(1); 
      D_SETS.b(2); 
      D_SETS.b(2);
      D_SETS.b(3);
      D_SETS.b(3);
      D_SETS.b(4)];

A = [1, -Ks(1), 0,      0, 0,     0;
     1, -Ks(2), 0,      0, 0,     0;
     0,      0, 1, -Ks(2), 0,     0;
     0,      0, 1, -Ks(3), 0,     0;
     0,      0, 0,      0, 1, -Ks(3);
     0,      0, 0,      0, 1, -Ks(4)];
 
% Вычисление точек пересечения прямях образующих кусочно линейную функцию:
IdIs = A\Bs;
 
% Составление точек пересечения прямых:
Ipoints = [IdIs(1),       0, 1; 
           IdIs(1), IdIs(2), 1; 
           IdIs(3), IdIs(4), 1;
           IdIs(5), IdIs(6), 1;
           IdIs(5), IdIs(6) + 2, 1];

% определение срабатывания дифференциального органа:  
tf_sig = zeros(size(Id));
flag = zeros(size(Ks,1) - 1,1); % флаг срабатывания дифференциального реле

% цикл обхода фаз:
for p = 1:1:size(Id,2)
    
    % цикл обхода точек дискретного сигнала:
    for i = 1:1:size(Id,1)
    
        % проверка срабатывания диф. отсечки:
        if (Id(i) < Ipoints(5,1)) 
            
            % цикл охода отрезков:
            for j = 1:1:size(Ks,1) - 1
                % построение матрицы L взаимного расположения j-ого отрезка
                % характеристики диф защиты и i-точки осцилограммы:
                L = [Ipoints(j,:); Ipoints(j + 1,:); [Id(i), Is(i),1]];
                detL = det(L);

                % условие взаимного расположения отрезка и точки:
                if (detL < 0)
                    flag(j) = 1;
                end
            end
        else
            tf_sig(i,p) = 1; % срабатывание диф. отсечки
        end
        
        % условие поподания в зону срабатывания характеристики:
        if (sum(flag) == 3)
            tf_sig(i,p) = 1;
            flag = [0; 0; 0]; % сброс состояния флага
        end
    end
end


% граффическое представление результатов расчета:
fig_1 = figure;
set(fig_1,'DefaultAxesFontSize',14,'DefaultAxesFontName','Times New Roman');
txt = 'Характеристика срабатывания диф. защиты,';

% цикл опроса фаз:
for p = 1:1:size(Id,2)
    subplot(2,2,p);
    title([txt,phases(p)]);
    hold on;
    plot(Ipoints(:,2), Ipoints(:,1), '-o', 'LineWidth', 2);
    grid minor;
    plot(Is(:,1), Id(:,1), '-', 'LineWidth', 2, 'color', color_M(p,:));
    hold off;
    
    xlabel('ток торможения Is, о.е.');
    ylabel('дифференциальный ток Id, о.е.');
    legend('характеристика', 'Id = f(Is)','Location','southoutside','Orientation','horizontal');
end

% вывод характеристики срабатывания:
subplot(2,2,4);
hold on;
for p = 1:1:size(Id,2)
    plot(p*tf_sig(:,p), 'LineWidth', 2, 'color', color_M(p,:));
end
grid minor;
hold off;

title('Зависемость логического сигнала от времяни');
xlabel('точки');
ylabel('логический сигнал');
legend(phases);
end