%% <importOpData_2nd.m> -> <OPData_2nd_BSIV.m> -> <OPData_2nd_BSIV_Trim.m> -> <OpData_2nd_BSIV_Trim_extrap.m>
%% import data
clear; clc;
isDorm = 0;
if isDorm == true
    drive = 'E:';
else
    drive = 'E:';
end
homeDirectory = sprintf('%s\\Dropbox\\GitHub\\HigherMoments', drive);
genData_path = sprintf('%s\\data\\gen_data', homeDirectory);

addpath(sprintf('%s\\data\\codes\\functions', homeDirectory));

% OptionsData_genData_path = sprintf('%s\\Dropbox\\GitHub\\OptionsData\\data\\gen_data', drive);

% Below takes: 1.3s (DORM PC)
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

% date=30Jun99, datenum() = 730301: Problematic date. Best to exclude it.
% idxC = find(CallData(:,1) ~=730301); idxP = find(PutData(:,1) ~=730301);
% CallData = CallData(idxC, :); PutData = PutData(idxP, :);
% TTM_C = TTM_C(idxC); TTM_P = TTM_P(idxP);

% date=10Dec14, datenum()=735943: IV_P alternating a lot. Better to exclude it.
% idxC = find(CallData(:,1) ~= 735943); idxP = find(PutData(:,1) ~= 735943);
% CallData = CallData(idxC, :); PutData = PutData(idxP, :);
% TTM_C = TTM_C(idxC); TTM_P = TTM_P(idxP);
% clear idxC idxP;

%% Exclude data whose TTM < 5D. This will alleviate (date,exdate) pair mismatch b/w Call & Put.
idx_C = find(CallData(:,23) > 5/252); % daysdif(), yearfrac() would've been more accurate, but it's enough.
idx_P = find(PutData(:,23) > 5/252);
CallData = CallData(idx_C, :);
PutData = PutData(idx_P, :);


%% Use only the intersection of CallData.date & PutData.date.
[date_, ~] = unique(CallData(:,1));
[date__, ~] = unique(PutData(:,1));
date_intersect = intersect(date_, date__);

% Below takes: 0.04s (DORM PC)
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

%% Change CallData, PutData into tables.
CallData = table(CallData(:,1), CallData(:,2), CallData(:,3), CallData(:,4), CallData(:,5), ...
    CallData(:,6), CallData(:,7), CallData(:,8), CallData(:,9), CallData(:,10), CallData(:,11), CallData(:,12), ...
    CallData(:,13), CallData(:,14), CallData(:,15), CallData(:,16), CallData(:,17), CallData(:,18), CallData(:,19), ...
    CallData(:,20), CallData(:,21), CallData(:,22), CallData(:,23), ...
    'VariableNames', {'date', 'exdate', 'Kc', 'volume', 'open_interest', 'IV', 'delta', 'gamma', 'vega', 'theta', ...
    'S', 'sprtrn', 'r', 'q', 'spxset', 'spxset_expiry', 'moneyness', 'C', 'opret', 'cpflag', ...
    'min_datedif', 'min_datedif_2nd', 'TTM'});
    
PutData = table(PutData(:,1), PutData(:,2), PutData(:,3), PutData(:,4), PutData(:,5), ...
    PutData(:,6), PutData(:,7), PutData(:,8), PutData(:,9), PutData(:,10), PutData(:,11), PutData(:,12), ...
    PutData(:,13), PutData(:,14), PutData(:,15), PutData(:,16), PutData(:,17), PutData(:,18), PutData(:,19), ...
    PutData(:,20), PutData(:,21), PutData(:,22), PutData(:,23), ...
    'VariableNames', {'date', 'exdate', 'Kp', 'volume', 'open_interest', 'IV', 'delta', 'gamma', 'vega', 'theta', ...
    'S', 'sprtrn', 'r', 'q', 'spxset', 'spxset_expiry', 'moneyness', 'P', 'opret', 'cpflag', ...
    'min_datedif', 'min_datedif_2nd', 'TTM'});

