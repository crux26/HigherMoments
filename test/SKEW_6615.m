%% SKEW(6615).isreal()==-1:
% dates_(6615)==733123, exdate_(6615)==733124
% 22-Mar-2007, 23-Mar-2007, respectively.

idxCplx = zeros(length(SKEW),1);
for i=1:length(SKEW)
    idxCplx(i) = ~isreal(SKEW(i));
end
idxCplx = find(idxCplx==1); % returns 6615.

%%
[SKEW, KURT, T_mmtPrice] = unit_test_main_replicating(6615);

%% Above corresponds to CallData_extrap(6614001,:)

blsimpv(1.4345e+3, 478.18, 0.0492-0.0196, 0.004, 956.3420)
blsprice(1.4345e+3, 478.18, 0.0492-0.0196, 0.004, 1)