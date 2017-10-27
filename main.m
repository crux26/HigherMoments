%% main: HigherMoments
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
load('OpData_BSIV_1st.mat', 'CallData', 'PutData', 'CallIV', 'PutIV', 'symbol_C', 'symbol_P');
% load('smpl_set.mat');



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
trimflag = 0;           % trimflag==1: Kernel Smoothing Regression
Smoothing_IVonly = 1;

MomentRank = 1:4 ;
moment = zeros(length(date_), length(MomentRank));

% Below takes 30s.
tic
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
        S_ = S(jj);
        r_ = r(jj);
        q_ = q(jj);
        T_ = T(jj);
        [C, Kc, P, Kp, IV_C, IV_P] = OpTrim_wrapper(S_, C, Kc, P, Kp, r_, T_, IV_C, IV_P, q_, trimflag, Smoothing_IVonly);
        % price2mom() cannot handle vector -> need to fix.
        moment(jj,:) = price2mom(S_, C, Kc, P, Kp, r_, T_, IV_C, IV_P, q_, MomentRank);
    catch
        warning('Problem with the function or data. Check again.');
    end
end
toc

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

save('result_moment', 'moment');