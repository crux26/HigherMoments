function [P, Kp, IV_P] = dropEnd_OTMP(P, Kp, IV_P, S, r, T, q)
tmpMult = 1.5;

%% drop deepest-OTM
while length(P)>2 && (Kp(1)<Kp(2) - tmpMult*(Kp(3)-Kp(2)))
	P = P(2:end); Kp = Kp(2:end); IV_P = IV_P(2:end);
end

%% extrap - alternative
% This will change only a few deepest-OTMPs.
% Even if IV_P does not increase, P will anyway (due to smaller Kp).
% if pchip, spline used then there's a chance of explosion.

i=1;
while length(P)>2 && (P(i)>=P(i+1))
    IV_P_ = interp1(Kp(i+1:i+4), IV_P(i+1:i+4), Kp(i), 'nearest', 'extrap');% pchip, spline can be <0 for some cases.
                                                                            % P will be near-0 anyway (even if IV_P>>0)
    if IV_P_ >= IV_P(i+1) && IV_P_ > IV_P(i)
        IV_P(i) = IV_P_;
        P(i) = myblsput(S, Kp(i), r, T, IV_P(i), q);
        i=i-1;
        if i==0
            break;
        end
    else
        i=i+1;
    end
end