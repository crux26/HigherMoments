%% main_replicating() -> main_tsreg().
%% main: HigherMoments
% Ultimate goal: Calculate option implied moments and pass the results to main_tsreg().
% Current goal: Let my own results match with the paper's data.

%% import data
clear;clc;
isDorm = true;
if isDorm == true
    drive = 'F:';
else
    drive = 'D:';
end
homeDirectory = sprintf('%s\\Dropbox\\GitHub\\HigherMoments', drive);
genData_path = sprintf('%s\\data\\gen_data', homeDirectory);
addpath(sprintf('%s\\main_functions', homeDirectory));

% Below takes: 4.3s (LAB PC)
tic;
load(sprintf('%s\\OpData_dly_2nd_BSIV_Trim_extrap.mat', genData_path), ...
    'CallData_extrap', 'PutData_extrap');
toc;

%% Renaming the variables.
CallData = CallData_extrap; PutData = PutData_extrap; clear CallData_extrap PutData_extrap;

% %% Exlcluding crazy data points.
% % date=30Jun99.datenum() = 730301: Problematic date. Best to exclude it.
% CallData = CallData(CallData.date ~=730301, :);
% PutData = PutData(PutData.date ~=730301, :);
% 
% % date=10Dec14.datenum()=735943: IV_P alternating a lot. Better to exclude it.
% CallData = CallData(CallData.date ~= 735943, :);
% PutData = PutData(PutData.date ~= 735943, :);

%% Indexing for Call.date & Put.date. #(date)=239, as 30Jun1999 is excluded.
[date_, idx_date_] = unique(CallData.date);
[date__, idx_date__] = unique(PutData.date);
if date_ ~= date__
    error('#dates(Call) ~= #dates(Put). Check the data.');
end

idx_date_ = [idx_date_; length(CallData.date)+1]; % to include the last index.
idx_date__ = [idx_date__; length(PutData.date)+1]; % unique() doesn't return the last index.

%% Indexing for Call.exdate & Put.exdate.
% Below takes: 4.6s (LAB PC)
% retrieveExdates(): for: 4.5s, parfor: 105s (DORM PC)
tic;
[exdate_, idx_exdate_, exdate__, idx_exdate__,dates_] = retrieveExdates(CallData, PutData);
toc;
idx_exdate_ = [idx_exdate_; length(CallData.exdate)+1];
idx_exdate__ = [idx_exdate__; length(PutData.exdate)+1];

idx_exdate_next = idx_exdate_(2:end)-1;
idx_exdate__next = idx_exdate__(2:end)-1;
idx_exdate_ = idx_exdate_(1:end-1);
idx_exdate__ = idx_exdate__(1:end-1);
%% Compare with main().
% Problematic: jj==4949. Note that momPrice3(jj=4949)==2(>0).
trimflag = 0;
Smoothing_IVonly = 1;
MomentRank = 1:4;
momPrice = zeros(length(dates_), length(MomentRank)); % dates_ used to be date_: Check the diff.
S = zeros(length(dates_), 1);
r = zeros(length(dates_), 1); q = zeros(length(dates_), 1); TTM = zeros(length(dates_), 1);
% Below takes: 23.7s -> 22.9s (LAB, DORM. parfor: 103.6s, LAB)
tic
% Calculate by exdate, not date.
for jj=1:length(exdate_)                % Note that length(date_)+1==length(ia_date_) now.
    tmpIdx1 = idx_exdate_(jj):idx_exdate_next(jj) ; % for call
    tmpIdx2 = idx_exdate__(jj):idx_exdate__next(jj) ; % for put

    C = CallData.OpPrice(tmpIdx1);      % CallData(:,18): call's mid price (C)
    Kc = CallData.strike(tmpIdx1);      % CallData(:,3): call's strike price (Kc)
    P = PutData.OpPrice(tmpIdx2);       % PutData(:,18): put's mid price (P)
    Kp = PutData.strike(tmpIdx2);       % PutData(:,3): put's strike price (Kp)
    IV_C = CallData.IV_extrap(tmpIdx1); % IV_C
    IV_P = PutData.IV_extrap(tmpIdx2);  % IV_P
    
    S(jj) = unique(CallData.S(tmpIdx1));
    r(jj) = unique(CallData.r(tmpIdx1));       % == r__ = unique(PutData.r(tmpIdx2));
    q(jj) = unique(CallData.q(tmpIdx1));
    TTM(jj) = unique(CallData.TTM(tmpIdx1));   % == PutData.TTM(tmpIdx2);
   
