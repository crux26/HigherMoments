%% <importData.m> -> <importOpData_1St.m> -> <TrimData_1st.m> OR <TrimData_1st_BSIV.m> (-> <dataSplit2expiry.m>)
%% remove non-sensical IV
% This is checked as often the raw data from SAS doesn't make sense at all.
% Refer to <opPrice_RelevanceChk.m>. This gives an example of "wrongly"
% traded data.
% Note that according to the document, Option Metrics calculates implied
% volatilities with BS model.
clear;clc;
load('rawOpData_2nd.mat', 'CallData', 'PutData', 'symbol_C', 'symbol_P');
DaysPerYear = 252;

% [CallnRow,~] = size(CallData);
% [PutnRow,~] = size(PutData);

% CallData = [date, exdate, strike_price, volume, open_interest, impl_volatility, ...
%     delta, gamma, vega, theta, spindx, sprtrn, ...
%     tb_m3, div, spxset, spxset_expiry, moneyness, mid, ...
%     opret, cpflag];

% Delete if isnan(tb_m3)
% Below takes: 2.6s. (DORM PC, 1996-2015)

% tic
% for i = CallnRow : -1 : 1
%     if isnan( CallData(i,13) )
%         CallData(i,:) = [];
%         symbol_C(i) = [];
%     end
% end
% toc

% Below takes: 2.6s. (DORM PC, 1996-2015)
% tic
% for i = PutnRow : -1 : 1
%     if isnan( PutData(i,13) )
%         PutData(i,:) = [];
%         symbol_P(i) = [];
%     end
% end
% toc

tic;
idx_notNaN_C = find(~isnan(CallData(:,13)));
CallData = CallData(idx_notNaN_C, :);
symbol_C = symbol_C(idx_notNaN_C);
toc;

tic;
idx_notNaN_P = find(~isnan(PutData(:,13)));
PutData = PutData(idx_notNaN_P, :);
symbol_P = symbol_P(idx_notNaN_P);
toc;

%% CallIV, PutIV: "true" model price.
% IVs from CallData(:,6), PutData(:,6): market price that can go "wrong".

% Volatility = blsimpv(Price, Strike, Rate, Time,...
%     Value, Limit, Yield, Tolerance, Class)

% Below takes: 526s (LAB PC, 1996-2015)
tic;
CallIV = blsimpv(CallData(:,11), CallData(:,3), CallData(:,13) * DaysPerYear , ...
    yearfrac(CallData(:,1),CallData(:,2),13), ...
    CallData(:,18), [], CallData(:,14), [], {'Call'});
toc;

%Below takes: 543s (DORM PC, 1996-2015)
tic;
PutIV = blsimpv(PutData(:,11), PutData(:,3), PutData(:,13) * DaysPerYear , ...
    yearfrac(PutData(:,1),PutData(:,2),13), ...
    PutData(:,18), [], PutData(:,14), [], {'Put'});
toc;


%% Delete observation where IV deviates from model IV more than 5%.
% This is quite often the case, as the traded price is far from
% model-derived price.

[CallnRow,~] = size(CallData);
[PutnRow,~] = size(PutData);

%Below took: 0.004s (LAB PC, 1996-2015)
CallVolDev = zeros(CallnRow,1); % 1 if Vol_true deviates more than 5% from IV_BS.
tic
for i = CallnRow : -1 : 1
    if CallIV(i) < 0.95 * CallData(i,6) || ...
        CallIV(i) > 1.05 * CallData(i,6)
        CallVolDev(i) = 1;
    end
end
toc

% Below took: 0.004s (LAB PC, 1996-2015)
PutVolDev = zeros(PutnRow,1);
tic
for i = PutnRow : -1 : 1
    if PutIV(i) < 0.95 * PutData(i,6) || ...
        PutIV(i) > 1.05 * PutData(i,6)
        PutVolDev(i)=1;
    end
end
toc

save('OpData_BSIV_2nd.mat','CallData', 'CallIV', 'CallVolDev', 'PutData', 'PutIV', 'PutVolDev', 'symbol_C', 'symbol_P');