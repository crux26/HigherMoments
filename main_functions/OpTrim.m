function [C, Kc, P, Kp, IV_C, IV_P] = OpTrim(S, C, Kc, P, Kp, r, T, IV_C, IV_P, q)
if nargin < 10
    q = 0;
end


%% IV_ITMC <-- IV_OTMP, IV_ITMP <-- IV_OTMC
% By doing this procedure first, can prevent some NaN IVs from being dropped.
forward = S*exp(r*T);
index_OTMC = find(Kc>forward);
index_ITMC = find(Kc<=forward);
index_OTMP = find(Kp<forward);
index_ITMP = find(Kp>=forward);

IV_C(index_ITMC) = interp1(Kp(index_OTMP), IV_P(index_OTMP), Kc(index_ITMC), 'nearest', 'extrap');
IV_P(index_ITMP) = interp1(Kc(index_OTMC), IV_C(index_OTMC), Kp(index_ITMP), 'nearest', 'extrap');

[C,~]=blsprice(S,Kc,r,T,IV_C,q);
[~,P]=blsprice(S,Kp,r,T,IV_P,q);

%% drop too deep-OTM values --> yields extreme outliers

[C, Kc, IV_C] = dropEnd_OTMC(C,Kc,IV_C, S, r, T, q);
[P, Kp, IV_P] = dropEnd_OTMP(P,Kp,IV_P, S, r, T, q);

%% Interpolation/Extrapolation part: This may be not needed.
% % 'cubic' on BSIV is the best, so will be used. BSIV will be converted into price via blsprice then.
% forward = S * exp(r*T);     % forward moneyness for index options
% diffStepSize=1;
% dP = diff_central(P, Kp, diffStepSize);
% dP_OTM = dP(Kp<forward);	% Choose OTMPs' first differences only
% dC = diff_central(C, Kc, diffStepSize);
% dC_OTM = dC(Kc>forward);      % Choose OTMCs' first differences only
%-------------------------

StepSize=1; Multiplier=0; % No extrap in Kc, Kp. "Smoothing" only will take place.
[~,Kc,IV_C] = C_BSIVInterpFun(S,Kc,r,T,C,IV_C,q,StepSize,Multiplier);
[~,Kp,IV_P] = P_BSIVInterpFun(S,Kp,r,T,P,IV_P,q,StepSize,Multiplier);


% %% IV_ITMC <-- IV_OTMP, IV_ITMP <-- IV_OTMC
% forward = S*exp(r*T);
% index_OTMC = find(Kc>forward);
% index_ITMC = find(Kc<=forward);
% index_OTMP = find(Kp<forward);
% index_ITMP = find(Kp>=forward);
% 
% IV_C(index_ITMC) = interp1(Kp(index_OTMP), IV_P(index_OTMP), Kc(index_ITMC), 'nearest', 'extrap');
% IV_P(index_ITMP) = interp1(Kc(index_OTMC), IV_C(index_OTMC), Kp(index_ITMP), 'nearest', 'extrap');
% 
[C,~]=blsprice(S,Kc,r,T,IV_C,q);
[~,P]=blsprice(S,Kp,r,T,IV_P,q);