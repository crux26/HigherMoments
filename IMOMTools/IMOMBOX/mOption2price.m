function out = mOption2price(Kc, C, Kp, P, S0, df, MomentRank)
% MOPTION2PRICE compute prices of moment contracts from calls and puts
% 
% price -> moment
%
% MomentRank: the first N number of moments
% df: Discount Factor
% 
% M = MOPTION2PRICE(Kc,C,Kp,P)
% returns price approximations of the first four moment contracts with
% values M = E( df * log(ST/S0)^n ). The contracts' maturity matches the
% options' maturity. The values of the spot asset price S0 and the factor
% for discounting, DF, are approximated along the way.
% 
% M = MOPTION2PRICE(Kc,C,Kp,P,S0)
% returns price approximations of the first four moment contracts where
% only the discount factor DF is approximated along the way.  
% 
% M = MOPTION2PRICE(Kc,C,Kp,P,S0,DF)
% returns price approximations of the first four moment contracts.
% 
% M = MOPTION2PRICE(Kc,C,Kp,P,S0,df,MomentRank)
% returns price approximations of (moment==MomentRank) contracts.
% 
% Author:     matthias.held@web.de
% Date:       2014-07-25

%     if ~exist('MomentRank')
if ~exist('MomentRank', 'var')
    MomentRank=1:4;
end
%     if ~exist('df') | ~exist('S0')
if ~exist('df', 'var') || ~exist('S0', 'var')   % if both exists
    [~,idxC,idxP]   = intersect(Kc,Kp); % Kc(idxC)==Kp(idxP)==intersect(Kc,Kp)
    if length([idxC idxP])>2    % intersects more than 1 strike

        % Put-call parity --> why does it show up here?
        YY              = C(idxC)-P(idxP);
        XX              = [ones(length(YY),1) Kc(idxC)];
        b1              = (XX'*XX)\(XX'*YY);
        df              = -b1(2);
        S0              = b1(1);
    else    % no intersection in strikes
        error('Plese supply discount factor and/or spot asset price.')
    end
end

idx_OTMP        = find(Kp<S0);
Kp              = Kp(idx_OTMP);
P               = P(idx_OTMP);
idx_OTMC        = find(Kc>S0);
Kc              = Kc(idx_OTMC);
C               = C(idx_OTMC);

if length(idx_OTMP)>1
    dKp=[Kp(2)-Kp(1); diff(Kp)];
else
    dKp=0;
end

if length(idx_OTMC)>1
    dKc=[Kc(2)-Kc(1); diff(Kc)];
else
    dKc=0;
end

out = zeros(length(MomentRank), 1); % my code. Erase the line if error.
for k = 1:length(MomentRank)
    out(k)          = sum(momweight(Kp,S0,MomentRank(k)).*P.*dKp) ...
                     +sum(momweight(Kc,S0,MomentRank(k)).*C.*dKc);
    if MomentRank(k) == 1
        out(k)          = out(k) + 1 - df;
    end
end
