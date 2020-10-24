function print_3p( plot_dat, subplots, struct_txt)

% subplots - число подграфиков в окне (2 максимум)
% plot_dat - данные для построения
% struct_txt - структура с информацией о графике ()

% цветовая палитра:
color_M = [[255 215 000];
           [034 139 034];
           [255 000 000];]/255;
       
fp1 = figure;
set(fp1,'DefaultAxesFontSize',14,'DefaultAxesFontName','Times New Roman');

% цикл опроса подграффиков:
for s = 1:1:subplots
    subplot(2,1,s);
        
    % цик опроса данных: 
    hold on;
    for p = 1:1:3
        plot(plot_dat(:,p + 3*(s - 1)),'LineWidth',2, 'color', color_M(p,:));
    end
    grid minor;
    
    title(struct_txt.title(s,1));
    xlabel(struct_txt.label(s,1));
    ylabel(struct_txt.label(s,2));
    
    legend(struct_txt.legend);
    hold off;
end 
end

