function [ SETS , SIGNALS , return_arg] = data_load( SETS , SIGNALS , OBJ)

% поиск файла "*.cfg":
[SETS.file.fcfg,SETS.file.path] = uigetfile({'*.cfg';'*.*'},'File Selector');

% проверка на успешный поиск файла "*.cfg":
if (~SETS.file.fcfg)
    SETS.file = [];
    for i = 1:1:OBJ.size
        SIGNALS(i).current = [];
    end
    disp('The file "*.cfg" was not opened!');
    
    return_arg = -1;
    return;
end

% получение имени файла "*.dat":
SETS.file.fdat = strrep(SETS.file.fcfg, 'cfg', 'dat');
% открыть файл "*.cfg" на чнение:
pf = fopen([SETS.file.path, SETS.file.fcfg], 'r');

% проверка на ошибки при открытии файла:
if (~pf)
    SETS.file = [];
    for i = 1:1:OBJ.size
        SIGNALS(i).current = [];
    end
    disp('The file "*.cfg" can not be opened!');
    
    return_arg = -1;
    return;
end

% чтение данных из файла "*.cfg":
buffer = textscan(pf,'%s','Delimiter','\n');
buffer = buffer{1,1};
SETS.F_base = int32(str2double(buffer{9}));
[temp1, temp2] = strtok(buffer{11,1},',');
SETS.F_adc = int32(str2double(temp1));
SETS.points = int32(str2double(temp2));
fclose(pf);
clear buffer pf temp1 temp2;

% открыть файл "*.dat" на чнение:
pf = fopen([SETS.file.path, SETS.file.fdat], 'r');

% проверка на ошибки при открытии файла:
if (~pf)
    SETS.file = [];
    for i = 1:1:OBJ.size
        SIGNALS(i).current = [];
    end
    disp('The file "*.dat" can not be opened!');
    
    return_arg = -1;
    return;
end

% чтение файла "*.dat" преобразование в числовой массив: 
buffer = cell2mat(textscan(pf,'%f %f %f %f %f %f %f %f','Delimiter',','));
fclose(pf);
clear pf;

buffer = buffer(:,3:8);

for i = 1:1:OBJ.size
    SIGNALS(i).side = i;
    SIGNALS(i).points = SETS.points;
    for j = 1:1:OBJ.phases
        SIGNALS(i).current(:,j) = buffer(:,j + 3*(i - 1));
    end
end

return_arg = 0; % успешное завершение работы функции
end

