%% T_mmt_interp(2861,:). date==16May2007, SKEW=2.3487(>0), KURT=41.8122
% date==733178
%
% This is due to OpData_dly_2nd_BSIV_Trim_extrap.
% CallData(101475, :), PutData(148249,:).
% After trimming, CallData(95247,:), PutData(139565,:).
idx_C = find(CallData(:,1)==733178);
idx_P = find(PutData(:,1)==733178);