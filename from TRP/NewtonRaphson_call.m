function IV = NewtonRaphson_call(S, K, r, tau, price, x0, tol, q)

% volMid = sqrt( abs( log(S/K) + r*tau) * 2/tau);
volMid = x0;                % if isnan(x0), then problem occurs
volMid(isnan(volMid))=0.2;  % give arbitrary value for vol if isnan(x0)
priceMid = myblscall(S,K,r,tau,volMid,q);
vegaMid = myblsvega(S,K,r,tau,volMid,q);
minDiff = abs(price - priceMid);

counter = 0;
while abs(price - priceMid) >= tol && abs(price - priceMid) <= minDiff
    counter = counter+1;
    if counter == 100
        break;
    end
    volMid = volMid - (priceMid - price) / vegaMid;
    priceMid = myblscall(S,K,r,tau,volMid,q);
    vegaMid = myblsvega(S,K,r,tau,volMid,q);
    minDiff = abs(price - priceMid);
end
IV = volMid;
