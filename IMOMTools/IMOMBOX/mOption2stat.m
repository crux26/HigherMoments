function out = mOption2stat(Kc,C,Kp,P,S0,df,N)
%     MOPTION2STAT compute implied standardized moments from calls and puts
%
%     N: the first N number of moments
%     df: Discount Factor
% 
%     S = MOPTION2STAT(Kc,C,Kp,P)
%     returns first four standardized moments of an asset's risk neutral log 
%     return distribution from traded put and call options traded on that
%     asset, with equal time to maturity. The values of the spot asset price 
%     S0 and the factor for discounting, DF, are approximated along the way.
% 
%     S = MOPTION2STAT(Kc,C,Kp,P,S0)
%     returns first four standardized moments of an asset's risk neutral log 
%     return distribution from traded put and call options traded on that
%     asset, with equal time to maturity. The value of the discounting factor 
%     DF is approximated along the way.
% 
%     S = MOPTION2STAT(Kc,C,Kp,P,S0,DF)
%     returns first four standardized moments of an asset's risk neutral log 
%     return distribution from traded put and call options traded on that
%     asset, with equal time to maturity.
% 
%     S = MOPTION2STAT(Kc,C,Kp,P,S0,DF,N)
%     returns first N standardized moments of an asset's risk neutral log 
%     return distribution from traded put and call options traded on that
%     asset, with equal time to maturity. Note that, as there only a discrete
%     number of options employed in this approximation, the accuracy of the
%     result will quickly decrease with N.
% 
%     S = MOPTION2STAT(S0,VOL,RF,Q,TAU,N)
%     returns first N standardized moments of an asset's risk neutral log
%     return distribution TAU years from now. S0 is the asset's spot level, 
%     VOL is a function handle to the volatility smile for this asset and 
%     maturity. RF is the annualized logarithmic risk neutral rate of return, 
%     Q is the asset's annualized continuous dividend yield. The vector N 
%     contains the moments that are to be priced.

    %   Author:     matthias.held@web.de
    %   Date:       2014-07-25

%     if ~exist('N')
    if ~exist('N', 'var')
        N=4;
    end

    if length(N)>1
        N = max(N);
    end

    out             = zeros(N,1);

%     if ~exist('df') | ~exist('S0')
    if ~exist('df', 'var') || ~exist('S0', 'var')
        [~,idxC,idxP]   = intersect(Kc,Kp);
        if length([idxC idxP])>2
            YY              = C(idxC)-P(idxP);
            XX              = [ones(length(YY),1) Kc(idxC)];
%             b1              = inv(XX'*XX)*(XX'*YY);
            b1              = (XX'*XX)\(XX'*YY);
            df              = -b1(2);
            S0              = b1(1);
        else
            error('Plese supply discount factor and/or spot asset price.')
        end
    end

    % move risk-neutral moment expectations (prices) into the future, and then
    % sum over centered moment expansion E[ (x-?^n ] = x^n - x^(n-1)?1 + ...
    M               = mOption2price(Kc,C,Kp,P,S0,df,1:N)*1/df;
    factor_          = @(x,n) factorial(n)./(factorial(x).*factorial(n-x));
    % factor(): built-in function
    for n = 1:N
        out(n)          = sum( factor_(0:n,n).*(-1).^(0:n) ...
                            .*[M(n-(0:n-1)) 1].*M(1).^(0:n));
    end
    % moment(1) should be mean, moment(2) is var, then standardize moments 3:N
    out(1) = M(1);
    if N>2
        out(3:N) = out(3:N)./(out(2).^(0.5*(3:N)'));
    end

end