%% <importData.m> -> <importOpData.m> -> <TrimData.m> (-> <dataSplit2expiry.m>)
%% Import the data
% [~, ~, raw] = xlsread('D:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\rawData\SPXData.xlsx','SPXData','A2:D5247');
[~, ~, raw] = xlsread('D:\Dropbox\GitHub\HigherMoments\data\rawdata\SPXData.xlsx','SPXData','A2:D5247');
raw(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),raw)) = {''};
cellVectors = raw(:,1);
raw = raw(:,[2,3,4]);

DaysPerYear = 252;
%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
raw(R) = {NaN}; % Replace non-numeric cells

%% Create output variable
data = reshape([raw{:}],size(raw));

%% Allocate imported array to column variable names
caldt = datenum(cellVectors(:,1));
spindx = data(:,1);
sprtrn = data(:,2);
tb_m3 = data(:,3) / DaysPerYear; %tb_m3: annualized rate -> 1D HPR


% date tb_m3
%---------------
% 28-Dec-94	5.52
% 29-Dec-94	5.51
% 30-Dec-94	5.53
% 02-Jan-95	.
% 03-Jan-95	5.53

% Start of the data period: 03-Jan-95

% To make the beginning and the end of the period of stock return and tb_m3
% to match, lag1(tb_m3) should be used in accordance with sprtrn.
% Hence, tb_m3(1) should be that of 30-Dec-94, and tb_m3(end) should be
% discarded.

tb_m3 = [5.53 /100 / 252; tb_m3];
tb_m3(end) = []; % tb_m3('31-Dec-2015') discarded. Now tb_m3(end) corresponds to 30-Dec-2015.

% Note that above shouldn't be applied to options as one simulates stock
% prices from today into future, where the beginning and the end of the
% window of each coincides.

%% Clear temporary variables
clearvars data raw cellVectors R;
save('rawData.mat', 'caldt', 'spindx', 'sprtrn', 'tb_m3');