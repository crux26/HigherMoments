function [C, Kc, IV_C] = dropEnd_OTMC(C, Kc, IV_C, S, r, T, q)
tmpMult = 1.5;

%% drop deepest-OTM
% if Kc(end) >>> Kc(end-1), crazy extrapolation results occur.
while length(C)>2 && (Kc(end)>Kc(end-1) + tmpMult*(Kc(end-1)-Kc(end-2)))
    C = C(1:end-1); Kc = Kc(1:end-1); IV_C = IV_C(1:end-1);
end

%% extrap - interp1('nearest') for the deep-OTM
% This will change only a few deepest-OTMCs.
% Even if IV_C does not decrease, C will anyway (due to larger Kc).
% if pchip, spline used then there's a chance of explosion.
m = length(Kc);
i=m;
while length(C)>2 && (C(i)>=C(i-1))
    IV_C_ = interp1(Kc(i-4:i-1), IV_C(i-4:i-1), Kc(i), 'nearest', 'extrap'); % pchip,spline yields <0 for some cases.
    if IV_C_ <= IV_C(i-1) && IV_C_ < IV_C(i)
        IV_C(i) = IV_C_;
        C(i) = myblscall(S, Kc(i), r, T, IV_C(i), q);
        i=i+1;
        if i>m
            break;
        end
    else
        i=i-1;
    end
end