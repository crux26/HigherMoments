function [C_BSIVInterp,Kc_interp, IV_BS0_interp] = C_BSIVInterpFun(S,Kc,r,T,C, IV_C,q,StepSize, Multiplier)
% Bigger StepSize extends the left-most K further, in the unit of 1.
% if too big, IV curvature's sign can change. (ex: StepSize=3, j==608 for Put)

StepSize = min(StepSize, length(Kc)-1);
Kc_interp = [Kc(1:end-1); (Kc(end):1:Kc(end)+Multiplier*(Kc(end)-Kc(end-StepSize)))']; 
Kc_interp = unique(Kc_interp);                                                                            
Kc_interp = Kc_interp(Kc_interp>0); % sanity check

%% BSIV
IV_BS0 = zeros(length(Kc),1);
Tol=1e-4;
for i=1:length(Kc)
    IV_BS0(i) = NewtonRaphson_call(S, Kc(i), r, T, C(i), IV_C(i), Tol, q);
end

%% extrap OTM part - "right" part
m = length(Kc);
IV_BS0_interp = zeros(length(Kc_interp),1);
IV_BS0_interp(1:m) = IV_BS0;

tmpIdx=find(Kc_interp==max(Kc));

% Now it's less overestimated --> not result in sufficiently small dC, dP
method='pchip';
for i=m+1:length(Kc_interp)
    if any(Kc_interp(i-4:i-1)==Kc_interp(tmpIdx))
        IV_BS0_interp(i) = interp1(Kc_interp(i-4:i-1), IV_BS0_interp(i-4:i-1), Kc_interp(i), method, 'extrap');
    else
        IV_BS0_interp(i) = interp1([Kc_interp(tmpIdx);Kc_interp(i-4:i-1)], ...
            [IV_BS0_interp(tmpIdx);IV_BS0_interp(i-4:i-1)], Kc_interp(i), method, 'extrap');
    end
end

index_pos = find(IV_BS0_interp>0);
IV_BS0_interp = IV_BS0_interp(index_pos);   % IV extrap can go negative.
Kc_interp = Kc_interp(index_pos);           % Discard Kc whose IV is negative.

[C_BSIVInterp,~]=blsprice(S,Kc_interp,r,T,IV_BS0_interp); % Do NOT use myblscall: arg is a vector in this case.
