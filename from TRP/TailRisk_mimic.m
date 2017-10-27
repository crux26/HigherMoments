function [VaR, ES, UP, EUP, TRP, ETRP]=TailRisk_mimic(S, C, Kc, P, Kp, r, T, alpha, IV_C, IV_P, q)
% C, P: $ price (NOT IV - to implement it in model-free sense)
% Kc, Kp: strike price vector (matrix NOT supported yet)
% If only one fixed maturity is used, this is fine. 
% Usually selects 1st month maturity, so seems OK.
if nargin < 11
    q=0;
end
% alpha: significance level.
if alpha < 1
    warning('Note that alpha will be divided by 100. Put the integer in.');
end
alpha = alpha/100;

%% drop too deep-OTM values --> yields extreme outliers

[C, Kc, IV_C] = dropEnd_OTMC(C,Kc,IV_C, S, r, T, q);
[P, Kp, IV_P] = dropEnd_OTMP(P,Kp,IV_P, S, r, T, q);

%% Interpolation/Extrapolation part. 'cubic' on BSIV is the best, so will be used. BSIV will be converted into price via blsprice then.

diffStepSize=1;
dP = diff_central(P, Kp, diffStepSize);
forward = S * exp(r*T);
dP_OTM = dP(Kp<forward);	% Choose OTMPs' first differences only

%--------
dC = diff_central(C, Kc, diffStepSize);
dC_OTM = dC(Kc>forward);      % Choose OTMCs' first differences only

if ~any(-dC_OTM < alpha*exp(-r*T))
    StepSize=3;
    Multiplier=6;
    [~,Kc,IV_C] = C_BSIVInterpFun(S,Kc,r,T,C,IV_C,q,StepSize,Multiplier, alpha);
end

if ~any(dP_OTM < alpha*exp(-r*T))
    StepSize=3;
    Multiplier=6;
    [~,Kp,IV_P] = P_BSIVInterpFun(S,Kp,r,T,P,IV_P,q,StepSize,Multiplier, alpha);
end

index_OTMC = find(Kc>forward);
index_ITMC = find(Kc<=forward);
index_OTMP = find(Kp<forward);
index_ITMP = find(Kp>=forward);

IV_C(index_ITMC) = interp1(Kp(index_OTMP), IV_P(index_OTMP), Kc(index_ITMC), 'nearest', 'extrap');
IV_P(index_ITMP) = interp1(Kc(index_OTMC), IV_C(index_OTMC), Kp(index_ITMP), 'nearest', 'extrap');

[C,~]=blsprice(S,Kc,r,T,IV_C,q);
[~,P]=blsprice(S,Kp,r,T,IV_P,q);

%% Sorting in ascending order
% Each column will be sorted separately (w.r.t. K).
% Sorting all columns altogether is sortrows().
[Kc, index] = sort(Kc);
C = C(index,1);
[Kp, index] = sort(Kp);
P = P(index,1);

%% Put: DQ, VaR

diffStepSize=1;
dP = diff_central(P, Kp, diffStepSize);

forward = S * exp(r*T);
index_OTMP = find(Kp<forward);  % OTMP indices
                                % Kp sorted beforehand, so index_OTMP will contain 
                                % consecutive numbers only (no "jump" in the index_OTMP)

% P_OTM = P(index_OTMP,1);      % Choose OTM puts only
Kp_OTM = Kp(index_OTMP,1);    % Choose OTM puts' strikes only
dP_OTM = dP(index_OTMP,1);    % Choose OTM puts' first differences only

% no "q" below: Breeden-Litzenberger deals with "r" only.
% Note that in the Breeden-Litzenberger formula, it discounts "cashflow", so the discount rate should be "r", NOT "r-q".

% ----------------- Kernel Smoothing Regression on P-----------------
% P_ksr = ksr(Kp_OTM,P_OTM, max(Kp_OTM)-min(Kp_OTM)+1);
% P_ksr = interp1(P_ksr.x, P_ksr.f, Kp_OTM);
% dP_OTM = diff_central(P_ksr, Kp_OTM, diffStepSize);
% -------------------------------------------------------------------

% -----------------Kernel Smoothing Rgression on dP-----------------
% dP_OTM = ksr(Kp_OTM, dP_OTM, max(Kp_OTM)-min(Kp_OTM)+1);
% dP_OTM = interp1(dP_OTM.x, dP_OTM.f, Kp_OTM, 'pchip', 'extrap');
% ------------------------------------------------------------------
[DQ, VaR] = index_P_tail(dP_OTM, Kp_OTM, alpha, S, r, T);

%% ES
% ES = ExpectedShortfall(P_OTM, Kp_OTM, S, T, alpha, DQ, VaR, IV_P(index_OTMP), r, q);
% Use all moneyness in case of Kp_OTM_star>>Kp_OTM everywhere.
% There's still chance that Kp_OTM_star < Kp_ITM.
ES = ExpectedShortfall(P, Kp, S, T, alpha, DQ, VaR, IV_P, r, q);

%% Call: UQ, UP (analogue of VaR)

diffStepSize=1;
dC = diff_central(C, Kc, diffStepSize);

forward = S*exp(r*T);
index_OTMC = find(Kc>forward);  % OTMC indices
                                % Kc sorted beforehand, so index_OTMC will contain 
                                % consecutive numbers only (no "jump" in the index_OTMC)

% C_OTM = C(index_OTMC,1);        % Choose OTMC only
Kc_OTM = Kc(index_OTMC,1);      % Choose OTMCs' first differences only
dC_OTM = dC(index_OTMC,1);      % Choose OTMCs' strikes only

% -----------------Kernel Smoothing Regression on C-----------------
% C_ksr = ksr(Kc_OTM, C_OTM, max(Kc_OTM)-min(Kc_OTM)+1);
% C_ksr = interp1(C_ksr.x, C_ksr.f, Kc_OTM);
% dC_OTM = diff_central(C_ksr, Kc_OTM, diffStepSize);
% -------------------------------------------------------------------

% -----------------Kernel Smoothing Regression on dC-----------------
% dC_OTM_ = ksr(Kc_OTM, dC_OTM, max(Kc_OTM)-min(Kc_OTM)+1);
% dC_OTM_ = interp1(dC_OTM_.x, dC_OTM_.f, Kc_OTM, 'pchip', 'extrap');
% -------------------------------------------------------------------
[UQ, UP] = index_C_tail(dC_OTM, Kc_OTM, alpha, S, r, T);

%% EUP

% EUP = ExpectedUpsidePotential(C_OTM, Kc_OTM, S, T, alpha, UQ, UP, IV_C(index_OTMC), r, q);
% Use all moneyness in case of Kc_OTM_star<<Kc_OTM everywhere.
% There's still chance that Kc_OTM_star > Kc_ITM.
EUP = ExpectedUpsidePotential(C, Kc, S, T, alpha, UQ, UP, IV_C, r, q);

%%
TRP = UP - VaR;
ETRP = EUP - ES;