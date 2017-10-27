function out = mVol2price(S0,vol,rf,q,tau,MomentRank)
    % MVOL2PRICE compute prices of moment contracts given volatility smile
    %
    % vol -> price -> moment
    %
    % BKM03: "Notably one must always pay to go long the volatility and the
    % quartic/kurtosis contracts.". That is, cubic/skewness contract may
    % have a negative price while volatility or quartic/kurtosis contracts
    % always have a positive price.
    %
    % M = MVOL2PRICE(S0,VOL,RF,Q,TAU,N)
    % returns M=E(df * log(ST/S0)^N), the prices of contracts written on the 
    % uncentered moments N of an asset's risk neutral log return distribution 
    % TAU years from now. S0 is the asset's spot level, VOL is a function
    % handle to the volatility smile for this asset and maturity. RF is the
    % annualized logarithmic risk neutral rate of return, Q is the asset's
    % annualized continuous dividend yield. The vector N contains the moments
    % that are to be priced.
    % 
    % Example: 
    % 
    % vol         = @(K) 0.3.*exp(-1./100.*K)+0.2; % volatility smile
    % S0          = 100
    % rf          = 0.05
    % q           = 0.02
    % tau         = 1
    % n           = [1:4]
    % mVol2price(S0,vol,rf,q,tau,n)
    % 
    % Author:     matthias.held@web.de
    % Date:       2014-07-25
    % 
    % Compute the prices of return moment prices as stated in BKM03. 
    % The moment-k contract pays [ln(S/S)]^k at maturity. Thus, the moment
    % itself is the un-discounted value-> multiply the momcontract with 1/df.
    % 
    % the relevant return is log(ST/S0), the dividend yield is (not?) of
    % interest...
    % if q~=0;S0 = S0*exp(-q*tau);q = 0;end
    % ----------------------------------------------------------------
    % Below wouldn't work. If vol is a vector, not a function handle,
    % then it becomes a constant vector even if stated as a function a
    % handle.
    % Hence, cannot access the first element of vol by vol(1).
    % If K = length(vol), then vol(1) == vol(2) == ...
    % will return the vol.
    if ~isa(vol,'function_handle')
        vol = @(K) vol; % to integrate w.r.t. K (in quadgk)
%         error('vol is not a function handle. Provide a function handle');
    end
    
    out = zeros(length(MomentRank), 1);
    for i = 1:length(MomentRank)
%         if ~exist('quadgk')
        if ~exist('quadgk', 'file')
            dx              = S0/10000;
            xl              = dx:dx:S0;
            xr              = S0+dx:dx:10*S0; % 10*S0 == inf
            out(i)          = sum( momweight(xl,S0,MomentRank(i)) ...
                                    .*Put(S0,xl,@(K)vol(K),rf,q,tau)) + ...
                              sum( momweight(xr,S0,MomentRank(i)) ...
                                    .*Call(S0,xr,@(K)vol(K),rf,q,tau));
            out(i)          = out(i)*dx;
        else
            % vol = @(K) vol --> volatility being a function of strike,
            % assumed to be smooth. 
            % Hence, volatility (smile) being integrated w.r.t. K.
            out(i)          = quadgk( @(K) momweight(K,S0,MomentRank(i)) ...
                                            .*Put(S0,K,vol,rf,q,tau),...
                                     0,S0,'AbsTol',1E-15) ...
                            + quadgk( @(K) momweight(K,S0,MomentRank(i)) ...
                                            .*Call(S0,K,vol,rf,q,tau),...
                                    S0,Inf,'AbsTol',1E-15);
        end
        
        if MomentRank(i) == 1 % first moment
            out(i) = out(i) + 1 - exp(-rf*tau);
        end
        
    end
end

function out = Call(S0,K,vol,r,q,tau)
    % vol: function handle
    d1          = (log(S0./K)+(r-q + 0.5.*vol(K).^2).*tau)./(vol(K).*sqrt(tau));
    d2          = d1-vol(K).*sqrt(tau);
    d1(isnan(d1)) = 0; d2(isnan(d2)) = 0;
    out         = S0.*exp(-q.*tau).*mynormcdf1(d1) - K.*exp(-r.*tau).*mynormcdf1(d2); % normcdf -> mynormcdf1
end

function out = Put(S0,K,vol,r,q,tau)
    % vol: function handle
    d1          = (log(S0./K)+(r-q + 0.5.*vol(K).^2).*tau)./(vol(K).*sqrt(tau));
    d2          = d1-vol(K).*sqrt(tau);
    d1(isnan(d1)) = 0; d2(isnan(d2)) = 0;
    out         = K.*exp(-r.*tau).*(1-mynormcdf1(d2))-S0.*exp(-q.*tau).*(1-mynormcdf1(d1));
end
