function [C, Kc, P, Kp, IV_C, IV_P] = OpTrim_wrapper(S, C, Kc, P, Kp, r, T, IV_C, IV_P, q, trimflag, Smoothing_IVonly)
% "Smoothing
% trimflag==0: "OpTrim" used in TRP. Interp/extrap of IV -> OpPrice.
% trimflag==1: Kernel Smoothing Regression
% Smoothing_IVonly==1: 
if trimflag == 0        % "Smoothing" through interp/extrap.
    [C, Kc, P, Kp, IV_C, IV_P] = OpTrim(S, C, Kc, P, Kp, r, T, IV_C, IV_P, q);

elseif trimflag == 1    % "Smoothing" through Kernel Smoothing Regression
    bandwidth = 2;
    nPt = 100;    % calculates the regression in n points (default:100)
    r_IV_C = ksr(Kc, IV_C, bandwidth, nPt);
    r_IV_P = ksr(Kp, IV_P, bandwidth, nPt);
    IV_C = interp1(r_IV_C.x, r_IV_C.f, Kc, 'nearest', 'extrap');
    IV_P = interp1(r_IV_P.x, r_IV_P.f, Kp, 'nearest', 'extrap');
    
    if Smoothing_IVonly == 1
%         [C, ~] = blsprice(S, Kc, r, T, IV_C, q);
%         [~, P] = blsprice(S, Kp, r, T, IV_P, q);
        C = myblscall(S*ones(length(Kc),1),Kc,r,T,IV_C,q);
        P = myblsput(S*ones(length(Kp),1),Kp,r,T,IV_P,q);
    else
        r_C = ksr(Kc, C, bandwidth, nPt);
        r_P = ksr(Kp, P, bandwidth, nPt);
        C = interp1(r_C.x, r_C.f, Kc, 'nearest', 'extrap');
        P = interp1(r_P.x, r_P.f, Kp, 'nearest', 'extrap');
    end
end
