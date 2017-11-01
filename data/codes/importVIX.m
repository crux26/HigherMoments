%% Import the data, extracting spreadsheet dates in Excel serial date format
clear; clc;
[~, ~, raw, dates] = xlsread('D:\Dropbox\GitHub\HigherMoments\data\rawdata\VIXData.xlsx','VIXData','A2:F1031','',@convertSpreadsheetExcelDates);
raw(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),raw)) = {''};
raw = raw(:,[2,3,4,5,6]);
dates = dates(:,1);

DaysPerYear = 252;
%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
raw(R) = {NaN}; % Replace non-numeric cells
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),dates); % Find non-numeric cells
dates(R) = {NaN}; % Replace non-numeric Excel dates with NaN

%% Create output variable
data = reshape([raw{:}],size(raw));

%% Allocate imported array to column variable names
caldt = datetime([dates{:,1}].', 'ConvertFrom', 'Excel');
spindx = data(:,1);
sprtrn = data(:,2);
tb_m3 = data(:,3) / DaysPerYear;
rate = data(:,4); div = rate;
vix = data(:,5);

% For code requiring serial dates (datenum) instead of datetime, uncomment the following line(s) below to return the
% imported dates as datenum(s).

caldt=datenum(caldt);

%% Clear temporary variables
clearvars data raw dates R;

save('rawData_VIX.mat', 'caldt', 'vix', 'spindx', 'sprtrn', 'tb_m3', 'div');