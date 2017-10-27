%% <importData.m> -> <importOpData_2nd.m> -> <TrimData_1st.m> OR <TrimData_1st_BSIV.m> (-> <dataSplit2expiry.m>)
%% Import the SPX Call 1st & 2nd month data
[~, ~, raw, dates] = xlsread('F:\Dropbox\GitHub\HigherMoments\data\rawdata\SPXCall_Mnth_2nd.xlsx','SPXCall_Mnth_2nd','A2:AB193464','',@convertSpreadsheetExcelDates);
raw(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),raw)) = {''};
stringVectors = string(raw(:,[3,5,16]));
stringVectors(ismissing(stringVectors)) = '';
raw = raw(:,[1,6,7,8,9,10,11,12,13,14,15,17,18,19,20,21,22,23,24,25,26,27,28]);
dates = dates(:,[2,4]);

DaysPerYear = 252;
%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
raw(R) = {NaN}; % Replace non-numeric cells
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),dates); % Find non-numeric cells
dates(R) = {NaN}; % Replace non-numeric Excel dates with NaN

%% Create output variable
data = reshape([raw{:}],size(raw));

%% Allocate imported array to column variable names
secid = data(:,1);
date = datetime([dates{:,1}].', 'ConvertFrom', 'Excel');
symbol = stringVectors(:,1);
exdate = datetime([dates{:,2}].', 'ConvertFrom', 'Excel');
cp_flag = categorical(stringVectors(:,2));
strike_price = data(:,2);
best_bid = data(:,3);
best_offer = data(:,4);
volume = data(:,5);
open_interest = data(:,6);
impl_volatility = data(:,7);
delta = data(:,8);
gamma = data(:,9);
vega = data(:,10);
theta = data(:,11);
ss_flag = categorical(stringVectors(:,3));
datedif = data(:,12);
spindx = data(:,13);
sprtrn = data(:,14);
tb_m3 = data(:,15) / DaysPerYear;   %tb_m3: annualized rate -> 1D HPR
div = data(:,16);
spxset = data(:,17);
spxset_expiry = data(:,18);
moneyness = data(:,19);
mid = data(:,20);
opret = data(:,21);
min_datedif = data(:,22);
min_datedif_2nd = data(:,23);

% For code requiring serial dates (datenum) instead of datetime, uncomment
% the following line(s) below to return the imported dates as datenum(s).

date=datenum(date);
exdate=datenum(exdate);

%% Clear temporary variables
clearvars data raw dates stringVectors R;

CallData = [date, exdate, strike_price, volume, open_interest, impl_volatility, ...
    delta, gamma, vega, theta, spindx, sprtrn, ...
    tb_m3, div, spxset, spxset_expiry, moneyness, mid, ...
    opret];

CallData(:,20) = 0; % cpflag: call == 0

CallData(:,[21,22]) = [min_datedif, min_datedif_2nd];
symbol_C = symbol;

clearvars -except CallData symbol_C;


%----------------------------------------------------------------------------------
%----------------------------------------------------------------------------------

%% Import the SPX Put 1st & 2nd month data
[~, ~, raw, dates] = xlsread('F:\Dropbox\GitHub\HigherMoments\data\rawdata\SPXPut_Mnth_2nd.xlsx','SPXPut_Mnth_2nd','A2:AB193456','',@convertSpreadsheetExcelDates);
raw(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),raw)) = {''};
stringVectors = string(raw(:,[3,5,16]));
stringVectors(ismissing(stringVectors)) = '';
raw = raw(:,[1,6,7,8,9,10,11,12,13,14,15,17,18,19,20,21,22,23,24,25,26,27,28]);
dates = dates(:,[2,4]);

DaysPerYear = 252;
%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
raw(R) = {NaN}; % Replace non-numeric cells
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),dates); % Find non-numeric cells
dates(R) = {NaN}; % Replace non-numeric Excel dates with NaN

%% Create output variable
data = reshape([raw{:}],size(raw));

%% Allocate imported array to column variable names
secid = data(:,1);
date = datetime([dates{:,1}].', 'ConvertFrom', 'Excel');
symbol = stringVectors(:,1);
exdate = datetime([dates{:,2}].', 'ConvertFrom', 'Excel');
cp_flag = categorical(stringVectors(:,2));
strike_price = data(:,2);
best_bid = data(:,3);
best_offer = data(:,4);
volume = data(:,5);
open_interest = data(:,6);
impl_volatility = data(:,7);
delta = data(:,8);
gamma = data(:,9);
vega = data(:,10);
theta = data(:,11);
ss_flag = categorical(stringVectors(:,3));
datedif = data(:,12);
spindx = data(:,13);
sprtrn = data(:,14);
tb_m3 = data(:,15) / DaysPerYear;
div = data(:,16);
spxset = data(:,17);
spxset_expiry = data(:,18);
moneyness = data(:,19);
mid = data(:,20);
opret = data(:,21);
min_datedif = data(:,22);
min_datedif_2nd = data(:,23);

% For code requiring serial dates (datenum) instead of datetime, uncomment
% the following line(s) below to return the imported dates as datenum(s).

date=datenum(date);
exdate=datenum(exdate);

%% Clear temporary variables
clearvars data raw dates stringVectors R;

PutData = [date, exdate, strike_price, volume, open_interest, impl_volatility, ...
    delta, gamma, vega, theta, spindx, sprtrn,...
    tb_m3, div, spxset, spxset_expiry, moneyness, mid,...
    opret];

PutData(:,20) = 1; % cpflag: Put == 1

PutData(:,[21,22]) = [min_datedif, min_datedif_2nd];
symbol_P = symbol;
clearvars -except CallData PutData symbol_C symbol_P;

%% Save call and put data
save('rawOpData_2nd.mat', 'CallData', 'PutData', 'symbol_C', 'symbol_P');
