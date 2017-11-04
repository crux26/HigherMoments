function [SKEW, KURT] = momPrice2mom(mom2, mom3, mom4, r, TTM)

mom1 = exp(r.*TTM)-1-0.5*exp(r.*TTM).*mom2 - exp(r.*TTM)./6.*mom3 - exp(r.*TTM)./24.*mom4;

denominator = exp(r.*TTM).*mom2 - mom1.^2;

SKEW = exp(r.*TTM).*mom3 - 3*mom1.*exp(r.*TTM).*mom2 + 2*(mom1).^3;
SKEW = SKEW./denominator.^1.5;

KURT = exp(r.*TTM).*mom4 - 4*mom1.*exp(r.*TTM).*mom3 + 6*exp(r.*TTM).*(mom1).^2.*mom2 - 3*(mom1).^4;
KURT = KURT./denominator.^2;
