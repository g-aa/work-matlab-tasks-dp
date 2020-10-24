function [ out_sig, out_sig_0 ] = normalization_fun( IN_SIG, OBJ)

% in_sig     - структура, входной 3 фазный дискретный сигнал
% sets       - структура, параметры трансофрматора
% out_sig    - приведенный 3 фазный дискретный сигнал (массив)
% out_sig_0  - значения тока нулевой последовательности (вектор)


out_sig = zeros(IN_SIG.points,OBJ.phases);
out_sig_0 = zeros(IN_SIG.points,1);

% нормирование входного сигнала:
if (strcmp(OBJ.type(IN_SIG.side),'D'))
    
    % корректировка коэфициента трансформации, перевод в о.е.
    kt(:,1) = (IN_SIG.TA(:,1)./IN_SIG.TA(:,2))./OBJ.I_RMS(IN_SIG.side);
        
    for i = 1:1:OBJ.phases
        out_sig(:,i) = IN_SIG.current(:,i).*kt(i,1);
    end

    % матрица связи токов для схемы соединения треугольник
    A = [+1, +0, -1;
         -1, +1, +0;
         +0, -1, +1];
     
    % псевдообратная матрица
    pinv_A = pinv(A');   
    
    % корректировка схемы соединения обмоток:
    for p = 1:1:IN_SIG.points
        out_sig(p,:) = (pinv_A*out_sig(p,:)')';
    end
    
elseif (strcmp(OBJ.type(IN_SIG.side),'Y0'))
    
    % корректировка коэфициента трансформации, перевод в о.е.:
    kt(:,1) = (IN_SIG.TA(:,1)./IN_SIG.TA(:,2))./OBJ.I_RMS(IN_SIG.side);
    
    for i = 1:1:OBJ.phases
        out_sig(:,i) = IN_SIG.current(:,i).*kt(i,1);
    end
    
    % определение и фильтрация тока нулевой последовательности:
    for i = 1:1:OBJ.phases
        out_sig_0 = out_sig_0 + out_sig(:,i);
    end
    out_sig_0 = out_sig_0./3;
    
    for i = 1:1:OBJ.phases
        out_sig(:,i) = out_sig(:,i) - out_sig_0;
    end
    
elseif (strcmp(OBJ.type(IN_SIG.side),'Y'))
    
    % корректировка коэфициента трансформации, перевод в о.е.:
    kt(:,1) = (IN_SIG.TA(:,1)./IN_SIG.TA(:,2))./OBJ.I_RMS(IN_SIG.side);
    
    for i = 1:1:OBJ.phases
        out_sig(:,i) = IN_SIG.current(:,i).*kt(i,1);
    end
end
end