function ES = ExpectedShortfall(P_OTM, Kp_OTM, S, T, alpha, DQ, VaR, P_OTM_IV, r, q)
% Only OTMP will be used, in general.

%% Pre-processing
Kp_OTM_star = S * exp(-DQ);

index_Kp = find(Kp_OTM < Kp_OTM_star);

if ~isempty(index_Kp)
    if length(index_Kp) ~= length(Kp_OTM)
        index_Kp_last = index_Kp(end);
    else
        index_Kp_last = length(Kp_OTM)-1; % index_Kp(end)-1 can be used as well.
        warning('Kp_OTM << Kp_OTM_star everywhere.');
    end
else
    index_Kp_last = 1;
    warning('Kp_OTM_star << Kp_OTM everywhere.');
end
        
%%

% Note that Kp_OTM_star is NOT market strike, so lie b/w [Kp_OTM(index_K_last), Kp_OTM(index_K_last+1)]
if ~isempty(index_Kp) && (length(index_Kp) ~= length(Kp_OTM))
    % ideal case
    P_OTM_star = P_OTM(index_Kp_last) + (Kp_OTM_star - Kp_OTM(index_Kp_last)) * ...
        (P_OTM(index_Kp_last+1) - P_OTM(index_Kp_last)) / (Kp_OTM(index_Kp_last+1) - Kp_OTM(index_Kp_last)) ;
    % Above is f(x) = x0 + (x-x0) * (y1-y0)/(x1-x0) where x in [x0, x1]
    
elseif ~isempty(index_Kp) && (length(index_Kp) == length(Kp_OTM))
    % Kp_OTM_star >> Kp_OTM everywhere --> need "right" extrap
    % Note that P_OTM_IV is decreasing in Kp_OTM.
    Kp_OTM_interp = unique([Kp_OTM; (max(Kp_OTM):1:Kp_OTM_star)']); % "right" interp of Kp up to Kp_OTM_star
    
    %---------------------------
    m=length(Kp_OTM);
    m_=length(Kp_OTM_interp);
    P_OTM_IV_interp = zeros(m_,1);
    P_OTM_IV_interp(1:m) = P_OTM_IV;
    
    for i=m+1:m_
        P_OTM_IV_interp(i) = interp1(Kp_OTM_interp(i-4:i-1), P_OTM_IV_interp(i-4:i-1), Kp_OTM_interp(i), 'pchip', 'extrap');
    end
    
    %---------------------------
%     P_OTM_IV_interp = interp1(Kp_OTM, P_OTM_IV, Kp_OTM_interp, 'pchip', 'extrap');  % 'pchip': IV_P>0 more often than 'spline'
%     incIndex = find(diff(P_OTM_IV_interp)>0); % find increasing IV_P, which is problematic
%     incIndex = incIndex( incIndex>length(Kp_OTM) );
%         
%     posIndex = find(P_OTM_IV_interp<0, 1, 'first');
%     if ~isempty(incIndex) && ~isempty(posIndex)
%         minposIndex = min(min(incIndex), posIndex);
%     elseif ~isempty(incIndex) && isempty(posIndex)
%         minposIndex = min(incIndex);
%     elseif isempty(incIndex) && ~isempty(posIndex)
%         minposIndex = posIndex;
%     else
%         error('both incIndex, posIndex empty.');
%     end
%     
%     P_OTM_IV_interp(minposIndex:end) = P_OTM_IV_interp(minposIndex-1);
    
    %---------------------------
    P_OTM_IV_star = P_OTM_IV_interp(end);
    P_OTM_star = myblsput(S, Kp_OTM_star, r, T, P_OTM_IV_star, q);
    
elseif isempty(index_Kp)
    % Kp_OTM_star << Kp_OTM everywhere --> need "left" extrap
    Kp_OTM_interp = unique( [(Kp_OTM_star:1:min(Kp_OTM))'; Kp_OTM]);    % "left" interp of Kp down to Kp_OTM_star
    
    %-------------------------
    m=length(Kp_OTM);
    m_=length(Kp_OTM_interp);
    P_OTM_IV_interp = zeros(m_,1);
    P_OTM_IV_interp(m_-m+1:m_) = P_OTM_IV;
    
    for i=m_-m:-1:1
        P_OTM_IV_interp(i) = interp1(Kp_OTM_interp(i+4:-1:i+1), P_OTM_IV_interp(i+4:-1:i+1), Kp_OTM_interp(i), 'pchip', 'extrap');
    end
    %-------------------------        
%     P_OTM_IV_interp = interp1(Kp_OTM, P_OTM_IV, Kp_OTM_interp, 'spline', 'extrap');
    %-------------------------
    P_OTM_IV_star = P_OTM_IV_interp(1);
    P_OTM_star = myblsput(S, Kp_OTM_star, r, T, P_OTM_IV_star, q);
end


%% Integration part
% Note that the left end of market strike is NOT 0, but "K0" (in the original code, "k0")
% min(C), min(P) == 0.025 --> <1e-3 results in overflow, letting K0 << 0.
% if (P_OTM(2) - P_OTM(1))/(Kp_OTM(2)-Kp_OTM(1)) > 0 % P_OTM(2)==P_OTM(1) can happen
if (P_OTM(2) - P_OTM(1))/(Kp_OTM(2)-Kp_OTM(1)) > 1e-3 % P_OTM(2)==P_OTM(1) can happen    
% Note that the "Slope" below is positive, so K0 < Kp_OTM(1).
    K0=Kp_OTM(1) - (P_OTM(1)-0)/(P_OTM(2)-P_OTM(1)) * (Kp_OTM(2)-Kp_OTM(1))  ;
else
    K0=Kp_OTM(1) - (Kp_OTM(2)-Kp_OTM(1));
end

K0 = max(K0,0); % can be negative if (P_OTM(2)-P_OTM(1)<eps).

% K0=0;   % Note that K0 < Kp_OTM(index_K_first)
%trapz(X,Y)
if isempty(index_Kp) % K0 < Kp_OTM << Kp_OTM_star
    tmp_int = trapz([K0; Kp_OTM; Kp_OTM_star], ...
        [0; P_OTM ./ Kp_OTM.^2; P_OTM_star/Kp_OTM_star.^2]); 

elseif ~isempty(index_Kp) && (length(index_Kp) == length(Kp_OTM) )
    tmp_int = trapz([K0; Kp_OTM_star], ...
        [0; P_OTM_star/Kp_OTM_star.^2]); 
    
else
    % Kp_OTM_star << K0, and P(K0)==0
    tmp_int = 0;
end
    % f(K0)=0, f(Kp_OTM(index_Kp))=P_OTM(index_Kp)./Kp_OTM(index_Kp).^2,
    % f(Kp_OTM_star)=P_OTM_star/Kp_OTM_star.^2
    % Note that f(K0)=0 is guaranteed by definition above.

clear K0;                                 
% Cannot use below because the closed-form expression of P w.r.t. K is not known
% integral() uses quadgk: Quadrature, "Gauss-Kronrod"
% tmp_int = integral(@(x) P_OTM.^2 ./ Kp_OTM.^2, 0, Kp_OTM_star, 'AbsTol', 1e-10, 'RelTol', 1e-6);

%% Print the result
ES = VaR + (P_OTM_star/Kp_OTM_star + tmp_int) / (alpha * T);

if isnan(ES)
    warning('ES is NaN.');
end