%% <importOpData_2nd.m> -> <OPData_2nd_BSIV.m> -> <OPData_2nd_BSIV_Trim.m> -> <OpData_2nd_BSIV_Trim_extrap.m>
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

addpath(sprintf('%s\\data\\codes\\functions', homeDirectory));

% OptionsData_genData_path = sprintf('%s\\Dropbox\\GitHub\\OptionsData\\data\\gen_data', drive);

% Below takes: 5.3s (DORM PC)
tic;
load(sprintf('%s\\OpData_dly_2nd_BSIV_Trim.mat', genData_path), ...
    'CallData', 'PutData', 'CallIV', 'PutIV', 'symbol_C', 'symbol_P', 'TTM_C', 'TTM_P');
toc;

%% Vol_True replaced by IV_BS. Note that this IV is dividend-adjusted.
CallData(:,6) = CallIV;
PutData(:,6) = PutIV;
clear CallIV PutIV CallVolDev PutVolDev;

CallData = [CallData, TTM_C];
PutData = [PutData, TTM_P];

% date=30Jun99.datenum() = 730301: Problematic date. Best to exclude it.
% idxC = find(CallData(:,1) ~=730301);
% idxP = find(PutData(:,1) ~=730301);
% 
% CallData = CallData(idxC, :);
% PutData = PutData(idxP, :);
% TTM_C = TTM_C(idxC);
% TTM_P = TTM_P(idxP);

% date=10Dec14.datenum()=735943: IV_P alternating a lot. Better to exclude it.
% idxC = find(CallData(:,1) ~= 735943);
% idxP = find(PutData(:,1) ~= 735943);
% CallData = CallData(idxC, :);
% PutData = PutData(idxP, :);
% TTM_C = TTM_C(idxC);
% TTM_P = TTM_P(idxP);
% clear idxC idxP;

%% Select put > 103% moneyness, call < 97% moneyness
% Below makes #dates(Call) ~= #dates(Put).
CallData = CallData(CallData(:,17) < 0.97, :);
PutData = PutData(PutData(:,17) > 1.03, :);

%% Use only the intersection of CallData.date & PutData.date.
[date_, ~] = unique(CallData(:,1));
[date__, ~] = unique(PutData(:,1));
date_intersect = intersect(date_, date__);

% Below takes: 0.01s (DORM PC)
tic;
idxC = ismember(CallData(:,1), date_intersect);
idxP = ismember(PutData(:,1), date_intersect);
toc;

CallData = CallData(idxC, :);
PutData = PutData(idxP, :);
%%
[date_, ia_date_] = unique(CallData(:,1));
[date__, ia_date__] = unique(PutData(:,1));
if ~isequal(date_, date__)
    error('#dates(Call) ~= #dates(Put). Check the data.');
end

ia_date_ = [ia_date_; length(CallData(:,1))+1]; % to include the last index.
ia_date__ = [ia_date__; length(PutData(:,1))+1]; % unique() doesn't return the last index.

%% IV extrapolation from 1% to 300% moneyness.
exdateC_ByDate = [];
exdateP_ByDate = [];

CallData_extrap = [];
PutData_extrap = [];
% Below takes: 10.5s (LAB PC, MnthEnd data) --> 2415.11s or 40.25m (DORM PC, daily data)
tic
for jj=1:length(date_)                   % Note that length(date_)+1==length(ia_date_) now.
    tmpIdx1 = ia_date_(jj):(ia_date_(jj+1)-1) ; % for call
    tmpIdx2 = ia_date__(jj):(ia_date__(jj+1)-1) ; % for put
    
    PutData_extrap_ = IVextrap_ByExdate_mat(PutData(tmpIdx2, 1:end-1), PutData(tmpIdx2, end));
    CallData_extrap_ = IVextrap_ByExdate_mat(CallData(tmpIdx1, 1:end-1), CallData(tmpIdx1, end));
    
    TTM_P_ = unique(PutData_extrap_.TTM);
    TTM_C_ = unique(CallData_extrap_.TTM);
    TTM_ = intersect(TTM_C_, TTM_P_);
    
    CallData_extrap_ = MatMatch(CallData_extrap_, TTM_);
    PutData_extrap_ = MatMatch(PutData_extrap_, TTM_);
    
    CallData_extrap = [CallData_extrap; CallData_extrap_];
    PutData_extrap = [PutData_extrap; PutData_extrap_];
end
toc

% Below takes: 17.5s (DORM PC)
tic;
save(sprintf('%s\\OpData_dly_2nd_BSIV_Trim_extrap.mat', genData_path), ...
    'CallData_extrap', 'PutData_extrap');
toc;
rmpath(sprintf('%s\\data\\codes\\functions', homeDirectory));