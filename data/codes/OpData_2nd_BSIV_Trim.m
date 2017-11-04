%% <importOpData_2nd.m> -> <OPData_2nd_BSIV.m> -> <OPData_2nd_BSIV_Trim.m> -> <OpData_2nd_BSIV_Trim_extrap.m>
%% remove non-sensical IV
% This is checked as often the raw data from SAS doesn't make sense at all.
% Refer to <opPrice_RelevanceChk.m>. This gives an example of "wrongly"
% traded data.
% Note that according to the document, Option Metrics calculates implied
% volatilities with BS model.
clear;clc;
isDorm = false;
if isDorm == true
    drive = 'F:';
else
    drive = 'D:';
end
homeDirectory = sprintf('%s\\Dropbox\\GitHub\\HigherMoments', drive);
gen_data_path = sprintf('%s\\data\\gen_data', homeDirectory);

OptionsData_genData_path = sprintf('%s\\Dropbox\\GitHub\\OptionsData\\data\\gen_data', drive);

%Below took: 17.6 (LAB PC)
tic;
load(sprintf('%s\\rawOpData_dly_2nd_BSIV.mat', OptionsData_genData_path), ...
    'CallData', 'CallIV', 'CallVolDev', 'PutData', 'PutIV', 'PutVolDev', ...
    'symbol_C', 'symbol_P', 'CallBidAsk', 'PutBidAsk', 'TTM_C', 'TTM_P');
toc;
DaysPerYear = 252;


% CallData = [date, exdate, strike_price, volume, open_interest, impl_volatility, ...
%     delta, gamma, vega, theta, spindx, sprtrn, ...
%     tb_m3, div, spxset, spxset_expiry, moneyness, mid, ...
%     opret, cpflag];


%% CallIV, PutIV: "true" model price.
% IVs from CallData(:,6), PutData(:,6): market price that can go "wrong".

% Volatility = blsimpv(Price, Strike, Rate, Time,...
%     Value, Limit, Yield, Tolerance, Class)

[CallnRow,~] = size(CallData);
[PutnRow,~] = size(PutData);

%% Filtering conditions should be added below.
%Below took: 0.12s (LAB PC)
tic
idx_C = find( CallBidAsk(:,1) == 0 | ... % exclude zero bid
        CallData(:,17) > 1 | ... % exclude ITM (S/K > 1)
        CallData(:,18) < 3/8 | ... % mid price < $3/8, the minimum tick size
        CallData(:,18) > CallData(:,11) | ... % exclude call price more expensive than S0
        CallData(:,18) < max(CallData(:,11) - CallData(:,14) - ...
            CallData(:,3).*exp( -CallData(:,13).*TTM_C), 0)); % exclude call < max(S0-q-K*exp(-rT), 0)
toc
idx_C = setdiff(1:CallnRow, idx_C);
CallData = CallData(idx_C, :);
CallIV = CallIV(idx_C, :);
CallVolDev = CallVolDev(idx_C);
CallBidAsk = CallBidAsk(idx_C, :);
TTM_C = TTM_C(idx_C, :);
symbol_C = symbol_C(idx_C, :);

%% Filtering conditions should be added below.
% Below took: 0.11s (LAB PC)
tic
idx_P = find( PutBidAsk(:,1) == 0 | ... % exclude zero bid
        PutData(:,17) < 1 |... % exclude ITM (S/K < 1)
        PutData(:,18) < 3/8 | ... % mid price < $3/8, the minimum tick size
        PutData(:,18) > PutData(:,3).*exp( -PutData(:,13) .* TTM_P) | ... %exclude put > K*exp(-rT)
        PutData(:,18) < max( PutData(:,14) + ...
            PutData(:,3).*exp( -PutData(:,13) .* (TTM_P) - PutData(:,11)), 0 ) );% exclude put < max(q+K*exp(-rT)-S0,0)
toc
idx_P = setdiff(1:PutnRow, idx_P);
PutData = PutData(idx_P, :);
PutIV = PutIV(idx_P, :);
PutVolDev = PutVolDev(idx_P);
PutBidAsk = PutBidAsk(idx_P, :);
TTM_P = TTM_P(idx_P, :);
symbol_P = symbol_P(idx_P, :);
%%
% Below took: 7.9s (LAB PC)
tic;
save(sprintf('%s\\OpData_dly_2nd_BSIV_Trim.mat', gen_data_path), ...
    'CallData', 'CallIV', 'CallVolDev', 'CallBidAsk', 'TTM_C', 'symbol_C', ...
 'PutData', 'PutIV', 'PutVolDev', 'PutBidAsk', 'TTM_P', 'symbol_P');
toc;