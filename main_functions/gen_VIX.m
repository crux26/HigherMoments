%% THIS CODE SHOULD BE RE-CHECKED. DON'T SEE THE PURPOSE OF THIS CODE.

%% VIX generation to be used as a second moment
%% import data
clear;clc;
isDorm = false;

if isDorm == true
    drive = 'F:';
else
    drive = 'D:';
end
homeDirectory = sprintf('%s\\Dropbox\\GitHub\\HigherMoments', drive);
gen_data_path = sprintf('%s\\data\gen_data', homeDirectory);
addpath('%s\\main_functions', homeDirectory);

% load('OpData_BSIV_1st.mat', 'CallData', 'PutData', 'CallIV', 'PutIV', 'symbol_C', 'symbol_P');
load(sprintf('%s\\OpData_BSIV_2nd.mat',gen_data_path), ...
 'CallData', 'PutData', 'CallIV', 'PutIV', 'symbol_C', 'symbol_P');
load('rawData_VIX.mat', 'caldt', 'vix');

%% Filling in NaN VIX. (missing(VIX).date()=[19970131, 19971126] during 01Jan1996, 31Dec2015.
% Below is enough as missing dates are not successive.
idx_vixMissing = find(isnan(vix));
vix(idx_vixMissing) = 0.5*( vix(idx_vixMissing-1) + vix(idx_vixMissing+1) );


%% Match VIX data with CallData & PutData
vix_C = zeros(size(CallData,1),1);
% Below takes 0.2s (LAB PC)
tic
for i=1:size(caldt,1)
    idx = find(caldt(i) == CallData(:,1));
    vix_C(idx) = vix(i);
end
toc

vix_P = zeros(size(PutData,1),1);
% Below takes 0.2s (LAB PC)
tic
for i=1:size(caldt,1)
    idx = find(caldt(i) == PutData(:,1));
    vix_P(idx) = vix(i);
end
toc

%% Vol_True replaced by IV_BS. Note that this IV is dividend-adjusted.
CallData(:,6) = CallIV;
PutData(:,6) = PutIV;
clear CallIV PutIV CallVolDev PutVolDev;

% date=30Jun99.datenum() = 730301: Problematic date. Best to exclude it.
idx_C = find(CallData(:,1)~=730301);
CallData = CallData(idx_C , :);
vix_C = vix_C(idx_C);

idx_P = find(PutData(:,1)~=730301);
PutData = PutData(idx_P, :);
vix_P = vix_P(idx_P);