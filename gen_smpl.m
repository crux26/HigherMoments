%% generate sample data-set
clear;clc;
addpath('D:\Dropbox\GitHub\HigherMoments\data\codes');
load('OpData_BSIV_1st.mat');
rmpath('D:\Dropbox\GitHub\HigherMoments\data\codes');

maxdate = max(CallData(:,1));
idx = find(CallData(:,1)==maxdate);
CallData = CallData(idx,:);
CallIV = CallIV(idx,:);

idx_ = find(PutData(:,1)==maxdate);
PutData = PutData(idx_,:);
PutIV = PutIV(idx_,:);
save('smpl_set.mat', 'CallData', 'CallIV', 'PutData', 'PutIV');