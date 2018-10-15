function moment = OpPrice2momPrice(S0, C, Kc, P, Kp, r, T, IV_C, IV_P, q, MomentRank)
% S0, r, T, q: scalar
% C,Kc,P,Kp: vector
% MomentRank: vector
DF = exp(-r*T);

if ~exist('MomentRank', 'var')
    MomentRank = 1:4;
end

% In BKM (2003), ITM defined as moneyness, NOT forward moneyness.
% Anyway, either will have no big difference, as TTM is small.
idx_OTMC = find(S0 < Kc); 
idx_OTMP = find(Kp < S0);

Kc_OTM = Kc(idx_OTMC);
Kp_OTM = Kp(idx_OTMP); 

C_OTM = C(idx_OTMC);
P_OTM = P(idx_OTMP);

% ATMs have higher $ prices, so can result in bigger errors.
if length(Kp_OTM) <=1 || length(Kc_OTM) <=1
    error('Only 1 data for OTMC or OTMP. Check the data again.');
end

% dKp = [Kp(2)-Kp(1); diff(Kp)];          % 2 entries of (Kp(2)-Kp(1)): OTM part
% dKc = [diff(Kc); Kc(end)-Kc(end-1)];    % 2 entries of (Kc(end)-Kc(end-1)): OTM part
% 
% dKc_OTM = dKc(idx_OTMC);
% dKp_OTM = dKp(idx_OTMP);

moment = zeros(1, length(MomentRank));  % row vector, as its time series will be stacked horizontally
for i = 1 : length(MomentRank)
%     moment(i) = sum(momweight(Kp_OTM, S0, MomentRank(i)) .* P_OTM .* dKp_OTM) + ...
%         sum(momweight(Kc_OTM, S0, MomentRank(i)) .* C_OTM .* dKc_OTM);
    
    moment(i) = trapz(Kp_OTM, momweight(Kp_OTM, S0, MomentRank(i)) .* P_OTM) + ...
        trapz(Kc_OTM, momweight(Kc_OTM, S0, MomentRank(i)) .* C_OTM);
    
    if MomentRank(i) == 1
        moment(i) = moment(i) + 1 - DF;
    end
end
