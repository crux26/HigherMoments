function EUP = ExpectedUpsidePotential(C_OTM, Kc_OTM, S, T, alpha, UQ, UP, C_OTM_IV, r, q)
% This is a call option analogue of ExpectedShortfall().
% Only OTMC will be used, in general.

%% Pre-processing
Kc_OTM_star = S * exp(UQ);
index_Kc = find(Kc_OTM > Kc_OTM_star);

if ~isempty(index_Kc)
    if length(index_Kc) ~= length(Kc_OTM)
        index_Kc_first = index_Kc(1);
    else
        index_Kc_first = 2; % should be 1 in fact, but as index_Kc_first-1 is used below,
                            % this is to supress the error.
        warning('Kc_OTM_star << Kc_OTM everywhere.');
    end
else
    index_Kc_first = length(Kc_OTM);
    warning('Kc_OTM << Kc_OTM_star everywhere.');
end

%%

% Note that Kc_OTM_star is NOT market strike, so lie b/w [Kc_OTM(index_K_last), Kc_OTM(index_K_last+1)]
if ~isempty(index_Kc) && (length(index_Kc) ~= length(Kc_OTM))
    % ideal case
    C_OTM_star = C_OTM(index_Kc_first) + (Kc_OTM_star - Kc_OTM(index_Kc_first)) * ...
        ( C_OTM(index_Kc_first-1) - C_OTM(index_Kc_first) ) / (Kc_OTM(index_Kc_first-1) - Kc_OTM(index_Kc_first)) ;

elseif ~isempty(index_Kc) && (length(index_Kc) == length(Kc_OTM))
    % Kc_OTM_star << Kc_OTM everywhere --> need "left" extrap
    % Note that C_OTM_IV is decreasing in Kc_OTM.
    Kc_OTM_interp = unique( [(Kc_OTM_star:1:min(Kc_OTM))'; Kc_OTM]);   % "left" interp of Kc down to Kc_OTM_star
    
    %------------------------------------------
    m=length(Kc_OTM);
    m_=length(Kc_OTM_interp);
    C_OTM_IV_interp=zeros(m_,1);
    C_OTM_IV_interp(m_-m+1:m_)=C_OTM_IV;
    
    for i=m_-m:-1:1
        C_OTM_IV_interp(i) = interp1(Kc_OTM_interp(i+4:-1:i+1), C_OTM_IV_interp(i+4:-1:i+1), Kc_OTM_interp(i), 'pchip', 'extrap');
    end
    
    %------------------------------------------
%     C_OTM_IV_interp = interp1(Kc_OTM, C_OTM_IV, Kc_OTM_interp, 'spline', 'extrap'); % 'spline': not restrict upper bound for IV
    %------------------------------------------
    C_OTM_IV_star = C_OTM_IV_interp(1);
    C_OTM_star = myblscall(S, Kc_OTM_star, r, T, C_OTM_IV_star, q);
    
elseif isempty(index_Kc)
    % Kc_OTM_star >> Kc_OTM everywhere --> need "right" extrap
    Kc_OTM_interp = unique( [Kc_OTM; (max(Kc_OTM):1:Kc_OTM_star)']);    % "right" interp of Kc up to Kc_OTM_star

    %------------------------------------------
	m=length(Kc_OTM);
    m_=length(Kc_OTM_interp);
    C_OTM_IV_interp=zeros(m_,1);
    C_OTM_IV_interp(1:m)=C_OTM_IV;

    for i=m+1:m_
        C_OTM_IV_interp(i) = interp1(Kc_OTM_interp(i-4:i-1), C_OTM_IV_interp(i-4:i-1), Kc_OTM_interp(i), 'pchip', 'extrap');
    end
    
    %------------------------------------------
%     C_OTM_IV_interp = interp1(Kc_OTM, C_OTM_IV, Kc_OTM_interp, 'pchip', 'extrap'); % 'pchip': IV_C>0 more often than 'spline'
%     incIndex = find(diff(C_OTM_IV_interp)>0); % find increasing IV_C, which is problematic
%     incIndex = incIndex(incIndex > length(Kc_OTM));
%     
%     posIndex = find(C_OTM_IV_interp<0, 1, 'first');
%     if ~isempty(incIndex) && ~isempty(posIndex)
%         minposIndex = min( min(incIndex), posIndex);
%     elseif ~isempty(incIndex) && isempty(posIndex)
%         minposIndex = min(incIndex);
%     elseif isempty(incIndex) && ~isempty(posIndex)
%         minposIndex = posIndex;
%     else
%         error('both incIndex, posIndex empty.');
%     end
%     
%     C_OTM_IV_interp(minposIndex:end) = C_OTM_IV_interp(minposIndex-1);
    %------------------------------------------
    
    C_OTM_IV_star = C_OTM_IV_interp(end);
    C_OTM_star = myblscall(S, Kc_OTM_star, r, T, C_OTM_IV_star, q);
end
% Above is f(x) = x0 + (x-x0) * (y1-y0)/(x1-x0) where x in [x0, x1]



%% Integration part
% min(C), min(P) == 0.025 --> <1e-3 results in overflow, letting Kinf << 0.
% if (C_OTM(end) - C_OTM(end-1))/(Kc_OTM(end)-Kc_OTM(end-1)) > 0 % C_OTM(end)==C_OTM(end-1) can happen
if (C_OTM(end) - C_OTM(end-1))/(Kc_OTM(end)-Kc_OTM(end-1)) > 1e-3 % C_OTM(end)==C_OTM(end-1) can happen    
% Note that the "Slope" below is negative, so Kinf > Kc_OTM(end).
    Kinf=Kc_OTM(end) - (C_OTM(end)-0)/(C_OTM(end)-C_OTM(end-1)) * (Kc_OTM(end)-Kc_OTM(end-1));
else
    Kinf=Kc_OTM(end) + (Kc_OTM(end)-Kc_OTM(end-1));
end

if ~isempty(index_Kc) || ( isempty(index_Kc) && (Kc_OTM_star < Kinf) )
    % Kc_OTM_star << Kc_OTM(index_Kc) if isempty(index_Kc)
    % Kc_OTM_star < Kinf may yield nonzero tmp_int.
    tmp_int = trapz([Kc_OTM_star; Kc_OTM(index_Kc); Kinf], ...
        [C_OTM_star/Kc_OTM_star.^2; C_OTM(index_Kc)./Kc_OTM(index_Kc).^2; 0]);
   
else
    % Kinf << Kc_OTM_star, and C(Kinf)==0.
    tmp_int = 0;
end

    % f(Kinf)=0, f(Kc_OTM(index_Kc))=C_OTM(index_Kc)./Kc_OTM(index_Kc).^2,
    % f(Kc_OTM_star)=C_OTM_star/Kc_OTM_star.^2
    % Note that f(Kinf)=0 is guaranteed by definition above.

clear Kinf;

%% Print the result
EUP = UP + (C_OTM_star/Kc_OTM_star + tmp_int)/ (alpha*T);

if isnan(EUP)
    warning('EUP is NaN.');
end