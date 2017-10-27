function IV = NewtonRaphson_put(S, K, r, tau, price, x0, tol, q)

% volMid = sqrt( abs( log(S/K) + r*tau) * 2/tau);
volMid = x0;                % if isnan(x0), then problem occurs
volMid(isnan(volMid))=0.2;  % give arbitrary value for vol if isnan(x0)
priceMid = myblsput(S,K,r,tau, volMid,q);
vegaMid = myblsvega(S,K,r,tau,volMid,q);
minDiff = abs(price - priceMid);

% tol_ = 0.01;
counter = 0;
while abs(price - priceMid) >= tol  && abs(price - priceMid) <= minDiff
    counter = counter+1;
    if counter == 100
        break;
    end
%     volOld = volMid;
    volMid = volMid - (priceMid - price) / vegaMid;
    priceMid = myblsput(S,K,r,tau,volMid,q);
    vegaMid = myblsvega(S,K,r,tau,volMid,q);
    minDiff = abs(price - priceMid);
    
%     if counter>1 && volOld>0 && volMid < 0
%         volMid = volOld;
%         break;
%     end
    
%     if abs((price-priceMid)/price) < tol_
%         break;
%     end
end
IV = volMid;