%     figure; plot(Kc,C); xlabel('Kc'); ylabel('C'); title(sprintf('%4.f', jj)); grid on;
%     figure; plot(Kp,P); xlabel('Kp'); ylabel('P'); title(sprintf('%4.f', jj)); grid on;
    
    momPrice(jj,:) = OpPrice2momPrice(S(jj), C, Kc, P, Kp, r(jj), TTM(jj), IV_C, IV_P, q(jj), MomentRank);
end
toc
T_mmtPrice = table(dates_, exdate_, momPrice(:,2), momPrice(:,3), momPrice(:,4), r, TTM, ...
    'VariableName', {'date_', 'exdate_', 'momPrice2', 'momPrice3', 'momPrice4', 'r', 'TTM'}); 

save(sprintf('%s\\mmtPrice.mat', homeDirectory), 'T_mmtPrice');

[SKEW, KURT] = momPrice2mom(momPrice(:,2), momPrice(:,3), momPrice(:,4), r, TTM);

%% idx_mmt_datediff needed for idNear30D_mmt().
% Intrivial, but checked.
idx_mmt_datediff = find(diff(dates_)~=0); idx_mmt_datediff = idx_mmt_datediff+1;
idx_mmt_datediff = [1; idx_mmt_datediff; length(dates_)+1];
idx_mmt_datediffNext = idx_mmt_datediff(2:end)-1;
idx_mmt_datediff = idx_mmt_datediff(1:end-1);

%% T_mmt_, T_mmt___ will be the result table. (T_mmt: input table)
DTM = daysdif(dates_, exdate_, 13);
T_mmt = table(dates_, exdate_, SKEW, KURT, DTM);
T_mmt_ = array2table( nan(length(idx_exdate_),5), ...
    'VariableNames', {'dates_', 'exdate_', 'SKEW', 'KURT', 'DTM'});

% Below takes: 5.9s -> 5.0s (LAB, DORM)
tic;
for jj=1:length(idx_mmt_datediff)
    tmpIdx = idx_mmt_datediff(jj):idx_mmt_datediffNext(jj) ; % for call
    tmpTbl = idNear30D_mmt( T_mmt(tmpIdx, :) );
    T_mmt_(tmpIdx(1):tmpIdx(1)+size(tmpTbl,1)-1,:) = tmpTbl;
end
toc;
T_mmt_ = T_mmt_( isnan(T_mmt_.dates_) ~= 1, : );

%% New indexing needed for below: As dates_ ~= T_mmt_.dates_.

idx_mmt_datediff_ = find(diff(T_mmt_.dates_)~=0); idx_mmt_datediff_ = idx_mmt_datediff_+1;
idx_mmt_datediff_ = [1; idx_mmt_datediff_; length(T_mmt_.dates_)+1];
idx_mmt_datediff_Next = idx_mmt_datediff_(2:end)-1;
idx_mmt_datediff_ = idx_mmt_datediff_(1:end-1);

% length(idx_exdate_): >> than needed, as idNear30D_mmt() returns
% atmost 2 for each date (ideally)
T_mmt__ = array2table( nan(length(unique(T_mmt_.dates_))*2,5), ...
    'VariableNames', {'date_', 'exdate_artificial', 'SKEW', 'KURT', 'DTM'});

% Below takes: 8.8s -> 7.6s (LAB, DORM)
tic;
for jj=1:length(idx_mmt_datediff_)
    tmpIdx = idx_mmt_datediff_(jj):idx_mmt_datediff_Next(jj) ; % for call
    tmpTbl = mmt_interp30D(T_mmt_(tmpIdx, :));
    T_mmt__(tmpIdx(1):tmpIdx(1)+size(tmpTbl,1)-1, :) = tmpTbl;
end
toc;

T_mmt__ = T_mmt__( isnan(T_mmt__.date_) ~= 1, :);
T_mmt_interp = T_mmt__;
save(sprintf('%s\\SKEWKURT.mat', homeDirectory), 'T_mmt_interp', 'T_mmtPrice');
%%

rmpath(sprintf('%s\\main_functions', homeDirectory));