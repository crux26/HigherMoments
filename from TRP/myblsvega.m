function vega = myblsvega(S, K, r, tau, sigma,q)
d1 = ( log(S./K) + (r-q+0.5*sigma.^2).*tau ) ./ (sigma .* sqrt(tau));
d1(isnan(d1))=0;
vega = S .* exp(-q.*tau) .* 1/sqrt(2*pi) .* exp(-0.5 .* d1.^2) .* sqrt(tau);