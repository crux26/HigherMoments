%% <importData.m> -> <importOpData_1St.m> -> <TrimData_1st.m> OR <TrimData_1st_BSIV.m> (-> <dataSplit2expiry.m>)
%% Import the SPX Call 1st month data
clear;clc;
isDorm = true;
if isDorm == true
    drive = 'F:';
else
    drive = 'D:';
end

DaysPerYear = 252;
% Below takes: 8.0s (DORM PC)
tic;
filename = sprintf('%s\\Dropbox\\GitHub\\HigherMoments\\data\\rawdata\\SPXCall_MnthEnd_1st.csv', drive);
ds = tabularTextDatastore(filename);
toc;


% Below takes: 8.2s (DORM PC)
tic
ds.ReadSize = 15000; % default: file
toc

T = table;
% Below takes: 5.1s (DORM PC)
tic
while hasdata(ds)
    T_ = read(ds);
    T = [T; T_];
end
toc

%%
secid = T.secid;
% Below takes 10.0s (DORM PC)
tic
date = T.date; date = char(date); date = datenum(date);
toc
symbol = T.symbol;
% Below takes 10.1s (DORM PC)
tic
exdate = T.exdate; exdate = char(exdate); exdate = datenum(exdate);
toc
cp_flag = T.cp_flag; cp_flag = string(cp_flag);
strike_price = T.strike_price;
best_bid = T.best_bid;
best_offer = T.best_offer;
volume = T.volume;
open_interest = T.open_interest;
impl_volatility = T.impl_volatility;
delta = T.delta;
gamma = T.gamma;
vega = T.vega;
theta = T.theta;
ss_flag = T.ss_flag;
datedif = T.datedif;
spindx = T.spindx;
sprtrn = T.sprtrn;
tb_m3 = T.TB_M3 / DaysPerYear;
div = T.div;
spxset = T.spxset;
spxset_expiry = T.spxset_expiry;
moneyness = T.moneyness;
mid = T.mid;
opret = T.opret;
min_datedif = T.min_datedif;

%% Clear temporary variables

CallData = [date, exdate, strike_price, volume, open_interest, impl_volatility, ...
    delta, gamma, vega, theta, spindx, sprtrn, ...
    tb_m3, div, spxset, spxset_expiry, moneyness, mid, ...
    opret];

CallData(:,20) = 0; % cpflag: call == 0

CallData(:,21) = min_datedif;
CallBidAsk = [best_bid, best_offer];
symbol_C = symbol;
clearvars -except drive CallData symbol_C CallBidAsk;

%----------------------------------------------------------------------------------
%----------------------------------------------------------------------------------

%% Import the SPX Put 1st month data
% Below takes: 8.2s (DORM PC)
tic;
filename = sprintf('%s\\Dropbox\\GitHub\\HigherMoments\\data\\rawdata\\SPXPut_MnthEnd_1st.csv', drive);
ds = tabularTextDatastore(filename);
toc;


% Below takes: 9.1s (DORM PC)
tic
ds.ReadSize = 15000; % default: file
toc

T = table;
% Below takes: 5.2s (DORM PC)
tic
while hasdata(ds)
    T_ = read(ds);
    T = [T; T_];
end
toc

DaysPerYear = 252;
%%
secid = T.secid;
% Below takes 10.0s (DORM PC)
tic
date = T.date; date = char(date); date = datenum(date);
toc
symbol = T.symbol;
% Below takes 10.1s (DORM PC)
tic
exdate = T.exdate; exdate = char(exdate); exdate = datenum(exdate);
toc
cp_flag = T.cp_flag; cp_flag = string(cp_flag);
strike_price = T.strike_price;
best_bid = T.best_bid;
best_offer = T.best_offer;
volume = T.volume;
open_interest = T.open_interest;
impl_volatility = T.impl_volatility;
delta = T.delta;
gamma = T.gamma;
vega = T.vega;
theta = T.theta;
ss_flag = T.ss_flag;
datedif = T.datedif;
spindx = T.spindx;
sprtrn = T.sprtrn;
tb_m3 = T.TB_M3 / DaysPerYear;
div = T.div;
spxset = T.spxset;
spxset_expiry = T.spxset_expiry;
moneyness = T.moneyness;
mid = T.mid;
opret = T.opret;
min_datedif = T.min_datedif;

%% Clear temporary variables

PutData = [date, exdate, strike_price, volume, open_interest, impl_volatility, ...
    delta, gamma, vega, theta, spindx, sprtrn,...
    tb_m3, div, spxset, spxset_expiry, moneyness, mid,...
    opret];

PutData(:,20) = 1; % cpflag: Put == 1

PutData(:,21) = min_datedif;
PutBidAsk = [best_bid, best_offer];
symbol_P = symbol;
clearvars -except drive CallData PutData symbol_C symbol_P CallBidAsk PutBidAsk;

%% Save call and put data
save('rawOpData_1st.mat', 'CallData', 'PutData', 'symbol_C', 'symbol_P', 'CallBidAsk', 'PutBidAsk');