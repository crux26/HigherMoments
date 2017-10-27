function out = mVol2stat(S0,vol,rf,q,tau,N)
    % MVOL2STAT implied standardized moments given volatility smile
    % 
    % S = MVOL2STAT(S0,VOL,RF,Q,TAU,N)
    % returns first N standardized moments of an asset's risk neutral log
    % return distribution TAU years from now. S0 is the asset's spot level, 
    % VOL is a function handle to the volatility smile for this asset and 
    % maturity. RF is the annualized logarithmic risk neutral rate of return, 
    % Q is the asset's annualized continuous dividend yield. The vector N 
    % contains the moments that are to be priced.
    % 
    % Example: constant volatility smile
    % 
    % vol         = @(K) 0.3.*exp(-1./100.*K)+0.2
    % S0          = 100
    % rf          = 0.05
    % q           = 0.02
    % tau         = 1
    % N           = 4
    % mVol2stat(S0,vol,rf,q,tau,n)
    % 
    % Author:     matthias.held@web.de
    % Date:       2014-07-25

    if ~isa(vol, 'function_handle')
        vol = @(K) vol;
    end

    if length(N)>1
        N = max(N);
    end

    out             = zeros(N,1);

    % move risk-neutral moment expectations (prices) into the future, and then
    % sum over centered moment expansion E[ (x-?^n ] = x^n - x^(n-1)?1 + ...
    M               = mVol2price(S0,vol,rf,q,tau,1:N) * exp(rf*tau);
    factor          = @(x,n) factorial(n)./(factorial(x).*factorial(n-x));
    for n = 1:N
        out(n)          = sum( factor(0:n,n).*(-1).^(0:n) ...
                            .*[M(n-(0:n-1)) 1].*M(1).^(0:n));
    end
    % moment(1) should be mean, moment(2) is var, then standardize moments 3:N
    out(1) = M(1);

    if N>2
        out(3:N) = out(3:N)./(out(2).^(0.5*(3:N)'));
    end

end