%% jj=4949 is problematic. Try main_replicating() with jj=4949.
% dates_(4949)==733178, exdate_(4949)==733209.
plot(C_OTM); xlabel('Kc OTM'); ylabel('C OTM'); title(sprintf('jj=4949. Problematic value'));

% Do not plot Kc_OTM as xaxis; Kc_OTM changes too much w.r.t. C_OTM, so
% cannot see the difference with bare eyes.

%%
idx_C = find(CallData_extrap.date==733178 & CallData_extrap.exdate==733209);

idx_C = find(CallData(:,1)==733178 & CallData(:,2)==733209);