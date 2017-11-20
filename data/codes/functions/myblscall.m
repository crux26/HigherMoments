function price = myblscall(S,K,r,tau,sigma,q)

d1 = ( log(S./K) + (r-q+0.5*sigma.^2).*tau ) ./ (sigma .* sqrt(tau));
d2 = d1 - sigma .* sqrt(tau);
d1(isnan(d1))=0; d2(isnan(d2))=0;
F = S.*exp((r-q).*tau);

price = exp(-r.*tau) .* (F.*mynormcdf1(d1)-K.*mynormcdf1(d2));
% price = reshape(price, size(S));