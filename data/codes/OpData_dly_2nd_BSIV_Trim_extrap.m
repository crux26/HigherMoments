%% <importOpData_2nd.m> -> <OPData_2nd_BSIV.m> -> <OPData_2nd_BSIV_Trim.m> -> <OpData_2nd_BSIV_Trim_extrap.m>
%% import data
clear; clc;
isDorm = false;
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

% Exclude NaN IVs: IVs will be used for extrap.
% If all IVs for (date, exdate) pair are NaN, then it's a problem.
idx_C = find(CallData(:,6) ~= -Inf & CallData(:,6) ~= Inf & ~isnan(CallData(:,6)));
CallData = CallData(idx_C, :);

idx_P = find(PutData(:,6) ~= -Inf & PutData(:,6) ~= Inf & ~isnan(PutData(:,6)));
PutData = PutData(idx_P, :);

% date=30Jun99.datenum() = 730301: Problematic date. Best to exclude it.
% idxC = find(CallData(:,1) ~=730301); idxP = find(PutData(:,1) ~=730301);
% 
% CallData = CallData(idxC, :); PutData = PutData(idxP, :);
% TTM_C = TTM_C(idxC); TTM_P = TTM_P(idxP);

% date=10Dec14.datenum()=735943: IV_P alternating a lot. Better to exclude it.
% idxC = find(CallData(:,1) ~= 735943); idxP = find(PutData(:,1) ~= 735943);
% CallData = CallData(idxC, :); PutData = PutData(idxP, :);
% TTM_C = TTM_C(idxC); TTM_P = TTM_P(idxP);
% clear idxC idxP;

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

%% IV extrapolation from 0.01% to 300% moneyness.

CallData_extrap = [];
PutData_extrap = [];
% Below takes: 2480s or 41.33m (LAB PC, daily data)
tic
for jj=1:length(date_)                   % Note that length(date_)+1==length(ia_date_) now.
    tmpIdx1 = ia_date_(jj):(ia_date_(jj+1)-1) ; % for call
    tmpIdx2 = ia_date__(jj):(ia_date__(jj+1)-1) ; % for put

%     CallData_extrap_ = IVextrap_ByExdate_mat(CallData(tmpIdx1, 1:end-1), CallData(tmpIdx1, end));
%     PutData_extrap_ = IVextrap_ByExdate_mat(PutData(tmpIdx2, 1:end-1), PutData(tmpIdx2, end));

    % Retrieve only 2 TTMs closest to 30D. This is copied from ~/ambiguity_premium/.
    [CallData_, PutData_] = idNear30D(CallData(tmpIdx1,:), PutData(tmpIdx2,:));
    CallData_extrap_ = IVextrap_ByExdate_mat(CallData_(:, 1:end-1), CallData_(:, end));
    PutData_extrap_ = IVextrap_ByExdate_mat(PutData_(:, 1:end-1), PutData_(:, end));
    %------------------------
    if any(PutData_extrap_.OpPrice < 0)
        disp(find(PutData_extrap_.OpPrice<0));
        disp('P < 0');
        break;
    end
    
    if any (PutData_extrap_.IV_extrap < 0)
        disp(find(PutData_extrap_.IV_extrap<0));
        disp('IV < 0');
        break;
    end
    %------------------------
    TTM_C_ = unique(CallData_extrap_.TTM);
    TTM_P_ = unique(PutData_extrap_.TTM);
    TTM_ = intersect(TTM_C_, TTM_P_);
    
    % Don't see the point of the below 2.
%     CallData_extrap_ = MatMatch(CallData_extrap_, TTM_);
%     PutData_extrap_ = MatMatch(PutData_extrap_, TTM_);
    
    CallData_extrap = [CallData_extrap; CallData_extrap_];
    PutData_extrap = [PutData_extrap; PutData_extrap_];
end
toc

%%
% CallData_extrap & PutData_extrap mismatch: try unique([date, exdate]) for both.
%%

% Below takes: 14s (LAB PC)
% IVextrap_ByExdate_mat() generates the grid w.r.t. moneyness, the inverse of K.
% Hence, with ascending moneyness, K is descending. The following sortings converts back the data
% into ascending K order.
tic;
CallData_extrap = sortrows(CallData_extrap, [1,2,3]); % sort by (date, exdate, strike)
PutData_extrap = sortrows(PutData_extrap, [1,2,3]);
toc;

% Below takes: 20s (LAB PC)
tic;
save(sprintf('%s\\OpData_dly_2nd_BSIV_Trim_extrap.mat', genData_path), ...
    'CallData_extrap', 'PutData_extrap');
toc;

rmpath(sprintf('%s\\data\\codes\\functions', homeDirectory));