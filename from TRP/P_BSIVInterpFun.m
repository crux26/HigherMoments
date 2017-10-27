function [P_BSIVInterp, Kp_interp, IV_BS0_interp] = P_BSIVInterpFun(S,Kp,r,T,P,IV_P,q,StepSize, Multiplier)
% Bigger StepSize extends the left-most K further, in the unit of 1.
% if too big, IV curvature's sign can change. (ex: StepSize=3, j==608 for Put)

StepSize=min(StepSize,length(Kp)-1);
Kp_interp = [(Kp(1)- Multiplier*(Kp(1+StepSize)-Kp(1)) : 1 : Kp(1))' ; Kp(2:end)];
Kp_interp=unique(Kp_interp);
Kp_interp = Kp_interp(Kp_interp>0); % Kp_interp <= 0 can take place, due to crazy data

%% BSIV 
IV_BS0 = zeros(length(Kp),1);
Tol=1e-4;
for i=1:length(Kp)
    IV_BS0(i) = NewtonRaphson_put(S, Kp(i), r, T, P(i), IV_P(i), Tol, q);
end

%% extrap OTM part - "left" part
m=length(Kp);
m_=length(Kp_interp);
IV_BS0_interp = zeros(m_,1);
IV_BS0_interp(m_-m+1:m_) = IV_BS0;

tmpIdx=find(Kp_interp==min(Kp));

method='pchip';
for i=m_-m:-1:1
    if any(Kp_interp(i+4:-1:i+1)==Kp_interp(tmpIdx))
        IV_BS0_interp(i) = interp1(Kp_interp(i+4:-1:i+1), IV_BS0_interp(i+4:-1:i+1), Kp_interp(i), method, 'extrap');    
    else
        IV_BS0_interp(i) = interp1([Kp_interp(tmpIdx); Kp_interp(i+4:-1:i+1)], ...
            [IV_BS0_interp(tmpIdx); IV_BS0_interp(i+4:-1:i+1)], Kp_interp(i), method, 'extrap');
    % pchip here results in decreasing IV_BS0_interp for some cases.
    end
end

index_pos = find(IV_BS0_interp>0);
IV_BS0_interp = IV_BS0_interp(index_pos);   % IV extrap can go negative.
Kp_interp = Kp_interp(index_pos);           % Discard Kp whose IV is negative.

[~,P_BSIVInterp]=blsprice(S,Kp_interp,r,T,IV_BS0_interp); % Do NOT use myblsput: arg is a vector in this case.
