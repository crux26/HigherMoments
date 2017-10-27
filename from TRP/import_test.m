%% import data - 1st month only for both call and put
clear;clc;
addpath('D:\Dropbox\GitHub\TRP\data\codes');
addpath('F:\Dropbox\GitHub\TRP\data\codes');
% load('DataTrim_IVTrim_1st.mat', 'CallData', 'PutData');
% load('DataTrim_IVnoTrim_1st.mat', 'CallData', 'PutData');
% load('rawOpData_1st.mat', 'CallData', 'PutData');
load('OpData_BSIV_1st.mat', 'CallData', 'CallIV', 'CallVolDev', 'PutData', 'PutIV', 'PutVolDev'); saveflag=0;
% load('OpData_BSIV_1st_NearMoney.mat', 'CallData', 'CallIV', 'CallVolDev', 'PutData', 'PutIV', 'PutVolDev'); saveflag=1;
% load('OpData_BSIV_2nd.mat', 'CallData', 'CallIV', 'CallVolDev', 'PutData', 'PutIV', 'PutVolDev');
rmpath('F:\Dropbox\GitHub\TRP\data\codes');
rmpath('D:\Dropbox\GitHub\TRP\data\codes');


% CallData = [date, exdate, strike_price, volume, open_interest, impl_volatility, ...
%     delta, gamma, vega, theta, spindx, sprtrn, ...
%     tb_m3, div, spxset, spxset_expiry, moneyness, mid, ...
%     opret];
% 
% CallData(:,20) = 0; % cpflag: call == 0

%% Vol_True replaced by IV_BS. Note that this IV is dividend-adjusted.
CallData(:,6) = CallIV;
PutData(:,6) = PutIV;
% CallData = CallData(1:1011,:);
% PutData = PutData(1:1010,:);
clear CallIV PutIV CallVolDev PutVolDev;

%% Discarding extraordinary cases
% % j==77, t=729580, T=729618
% CallData = CallData(CallData(:,1)~=729580,:); 
% PutData = PutData(PutData(:,1)~=729580,:);
% 
% j==506, t=732618: 3-4 right tail data increasing.
% CallData = CallData(CallData(:,1)~=732618,:); 
% PutData = PutData(PutData(:,1)~=732618,:);
%
% j==586, t=733178, T=733209
% CallData = CallData(CallData(:,1)~=733178,:); % C(K=1700)=0.025, C(K=1800)=9.4
% PutData = PutData(PutData(:,1)~=733178,:);
% 
% j==601, t=733290: NO error. Outlier because Kp_OTM_star>>Kp_OTM everywhere (in ExpectedShortfall.m)
% CallData = CallData(CallData(:,1)~=733290,:); 
% PutData = PutData(PutData(:,1)~=733290,:);
% 
% % j==608, t=733339
% CallData = CallData(CallData(:,1)~=733339,:);
% PutData = PutData(PutData(:,1)~=733339,:);
% 
% % j==612, t=733367: Call alternating in tail.
% CallData = CallData(CallData(:,1)~=733367,:);
% PutData = PutData(PutData(:,1)~=733367,:);

%%
[date_, ia_date_] = unique(CallData(:,1));
[date__, ia_date__] = unique(PutData(:,1));
if date_ ~= date__
    error('#dates(Call) ~= #dates(Put). Check the data.');
end

%%
S = CallData(ia_date_, 11);                                     % CallData(:,11): spindx
DaysPerYear = 252;
r = CallData(ia_date_, 13) * DaysPerYear;                       % CallData(:,13): tb_m3, 1D HPR
q = CallData(ia_date_, 14);                                     % CallData(:,14): annualized dividend
T = yearfrac(CallData(ia_date_,1), CallData(ia_date_,2), 13);   % "T" is TTM, not expiry per se.

if length(S) ~= length(ia_date_)
    error('Something is wrong. Re-check.');
end

%%

[VaR, ES, UP, EUP, TRP, ETRP] = deal(zeros(1,length(date_)));


