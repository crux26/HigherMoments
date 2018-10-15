%% var(my SKEW, KURT) >>> var(paper's SKEW, KURT). Must fix it.
%% date==732798; Start from here.

%% plotting
clear;clc;
isDorm = true;
if isDorm == true
    drive = 'E:';
else
    drive = 'E:';
end
homeDirectory = sprintf('%s\\Dropbox\\GitHub\\HigherMoments', drive);
genData_path = sprintf('%s\\data\\gen_data', homeDirectory);
addpath(sprintf('%s\\main_functions', homeDirectory));
addpath(homeDirectory);
% Below takes: 4.3s (LAB PC)

%% my SKEW, KURT calculation
load('SKEWKURT.mat', 'T_mmt_interp', 'T_mmtPrice');
figure;
plot(T_mmt_interp.date_, T_mmt_interp.SKEW, T_mmt_interp.date_, T_mmt_interp.KURT);
xlim([T_mmt_interp.date_(1)-100 T_mmt_interp.date_(end)+100]);
tickDates = linspace(T_mmt_interp.date_(1),T_mmt_interp.date_(end),10);
set(gca, 'XTick', tickDates, 'XTickLabel', datestr(tickDates, 12));
legend('SKEW', 'KURT', 'Location', 'northwest');
title('my SKEW, KURT');

%% Chang, Christoffersen, Jacobs (2013)'s iSKEW, iKURT data
load('SKEWKURT_mmt.mat', 'T_mmt');
figure;
plot(T_mmt.date, T_mmt.iskew, T_mmt.date, T_mmt.ikurt);
% legend('SKEW', 'KURT');
xlim([T_mmt.date(1)-100 T_mmt.date(end)+100]);
tickDates = linspace(T_mmt.date(1),T_mmt.date(end),10);
set(gca, 'XTick', tickDates, 'XTickLabel', datestr(tickDates, 12));
legend('SKEW', 'KURT', 'Location', 'northwest');
title('papers SKEW, KURT');

%% Compare SKEW
load('SKEWKURT.mat', 'T_mmt_interp', 'T_mmtPrice');
load('SKEWKURT_mmt.mat', 'T_mmt');
date_intersection = intersect(T_mmt_interp.date_, T_mmt.date);
T_mmt_interp = T_mmt_interp( ismember(T_mmt_interp.date_, date_intersection), :);
T_mmt = T_mmt( ismember(T_mmt.date, date_intersection), :);

figure;
plot(date_intersection, T_mmt_interp.SKEW, date_intersection, T_mmt.iskew);
xlim([T_mmt.date(1)-100 T_mmt.date(end)+100]);
tickDates = linspace(T_mmt.date(1),T_mmt.date(end),10);
set(gca, 'XTick', tickDates, 'XTickLabel', datestr(tickDates, 12));
legend('my SKEW', 'paper SKEW', 'Location', 'northwest');
title('option implied SKEW comparison');

%% Compare KURT
load('SKEWKURT.mat', 'T_mmt_interp', 'T_mmtPrice');
load('SKEWKURT_mmt.mat', 'T_mmt');
date_intersection = intersect(T_mmt_interp.date_, T_mmt.date);
T_mmt_interp = T_mmt_interp( ismember(T_mmt_interp.date_, date_intersection), :);
T_mmt = T_mmt( ismember(T_mmt.date, date_intersection), :);

figure;
plot(date_intersection, T_mmt_interp.KURT, date_intersection, T_mmt.ikurt);
xlim([T_mmt.date(1)-100 T_mmt.date(end)+100]);
tickDates = linspace(T_mmt.date(1),T_mmt.date(end),10);
set(gca, 'XTick', tickDates, 'XTickLabel', datestr(tickDates, 12));
legend('my KURT', 'paper KURT', 'Location', 'northwest');
title('option implied KURT comparison');

%%
rmpath(sprintf('%s\\main_functions', homeDirectory));
rmpath(homeDirectory);
