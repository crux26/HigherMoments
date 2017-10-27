%% IV_constMaturity_main

clear;clc;
Dorm = false;
if ~Dorm
    addpath('D:\Dropbox\GitHub\HigherMoments\from TRP');
    addpath('D:\Dropbox\GitHub\HigherMoments\data\codes\');
else
    addpath('F:\Dropbox\GitHub\HigherMoments\from TRP');
    addpath('F:\Dropbox\GitHub\HigherMoments\data\codes\');
end

addpath('F:\Dropbox\GitHub\HigherMoments\data\codes');
load('OpData_BSIV_2nd.mat', 'CallData', 'PutData', 'CallIV', 'PutIV', 'symbol_C', 'symbol_P');
% load('OpData_BSIV_1st.mat', 'CallData', 'PutData', 'CallIV', 'PutIV', 'symbol_C', 'symbol_P');



%% Vol_True replaced by IV_BS. Note that this IV is dividend-adjusted.
CallData(:,6) = CallIV;
PutData(:,6) = PutIV;
clear CallIV PutIV CallVolDev PutVolDev;

%%
[date_, ia_date_] = unique(CallData(:,1));      % date
[date__, ia_date__] = unique(PutData(:,1));

% [exdate_, ia_exdate_] = unique(CallData(:,2));  % exdate
% [exdate__, ia_exdate__] = unique(PutData(:,2));
if date_ ~= date__
    error('#dates(Call) ~= #dates(Put). Check the data.');
end

% idx_C_1st = zeros(length(CallData(:,2)), 1);
% idx_C_2nd = zeros(length(CallData(:,2)), 1);
% idx_P_1st = zeros(length(PutData(:,2)), 1);
% idx_P_2nd = zeros(length(PutData(:,2)), 1);

%% START AGAIN FROM HERE
jj = 1;
tmpIndexVec1 = ia_date_(jj):(ia_date_(jj+1)-1);
idx_C_1st = ia_date_(jj)-1 + find(CallData(tmpIndexVec1,2) == min(CallData(tmpIndexVec1, 2)) );
idx_C_Not1st = find(CallData(tmpIndexVec1,2) ~= min(CallData(tmpIndexVec1, 2)) );
idx_C_2nd = ia_date_(jj)-1 + find(CallData(tmpIndexVec1, 2) == min(CallData(idx_C_Not1st, 2)) );
if isequal(idx_C_1st, idx_C_2nd)
	idx_C_2nd = [];
end

tmpIndexVec2 = ia_date__(jj):(ia_date__(jj+1)-1);
idx_P_1st = ia_date__(jj)-1 + find(PutData(tmpIndexVec2, 2) == min(PutData(tmpIndexVec2, 2)) );
idx_P_Not1st = find(PutData(tmpIndexVec2, 2) ~= min(PutData(tmpIndexVec2, 2)) );
idx_P_2nd = ia_date__(jj)-1 + find(PutData(tmpIndexVec2, 2) == min(PutData(idx_P_Not1st, 2)) );
if isequal(idx_P_1st, idx_P_2nd)
    idx_P_2nd = [];
end

ia_date_ = [ia_date_; length(CallData(:,1))+1]; % to include the last index.
ia_date__ = [ia_date__; length(PutData(:,1))+1]; % unique() doesn't return the last index.

% Call works, Put not works

for jj=2:length(date_)
    tmpIndexVec1 = ia_date_(jj):(ia_date_(jj+1)-1);
    idx_C_1st = [idx_C_1st; ia_date_(jj)-1 + find(CallData(tmpIndexVec1,2) == min(CallData(tmpIndexVec1, 2)) )];
    idx_C_2nd = [idx_C_2nd; ia_date_(jj)-1 + find(CallData(tmpIndexVec1, 2) == max(CallData(tmpIndexVec1, 2)) )];
    
    tmpIndexVec2 = ia_date__(jj):(ia_date__(jj+1)-1);
    idx_P_1st = [idx_P_1st; ia_date__(jj)-1 + find(PutData(tmpIndexVec2, 2) == min(PutData(tmpIndexVec2, 2)) )];
    idx_P_2nd = [idx_P_2nd; ia_date__(jj)-1 + find(PutData(tmpIndexVec2, 2) == max(PutData(tmpIndexVec2, 2)) )];
end


%%
S = CallData(ia_date_, 11);                                     % CallData(:,11): spindx
DaysPerYear = 252;
r = CallData(ia_date_, 13) * DaysPerYear;                       % CallData(:,13): tb_m3, 1D HPR
q = CallData(ia_date_, 14);                                     % CallData(:,14): annualized dividend

T = yearfrac(CallData(ia_date_,1), CallData(ia_date_,2), 13);   % "T" is TTM, not expiry per se.
% tau1 = yearfrac(CallData(ia_date_,1), CallData(idx_C_1st,2), 13);
% tau2 = yearfrac(CallData(ia_date_,1), CallData(idx_C_2nd,2), 13);

if length(S) ~= length(ia_date_)
    error('Something is wrong. Re-check.');
end

ia_date_ = [ia_date_; length(CallData(:,1))+1]; % to include the last index.
ia_date__ = [ia_date__; length(PutData(:,1))+1]; % unique() doesn't return the last index.

% idx_C_1st = [idx_C_1st; length(idx_C_1st)];
% idx_C_2nd = [idx_C_2nd; length(idx_C_2nd)];

%%
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
%         T_ = T(jj);
%         [C, Kc, P, Kp, IV_C, IV_P] = OpTrim_wrapper(S_, C, Kc, P, Kp, r_, T_, IV_C, IV_P, q_, trimflag, Smoothing_IVonly);
%         % price2mom() cannot handle vector -> need to fix.
%         moment(jj,:) = price2mom(S_, C, Kc, P, Kp, r_, T_, IV_C, IV_P, q_, MomentRank);

    %%
    % 
    % function [IV_C_constMaturity, IV_P_constMaturity] = IV_constMaturityWrapper(CallData, PutData)
    % IV_C_constMaturity = interp1([t1; t2], [CallIV1; CallIV2], constMaturity, 'linear', 'extrap');
    % IV_P_constMaturity = interp1([t1; t2], [PutIV1; PutIV2], constMaturity, 'linear', 'extrap');
    % 
    catch
        warning('Problem with the function or data. Check again.');
    end
end
toc

%% rmpath

if ~Dorm
    rmpath('D:\Dropbox\GitHub\HigherMoments\data\codes\');
    rmpath('D:\Dropbox\GitHub\HigherMoments\from TRP');
else
    rmpath('F:\Dropbox\GitHub\HigherMoments\data\codes\');
    rmpath('F:\Dropbox\GitHub\HigherMoments\from TRP');
end