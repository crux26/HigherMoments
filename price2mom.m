function moment = price2mom(S0, C, Kc, P, Kp, r, T, IV_C, IV_P, q, MomentRank)
% S0: scalar
% C,Kc,P,Kp: vector
% MomentRank: vector
df = exp(-r*T);

if ~exist('MomentRank', 'var')
    MomentRank = 1:4;
end


forward = S0*exp(r*T);
idx_OTMC = find(forward < Kc); 
idx_OTMP = find(Kp < forward);
% idx_ITMC = find(forward >= Kc);
% idx_ITMP = find(Kp >= forward);

Kc_OTM = Kc(idx_OTMC);
Kp_OTM = Kp(idx_OTMP); 

C_OTM = C(idx_OTMC);
P_OTM = P(idx_OTMP);

% ATMs have higher $ prices, so can result in bigger errors.
if length(Kp_OTM) <=1 || length(Kc_OTM) <=1
    error('Only 1 data for OTMC or OTMP. Check the data again.');
end

dKp = [Kp(2)-Kp(1); diff(Kp)];          % 2 entries of (Kp(2)-Kp(1)): OTM part
dKc = [diff(Kc); Kc(end)-Kc(end-1)];    % 2 entries of (Kc(end)-Kc(end-1)): OTM part


dKc_OTM = dKc(idx_OTMC);
dKp_OTM = dKp(idx_OTMP);

moment = zeros(1, length(MomentRank));  % row vector, as its time series will be stacked horizontally
for i = 1 : length(MomentRank)
    moment(i) = sum(momweight(Kp_OTM, S0, MomentRank(i)).*P_OTM.*dKp_OTM) + ...
        sum(momweight(Kc_OTM, S0, MomentRank(i).*C_OTM.*dKc_OTM));
    
    if MomentRank(i) == 1
        moment(i) = moment(i) + 1 - df;
    end
end