ia_date_ = [ia_date_; length(CallData(:,1))+1]; % to include the last index.
ia_date__ = [ia_date__; length(PutData(:,1))+1]; % unique() doesn't return the last index.

% Above "+1" is needed for the trick for the for-loop below.
% By doing so, can access the bottommost row index of CallData(:,1) through the for-loop below.

%% Problematic "j": 11 (Warning), 12 (Error) (for pchip)
% for spline, problem with even j==1. Start again from here.
% Sometimes pchip being more problematic, sometimes spline being so.

addpath('D:\Dropbox\GitHub\TRP');
addpath('D:\Dropbox\GitHub\TRP\test\IV');

addpath('F:\Dropbox\GitHub\TRP');
addpath('F:\Dropbox\GitHub\TRP\test\IV');


alpha_ = [1,5,10];                              % alpha_: given as an int
% alpha_ = 10;
% try using "try-catch" inside the for-loop
for i_=1:length(alpha_)
    [VaR, ES, UP, EUP, TRP, ETRP] = deal(zeros(1,length(date_)));
    VaR_=VaR'; ES_=ES'; UP_=UP'; EUP_=EUP'; TRP_=TRP'; ETRP_=ETRP';
    alpha = alpha_(i_);
    % Below takes: 412s or 6.9m --> 9s. (parfor, LAB PC)
    % Below takes: 1161s or 19.35m --> < 20s. (for, LAB PC)
    tic
    ii=0;   % The number of errors in index_P_tail or index_C_tail.
    for jj=1:length(date_)                   % Note that length(date_)+1==length(ia_date_) now.
        try
            tmpIndexVec1 = ia_date_(jj):(ia_date_(jj+1)-1) ;
            tmpIndexVec2 = ia_date__(jj):(ia_date__(jj+1)-1) ;

            [VaR(jj), ES(jj), UP(jj), EUP(jj), TRP(jj), ETRP(jj)]= ...
                TailRisk_mimic(S(jj), ...
                CallData(tmpIndexVec1, 18), ... % CallData(:,18): call's mid price (C)
                CallData(tmpIndexVec1, 3), ...  % CallData(:,3): call's strike price (Kc)
                PutData(tmpIndexVec2, 18), ...  % PutData(:,18): put's mid price (P)
                PutData(tmpIndexVec2, 3),...    % PutData(:,3): put's strike price (Kp)
                r(jj), T(jj), alpha, ...
                CallData(tmpIndexVec1, 6), ...  % IV_C
                PutData(tmpIndexVec2, 6), ...   % IV_P
                q(jj));                          % dividend
        catch
            ii=ii+1;
        end
    end
    toc
    resultmat = [VaR; ES; UP; EUP; TRP; ETRP];
    VaR_=VaR'; ES_=ES'; UP_=UP'; EUP_=EUP'; TRP_=TRP'; ETRP_=ETRP';
    resultTable = table(VaR_, ES_, UP_, EUP_, TRP_, ETRP_);
    numErrPt = ii;
    if saveflag==0
        save(sprintf('result_alpha_%d.mat', alpha), 'VaR', 'ES', 'UP', 'EUP', 'TRP', 'ETRP', 'resultTable', 'numErrPt');
    elseif saveflag==1
        save(sprintf('result_NearmMoney_alpha_%d.mat', alpha), 'VaR', 'ES', 'UP', 'EUP', 'TRP', 'ETRP', 'resultTable','numErrPt');
    end
    clear i_ ii jj;
end


rmpath('F:\Dropbox\GitHub\TRP\test\IV');
rmpath('F:\Dropbox\GitHub\TRP');

rmpath('D:\Dropbox\GitHub\TRP\test\IV');
rmpath('D:\Dropbox\GitHub\TRP');


%%
% id_outlier(10);
id_outlier([1,5,10]);
alpha=5;
[VaR,ES,UP,EUP,TRP,ETRP]=import_test_unit(alpha, 95);
plot_figures(10);