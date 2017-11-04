%% main: HigherMoments
%% import data
clear;clc;
isDorm = false;

if isDorm == true
    drive = 'F:';
else
    drive = 'D:';
end
homeDirectory = sprintf('%s\\Dropbox\\GitHub\\HigherMoments', drive);
gen_data_path = sprintf('%s\\data\\gen_data', homeDirectory);
addpath('%s\\main_functions', homeDirectory);


load(sprintf('%s\\rawOpData_1st.mat', gen_data_path), 'CallData', 'PutData', 'symbol_C', 'symbol_P');
% load('OpData_BSIV_2nd.mat', 'CallData', 'PutData', 'CallIV', 'PutIV', 'symbol_C', 'symbol_P', 'TTM_C', 'TTM_P');
% load('smpl_set.mat');

%% Vol_True replaced by IV_BS. Note that this IV is dividend-adjusted.
CallData(:,6) = CallIV;
PutData(:,6) = PutIV;
clear CallIV PutIV CallVolDev PutVolDev;

% date=30Jun99.datenum() = 730301: Problematic date. Best to exclude it.
CallData = CallData(CallData(:,1) ~= 730301, :);
PutData = PutData(PutData(:,1) ~= 730301, :);

% date=10Dec14.datenum()=735943: IV_P alternating a lot. Better to exclude it.
CallData = CallData(CallData(:,1) ~= 735943, :);
PutData = PutData(PutData(:,1) ~= 735943, :);

%% Select put > 103% moneyness, call < 97% moneyness
% CallData = CallData(CallData(:,17) < 0.97, :);
% PutData = PutData(PutData(:,17) > 1.03, :);

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
TTM = yearfrac(CallData(ia_date_,1), CallData(ia_date_,2), 13);   % "T" is TTM, not expiry per se.

if length(S) ~= length(ia_date_)
    error('Something is wrong. Re-check.');
end

ia_date_ = [ia_date_; length(CallData(:,1))+1]; % to include the last index.
ia_date__ = [ia_date__; length(PutData(:,1))+1]; % unique() doesn't return the last index.

%%
trimflag = 0;           % trimflag==1: Kernel Smoothing Regression
Smoothing_IVonly = 1;

MomentRank = 1:4 ;
momPrice = zeros(length(date_), length(MomentRank));

% Below takes 21.7s (LAB PC)
% idx_err=0;
% idx_err_dates=[];
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
        TTM_ = TTM(jj);
        [C, Kc, P, Kp, IV_C, IV_P] = OpTrim_wrapper(S_, C, Kc, P, Kp, r_, TTM_, IV_C, IV_P, q_, trimflag, Smoothing_IVonly);
        % price2mom() cannot handle vector -> need to fix.
        momPrice(jj,:) = OpPrice2momPrice(S_, C, Kc, P, Kp, r_, TTM_, IV_C, IV_P, q_, MomentRank);
    catch
        warning('Problem with the function or data. Check again.');
%         idx_err=idx_err+1;
%         idx_err_dates(end+1)=date_(jj);
    end
end
toc

%%
% Below works in the global, but not in local workspace.
% for j=1:size(moment,2)
%     assignin('base', sprintf('moment%d',j), moment(:,j));
% end

tbl_momPrice = table_momPrice(momPrice);
momPrice = [tbl_momPrice.momPrice1, tbl_momPrice.momPrice2, ...
    tbl_momPrice.momPrice3, tbl_momPrice.momPrice4];

save(sprintf('%s\\result_momPrice.mat', homeDirectory), 'momPrice', 'tbl_momPrice', 'date_');

%%
[SKEW, KURT] = momPrice2mom(tbl_momPrice.momPrice2, tbl_momPrice.momPrice3, tbl_momPrice.momPrice4, r, TTM);
T_tmp = table(datestr(date_), SKEW, KURT);
x = 1:1028;
figure; plot(x,SKEW); title('SKEW');
figure; plot(x,KURT); title('KURT');

%%
% date_(975)=735943='10Dec2014' seems problematic.
% addpath('D:\Dropbox\GitHub\HigherMoments\test');
% trimflag = 0;           % trimflag==1: Kernel Smoothing Regression
% Smoothing_IVonly = 1;
% moments = unit_test_main(975, trimflag, Smoothing_IVonly);
% rmpath('D:\Dropbox\GitHub\HigherMoments\test');

rmpath('%s\\main_functions', homeDirectory);