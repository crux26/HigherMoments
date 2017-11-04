%% result_momPrice <- main()
clear; clc;
isDorm = false;
if ~isDorm
    addpath('D:\Dropbox\GitHub\HigherMoments');
else
    addpath('F:\Dropbox\GitHub\HigherMoments');
end


load('result_momPrice.mat', 'moment', 'tbl_moment', 'date_');

%% Exclude some dates
% idx_ = find(date_ ~= 735943);
% date_ = date_(idx_);
% moment = moment(idx_, :);
%%
mom1 = moment(:,1);
mom2 = moment(:,2);
mom3 = moment(:,3);
mom4 = moment(:,4);
%% Print descriptive statistics
describe([mom1,mom2,mom3,mom4]);

%% Compare it with summary(T)
summary(tbl_moment);

%% subplot
figure;
set(gcf, 'Position', [500, 100, 1000, 800]);

subplot(4,1,1);
plot(date_,mom1);
xlim([date_(1)-200, date_(end)+200]);
ylim auto;
datetick('x', 12, 'keepticks', 'keeplimits');
legend('mom1');
grid minor;

subplot(4,1,2);
plot(date_,mom2);
xlim([date_(1)-200, date_(end)+200]);
ylim auto;
datetick('x', 12, 'keepticks', 'keeplimits');
legend('mom2');
grid minor;

subplot(4,1,3);
plot(date_,mom3);
xlim([date_(1)-200, date_(end)+200]);
ylim auto;
datetick('x', 12, 'keepticks', 'keeplimits');
legend('mom3');
grid minor;

subplot(4,1,4);
plot(date_,mom4);
xlim([date_(1)-200, date_(end)+200]);
ylim auto;
datetick('x', 12, 'keepticks', 'keeplimits');
legend('mom4');
grid minor;

if ~isDorm
    rmpath('D:\Dropbox\GitHub\HigherMoments');
else
    rmpath('F:\Dropbox\GitHub\HigherMoments');
end