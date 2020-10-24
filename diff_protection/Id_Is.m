function [ Id, Is ] = Id_Is( I1, I2, tipe_Is )
% I1 - трехфазный ток первичной стороны трансформатора
% I2 - трехфазный ток вторичной стороны трансофрматора

% определение дифференциального тока трансформатора (Id)
Id = abs(I1 + I2);

% расчет тока торможения трансформатора (Is)
if (strcmp(tipe_Is,'abs_sub'))
    Is = abs(I1) - abs(I2);
elseif(strcmp(tipe_Is,'abs_sum'))
    Is = abs(I1) + abs(I2);
end
end