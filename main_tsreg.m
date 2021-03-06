%% This is WRONG: note that Chang, Christoffersen, Jacobs (2013)'s iSKEW, iKURT is monthly series.
%% var(my SKEW, KURT) >>> var(paper's SKEW, KURT). Must fix it.


%% main_replicating() -> main_tsreg().
%% Ultimate goal: export this data to SAS.
%% Checking Done! (2017.11.16) Works perfectly fine. Also checked with EViews.
clear; clc;
isDorm = 0;
if isDorm == true
    drive = 'E:';
else
    drive = 'E:';
end
homeDirectory = sprintf('%s\\Dropbox\\GitHub\\HigherMoments', drive);
genData_path = sprintf('%s\\data\\gen_data', homeDirectory);
addpath(sprintf('%s\\main_functions', homeDirectory));
OptionsData_genData_path = sprintf('%s\\Dropbox\\GitHub\\OptionsData\\data\\gen_data', drive);

%%
load(sprintf('%s\\rawData_VIX_dly.mat', OptionsData_genData_path), 'T_VIX_dly');
T_VIX_dly = T_VIX_dly( ~isnan(T_VIX_dly.vix), :);   % T_VIX_dly.vix has some (2, between 1996-2015) NaN values.
VOL_diff = diff(T_VIX_dly.vix);
T_VIX_dly.VOL_diff = [NaN; VOL_diff];

load(sprintf('%s\\SKEWKURT.mat', homeDirectory), 'T_mmtPrice', 'T_mmt_interp');

load(sprintf('%s\\raw_factors_dly.mat', OptionsData_genData_path), 'T_factors_dly');

date_intersection = intersect( intersect(T_VIX_dly.caldt, T_mmt_interp.date_), T_factors_dly.date );
T_VIX_dly = T_VIX_dly( ismember(T_VIX_dly.caldt,date_intersection), :);
T_mmt_interp = T_mmt_interp( ismember(T_mmt_interp.date_, date_intersection), :);
T_factors_dly = T_factors_dly( ismember(T_factors_dly.date, date_intersection), :);

%% This may need to be fixed; by doing so 1 observation for VOL, SKEW, KURT are lost.
% VOL = T_VIX_dly.vix;
SKEW = T_mmt_interp.SKEW;   % SKEW_diff = diff(SKEW);
KURT = T_mmt_interp.KURT;   % KURT_diff = diff(KURT);

%% Below is to check it with EViews: to make sure that the slight differences are not due to the program.
% date = datestr(date_);
% T = table(date, VOL, SKEW, KURT);
% writetable(T, 'SKEWKURT.txt', 'Delimiter', ' ');

%% ARMA(1,1) for SKEW, KURT to remove autocorr.
% Compare it with EViews result: More or less the same.
[SKEW_coeff, SKEW_SE, SKEW_t, SKEW_res] = myARMA11(SKEW);
[KURT_coeff, KURT_SE, KURT_t, KURT_res ] = myARMA11(KURT);
% SKEW_res = SKEW_res(2:end); % Discard t0 value: As it is differenced series.
% KURT_res = KURT_res(2:end); % Discard t0 value: As it is differenced series.

%% Paper scaled SKEW, KURT by 0.01.
% VOL_diff = diff(VOL);
VOL_diff = T_VIX_dly.VOL_diff;
SKEW_diff = SKEW_res * 0.01;
KURT_diff = KURT_res * 0.01;
% disp(corrcoef([SKEW_diff, KURT_diff, VOL_diff]));

%% Separating the effect from skewness on kurtosis from pure kurtosis dynamics
% KURT_diff: residuals of KURT_diff reg. w.r.t. SKEW_diff.
[~,~,KURT_diff] = regress(KURT_diff, [ones(length(SKEW_diff),1), SKEW_diff]);   % corr(SKEW_diff, KURT_diff)==0 now.

T_mmtFactors_dly = table(T_factors_dly.date, VOL_diff, SKEW_diff, KURT_diff, ...
    'VariableNames', {'date', 'iVOL', 'iSKEW', 'iKURT'});

save(sprintf('%s\\T_mmtFactors_dly', homeDirectory), 'T_mmtFactors_dly');

%% Convert datenum 2 datestr as it will be read from SAS.
date = datestr(T_factors_dly.date, 'ddmmmyyyy');
T_mmtFactors_dly_ = table(date, VOL_diff, SKEW_diff, KURT_diff, ...
    'VariableNames', {'date', 'iVOL', 'iSKEW', 'iKURT'});
writetable(T_mmtFactors_dly_, sprintf('%s\\T_mmtFactors_dly.csv', genData_path));

rmpath(sprintf('%s\\main_functions', homeDirectory));
