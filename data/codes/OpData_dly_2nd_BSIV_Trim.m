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
        CallData(:,17) > 1/0.97 | ... % exclude ITM (S/K > 1/0.97 or K<0.97S)
        CallData(:,18) < 3/8 | ... % mid price < $3/8, the minimum tick size
        CallData(:,18) > CallData(:,11) | ... % exclude call price more expensive than S0
        CallData(:,18) < max(CallData(:,11) - CallData(:,14) - ...
            CallData(:,3).*exp( -CallData(:,13).*TTM_C), 0)); % exclude call < max(S0-q-K*exp(-rT), 0)
toc
idx_C = setdiff(1:CallnRow, idx_C);
CallData = CallData(idx_C, :); CallIV = CallIV(idx_C, :);
CallVolDev = CallVolDev(idx_C); CallBidAsk = CallBidAsk(idx_C, :);
TTM_C = TTM_C(idx_C, :); symbol_C = symbol_C(idx_C, :);

%% Filtering conditions should be added below.
% Below took: 0.11s (LAB PC)
tic
idx_P = find( PutBidAsk(:,1) == 0 | ... % exclude zero bid
        PutData(:,17) < 1/1.03 |... % exclude ITM (S/K < 1/1.03 or K>1.03S)
        PutData(:,18) < 3/8 | ... % mid price < $3/8, the minimum tick size
        PutData(:,18) > PutData(:,3).*exp( -PutData(:,13) .* TTM_P) | ... %exclude put > K*exp(-rT)
        PutData(:,18) < max( PutData(:,14) + ...
            PutData(:,3).*exp( -PutData(:,13) .* (TTM_P) - PutData(:,11)), 0 ) );% exclude put < max(q+K*exp(-rT)-S0,0)
toc
idx_P = setdiff(1:PutnRow, idx_P);
PutData = PutData(idx_P, :); PutIV = PutIV(idx_P, :); 
PutVolDev = PutVolDev(idx_P); PutBidAsk = PutBidAsk(idx_P, :);
TTM_P = TTM_P(idx_P, :); symbol_P = symbol_P(idx_P, :);

%% For some days, repetition in K. Hence, deleting them. One is quarterly (SLQ), one is weekly (JXE).
m1 = size(CallData,1); m2 = size(PutData,1);
idx_C = 1:m1-1; idx_C_next = 2:m1; idx_P = 1:m2-1; idx_P_next = 2:m2;

isSameK_C = find(CallData(idx_C,1)==CallData(idx_C_next,1) & ...
    CallData(idx_C,2)==CallData(idx_C_next,2)& ...
    CallData(idx_C,3)== CallData(idx_C_next,3));

RetainThisK_C = setdiff(1:m1, isSameK_C)'; % isSameK_C+1: Quarterly option. isSameK_C: Weekly option

isSameK_P = find(PutData(idx_P,1)==PutData(idx_P_next,1) & ...
    PutData(idx_P,2)==PutData(idx_P_next,2) & ...
PutData(idx_P,3)==PutData(idx_P_next,3));

RetainThisK_P = setdiff(1:m2, isSameK_P)';

CallData = CallData(RetainThisK_C,:); CallIV = CallIV(RetainThisK_C,:);
CallVolDev = CallVolDev(RetainThisK_C,:); CallBidAsk =  CallBidAsk(RetainThisK_C,:);
TTM_C = TTM_C(RetainThisK_C,:); symbol_C = symbol_C(RetainThisK_C,:);

PutData = PutData(RetainThisK_P,:); PutIV = PutIV(RetainThisK_P,:);
PutVolDev = PutVolDev(RetainThisK_P,:); PutBidAsk = PutBidAsk(RetainThisK_P,:);
TTM_P = TTM_P(RetainThisK_P,:); symbol_P = symbol_P(RetainThisK_P,:);

%% Delete TTM==0 data.
idx_C = find(CallData(:,1)~=CallData(:,2)); 
CallData = CallData(idx_C,:); CallIV = CallIV(idx_C,:);
CallVolDev = CallVolDev(idx_C,:); CallBidAsk = CallBidAsk(idx_C,:);
TTM_C = TTM_C(idx_C,:); symbol_C = symbol_C(idx_C,:);

idx_P = find(PutData(:,1)~=PutData(:,2));
PutData = PutData(idx_P,:); PutIV = PutIV(idx_P,:); 
PutVolDev = PutVolDev(idx_P,:);  PutBidAsk = PutBidAsk(idx_P,:); 
TTM_P = TTM_P(idx_P,:); symbol_P = symbol_P(idx_P,:); 


%% Discard (date,exdate) pair if #(strikes) on that date < 2.
[DatePair_C, idx_DatePair_C, ~] = unique(CallData(:,1:2), 'rows', 'stable');
[DatePair_P, idx_DatePair_P, ~] = unique(PutData(:,1:2), 'rows', 'stable');

idx_C=[];
for i=1:size(idx_DatePair_C,1)-1
    if idx_DatePair_C(i+1) - idx_DatePair_C(i) < 2
        idx_C_ = i;
        idx_C = [idx_C; idx_C_];
    end
end

idx_P = [];
for i=1:size(idx_DatePair_P,1)-1
    if idx_DatePair_P(i+1) - idx_DatePair_P(i) < 2
        idx_P_ = i;
        idx_P = [idx_P; idx_P_];
    end
end

Problematic_Date_C = CallData(idx_DatePair_C(idx_C), 1); Problematic_Exdate_C = CallData(idx_DatePair_C(idx_C), 2);
Problematic_Date_P = PutData(idx_DatePair_P(idx_P), 1); Problematic_Exdate_P = PutData(idx_DatePair_P(idx_P), 2);

idx_C_Date = ismember(CallData(:,1), Problematic_Date_C); idx_C_Exdate = ismember(CallData(:,2), Problematic_Exdate_C);
idx_C = idx_C_Date & idx_C_Exdate;

idx_P_Date = ismember(PutData(:,1), Problematic_Date_C); idx_P_Exdate = ismember(PutData(:,2), Problematic_Exdate_P);
idx_P = idx_P_Date & idx_P_Exdate;

%
CallData = CallData(~idx_C,:); CallIV = CallIV(~idx_C,:); 
CallVolDev = CallVolDev(~idx_C,:); CallBidAsk = CallBidAsk(~idx_C,:); 
TTM_C = TTM_C(~idx_C,:); symbol_C = symbol_C(~idx_C,:); 

PutData = PutData(~idx_P,:); PutIV = PutIV(~idx_P,:); 
PutVolDev = PutVolDev(~idx_P,:); PutBidAsk = PutBidAsk(~idx_P,:); 
TTM_P = TTM_P(~idx_P,:); symbol_P = symbol_P(~idx_P,:); 


%%
% Below took: 7.9s (LAB PC)
tic;
save(sprintf('%s\\OpData_dly_2nd_BSIV_Trim.mat', gen_data_path), ...
    'CallData', 'CallIV', 'CallVolDev', 'CallBidAsk', 'TTM_C', 'symbol_C', ...
 'PutData', 'PutIV', 'PutVolDev', 'PutBidAsk', 'TTM_P', 'symbol_P');
toc;