% Drop delta, gamma, vega, theta, spxset_expiry: NaN will return weird results.
% ex) unique([NaN, NaN]) = [NaN, NaN], which is an unexpected result.
% This yields duplicates in the unique() in the for loop below.
CallData.delta = []; CallData.gamma = []; CallData.vega = []; CallData.theta = []; CallData.spxset_expiry = [];
PutData.delta = []; PutData.gamma = []; PutData.vega = []; PutData.theta = []; PutData.spxset_expiry = [];

%% IV extrapolation from 0.01% to 300% moneyness.
%% jj=2861, date_==733178 is troublesome.
CallData_extrap = [];
PutData_extrap = [];
idx_problematic = [];

% Below takes: 1042s or 17.4m (LAB PC, daily data)
tic
for jj=1:length(date_)                   % Note that length(date_)+1==length(ia_date_) now.
    try
        tmpIdx1 = ia_date_(jj):(ia_date_(jj+1)-1) ; % for call
        tmpIdx2 = ia_date__(jj):(ia_date__(jj+1)-1) ; % for put

        % idNear30D(): Retrieve only 2 TTMs closest to 30D. This is copied from ~/ambiguity_premium/.
        [CallData_, PutData_] = idNear30D(CallData(tmpIdx1,:), PutData(tmpIdx2,:));
        % dropEnd_OTMC() cannot process multiple exdates. Hence, splitting w.r.t. SplitByExdate.
        % As idNear30D() is run already, there should be at most 2 exdates for each date.
        [CallData_1, CallData_2] = SplitByExdate(CallData_);
        CallData_1 = dropEnd_OTMC(CallData_1); CallData_2 = dropEnd_OTMC(CallData_2);
        CallData_ = unique([CallData_1; CallData_2], 'rows'); % unique() needed for interp1() in IVextrap_ByExdate_mat

        [PutData_1, PutData_2] = SplitByExdate(PutData_);
        PutData_1 = dropEnd_OTMP(PutData_1); PutData_2 = dropEnd_OTMP(PutData_2);
        PutData_ = unique([PutData_1; PutData_2], 'rows'); % unique() needed for interp1() in IVextrap_ByExdate_mat
        %---------------
        CallData_extrap_ = IVextrap_ByExdate_mat(CallData_(:, 1:end-1), CallData_(:, end));
        PutData_extrap_ = IVextrap_ByExdate_mat(PutData_(:, 1:end-1), PutData_(:, end));
        %------------------------
%         if size(CallData_extrap_,1) ~= size(PutData_extrap_,1)
%             disp('CallData.len() ~= PutData.len()');
%             break;
%         end

        if any(CallData_extrap_.OpPrice < 0) || any(PutData_extrap_.OpPrice < 0)
            disp('C<0 || P<0');
            break;
        end

        if any (CallData_extrap_.IV_extrap < 0) || any(PutData_extrap_.IV_extrap < 0)
            disp('IV_C<0 || IV_P<0');
            break;
        end

        CallData_extrap = [CallData_extrap; CallData_extrap_];
        PutData_extrap = [PutData_extrap; PutData_extrap_];
    catch
        idx_problematic = [idx_problematic; jj];
    end
end
toc

%%

% Below takes: 8s (LAB PC)
% IVextrap_ByExdate_mat() generates the grid w.r.t. moneyness, the inverse of K.
% Hence, with ascending moneyness, K is descending. The following sortings converts back the data
% into ascending K order.
tic;
CallData_extrap = sortrows(CallData_extrap, [1,2,3]); % sort by (date, exdate, strike)
PutData_extrap = sortrows(PutData_extrap, [1,2,3]);
toc;

%%
% Below takes: 13s (LAB PC)
tic;
save(sprintf('%s\\OpData_dly_2nd_BSIV_Trim_extrap.mat', genData_path), ...
    'CallData_extrap', 'PutData_extrap');
toc;

rmpath(sprintf('%s\\data\\codes\\functions', homeDirectory));
