%% main_unit_test: HigherMoments
%% import data
clear;clc;
Dorm = true;
if ~Dorm
    addpath('D:\Dropbox\GitHub\HigherMoments\from TRP');
    addpath('D:\Dropbox\GitHub\HigherMoments\data\codes\');
    addpath('D:\Dropbox\GitHub\HigherMoments\Kernel Smoothing Regression\ksr');
else
    addpath('F:\Dropbox\GitHub\HigherMoments\from TRP');
    addpath('F:\Dropbox\GitHub\HigherMoments\data\codes\');
    addpath('F:\Dropbox\GitHub\HigherMoments\Kernel Smoothing Regression\ksr');
end
% load('rawOpData_1st.mat', 'CallData', 'PutData', 'symbol_C', 'symbol_P');
load('OpData_BSIV_1st.mat','CallData', 'CallIV', 'CallVolDev', 'PutData', 'PutIV', 'PutVolDev', 'symbol_C', 'symbol_P');
load('smpl_set.mat');



%% Vol_True replaced by IV_BS. Note that this IV is dividend-adjusted.
CallData(:,6) = CallIV;
PutData(:,6) = PutIV;
clear CallIV PutIV CallVolDev PutVolDev;

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

ia_date_ = [ia_date_; length(CallData(:,1))+1]; % to include the last index.
ia_date__ = [ia_date__; length(PutData(:,1))+1]; % unique() doesn't return the last index.

%%
for jj=1:length(date_)                   % Note that length(date_)+1==length(ia_date_) now.
    try
        tmpIndexVec1 = ia_date_(jj):(ia_date_(jj+1)-1) ;
        tmpIndexVec2 = ia_date__(jj):(ia_date__(jj+1)-1) ;
        C = CallData(tmpIndexVec1, 18);     % CallData(:,18): call's mid price (C)
        Kc = CallData(tmpIndexVec1, 3);     % CallData(:,3): call's strike price (Kc)
        P = PutData(tmpIndexVec2, 18);      % PutData(:,18): put's mid price (P)
        Kp = PutData(tmpIndexVec2, 3);      % PutData(:,3): put's strike price (Kp)
        IV_C = CallData(tmpIndexVec1, 6);   % IV_C
        IV_P = PutData(tmpIndexVec2, 6);    % IV_P
    catch
        warning('Problem with the function or data. Check again.');
    end
end

%% "Smoothing"
trimflag = 0;           % trimflag==1: Kernel Smoothing Regression
Smoothing_IVonly = 1;

if trimflag == 0        % "Smoothing" through interp/extrap.
    [C, Kc, P, Kp, IV_C, IV_P] = OpTrim(S, C, Kc, P, Kp, r, T, IV_C, IV_P, q);

elseif trimflag == 1    % "Smoothing" through Kernel Smoothing Regression
    bandwidth = 2;
    nPt = 100;    % calculates the regression in n points (default:100)
    r_IV_C = ksr(Kc, IV_C, bandwidth, nPt);
    r_IV_P = ksr(Kp, IV_P, bandwidth, nPt);
    IV_C = interp1(r_IV_C.x, r_IV_C.f, Kc, 'nearest', 'extrap');
    IV_P = interp1(r_IV_P.x, r_IV_P.f, Kp, 'nearest', 'extrap');
    
    if Smoothing_IVonly == 1
%         [C, ~] = blsprice(S, Kc, r, T, IV_C, q);
%         [~, P] = blsprice(S, Kp, r, T, IV_P, q);
        C = myblscall(S*ones(length(Kc),1),Kc,r,T,IV_C,q);
        P = myblsput(S*ones(length(Kp),1),Kp,r,T,IV_P,q);
    else
        r_C = ksr(Kc, C, bandwidth, nPt);
        r_P = ksr(Kp, P, bandwidth, nPt);
        C = interp1(r_C.x, r_C.f, Kc, 'nearest', 'extrap');
        P = interp1(r_P.x, r_P.f, Kp, 'nearest', 'extrap');
    end
end

%% 
MomentRank = (1:4);
moment = price2mom(S, C, Kc, P, Kp, r, T, IV_C, IV_P, q, MomentRank);
%% rmpath

if ~Dorm
    rmpath('D:\Dropbox\GitHub\HigherMoments\Kernel Smoothing Regression\ksr');
    rmpath('D:\Dropbox\GitHub\HigherMoments\data\codes\');
    rmpath('D:\Dropbox\GitHub\HigherMoments\from TRP');
else
    rmpath('F:\Dropbox\GitHub\HigherMoments\Kernel Smoothing Regression\ksr');
    rmpath('F:\Dropbox\GitHub\HigherMoments\data\codes\');
    rmpath('F:\Dropbox\GitHub\HigherMoments\from TRP');
end