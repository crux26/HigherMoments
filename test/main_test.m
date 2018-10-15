% [SKEW, KURT, T_mmtPrice] = unit_test_main_replicating(id_mx);

%% main_test().
clear;clc;
isDorm = true;
if isDorm == true
    drive = 'E:';
else
    drive = 'E:';
end
homeDirectory = sprintf('%s\\Dropbox\\GitHub\\HigherMoments', drive);
genData_path = sprintf('%s\\data\\gen_data', homeDirectory);
addpath(sprintf('%s\\main_functions', homeDirectory));
addpath(sprintf('%s\\test', homeDirectory));
addpath(homeDirectory);

tic;
load(sprintf('%s\\OpData_dly_2nd_BSIV_Trim_extrap.mat', genData_path), ...
    'CallData_extrap', 'PutData_extrap');
toc;
CallData = CallData_extrap; PutData = PutData_extrap; clear CallData_extrap PutData_extrap;

%% Compare SKEW
load('SKEWKURT.mat', 'T_mmt_interp', 'T_mmtPrice');
load('SKEWKURT_mmt.mat', 'T_mmt');
date_intersection = intersect(T_mmt_interp.date_, T_mmt.date);
T_mmt_interp = T_mmt_interp( ismember(T_mmt_interp.date_, date_intersection), :);
T_mmt = T_mmt( ismember(T_mmt.date, date_intersection), :);


%% T_mmt.date(id_mx) == 729547; IV_extrap little fluctuates in the end, but nothing wrong in prices.
[mx, id_mx] = max(T_mmt_interp.SKEW);
date_prblm = T_mmt_interp.date_(id_mx);
CallData_ = CallData(CallData.date == date_prblm, :);
PutData_ = PutData(PutData.date == date_prblm, :);

CallData_ = CallData_(CallData_.OpPrice>1e-4, :);
PutData_ = PutData_(PutData_.OpPrice>1e-4, :);
%
[date_C, ~] = unique([CallData_.date, CallData_.exdate], 'rows');

for i = 1 : size(date_C, 1)
    idx_C = ismember([CallData_.date, CallData_.exdate], date_C(i, :), 'rows');
%     figure; plot(CallData_.strike(idx_C), CallData_.IV_extrap(idx_C));
%     title('C, K vs IV');
    figure; plot(CallData_.strike(idx_C), CallData_.OpPrice(idx_C), '-*'); grid on;
    title('C, K vs OpPrice');
    
    idx_P = ismember([PutData_.date, PutData_.exdate], [date_C(i, :)], 'rows');
%     figure; plot(PutData_.strike(idx_P), PutData_.IV_extrap(idx_P));
%     title('P, K vs IV');
    figure; plot(PutData_.strike(idx_P), PutData_.OpPrice(idx_P), '-*'); grid on;
    title('P, K vs OpPrice');
end


%%
rmpath(sprintf('%s\\main_functions', homeDirectory));
rmpath(sprintf('%s\\test', homeDirectory));
rmpath(homeDirectory);