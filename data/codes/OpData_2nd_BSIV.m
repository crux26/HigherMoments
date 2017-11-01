%% <importData.m> -> <importOpData_1St.m> -> <TrimData_1st.m> OR <TrimData_1st_BSIV.m> (-> <dataSplit2expiry.m>)
%% remove non-sensical IV
% This is checked as often the raw data from SAS doesn't make sense at all.
% Refer to <opPrice_RelevanceChk.m>. This gives an example of "wrongly"
% traded data.
% Note that according to the document, Option Metrics calculates implied
% volatilities with BS model.
clear;clc;
load('rawOpData_2nd.mat', 'CallData', 'PutData', 'symbol_C', 'symbol_P', 'CallBidAsk', 'PutBidAsk');
DaysPerYear = 252;

% CallData = [date, exdate, strike_price, volume, open_interest, impl_volatility, ...
%     delta, gamma, vega, theta, spindx, sprtrn, ...
%     tb_m3, div, spxset, spxset_expiry, moneyness, mid, ...
%     opret, cpflag];

% Delete if isnan(tb_m3)
idx_notNaN_C = find(~isnan(CallData(:,13)));
CallData = CallData(idx_notNaN_C, :);
symbol_C = symbol_C(idx_notNaN_C);
CallBidAsk = CallBidAsk(idx_notNaN_C, :);

idx_notNaN_P = find(~isnan(PutData(:,13)));
PutData = PutData(idx_notNaN_P, :);
symbol_P = symbol_P(idx_notNaN_P);
PutBidAsk = PutBidAsk(idx_notNaN_P, :);


%% CallIV, PutIV: "true" model price.
% IVs from CallData(:,6), PutData(:,6): market price that can go "wrong".

% Volatility = blsimpv(Price, Strike, Rate, Time,...
%     Value, Limit, Yield, Tolerance, Class)

% Below takes: 565.7s (LAB PC, 1996-2015)
TTM_C = yearfrac(CallData(:,1),CallData(:,2),13);
tic;
CallIV = blsimpv(CallData(:,11), CallData(:,3), CallData(:,13) * DaysPerYear , ...
    TTM_C, CallData(:,18), [], CallData(:,14), [], {'Call'});
toc;

%Below takes: 543s (DORM PC, 1996-2015)
TTM_P = yearfrac(PutData(:,1),PutData(:,2),13);
tic;
PutIV = blsimpv(PutData(:,11), PutData(:,3), PutData(:,13) * DaysPerYear , ...
    TTM_P, PutData(:,18), [], PutData(:,14), [], {'Put'});
toc;


[CallnRow,~] = size(CallData);
[PutnRow,~] = size(PutData);

%Below took: 0.004s (LAB PC, 1996-2015)
CallVolDev = zeros(CallnRow,1); % 1 if Vol_true deviates more than 5% from IV_BS.
idx_CallVolDev = find(CallIV < 0.95*CallData(:,6) | CallIV > 1.05*CallData(:,6));
CallVolDev(idx_CallVolDev) = 1;

% Below took: 0.004s (LAB PC, 1996-2015)
PutVolDev = zeros(PutnRow,1);
idx_PutVolDev = find(PutIV < 0.95*PutData(:,6) | PutIV > 1.05*PutData(:,6));
PutVolDev(idx_PutVolDev) = 1;


save('OpData_BSIV_2nd.mat','CallData', 'CallIV', 'CallVolDev', 'PutData', 'PutIV', 'PutVolDev', ...
    'symbol_C', 'symbol_P', 'CallBidAsk', 'PutBidAsk', 'TTM_C', 'TTM_P');