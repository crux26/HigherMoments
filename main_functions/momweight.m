function out = momweight(X,S0,n)
    % In BKM03, any contract on R^n=[ln(ST/S0)^N] can be replicated using bond,
    % the underlying, puts and calls. The function MOMWEIGHT(K,S0,N) yields the 
    % required weights in the Put and Call options for any strike level X, spot
    % asset price S0 and contract exponent N.
    %
    % out (weight) same for both call and put. Note the moneyness notation in BKM03.
    out = 1./X.^2 .* n .* ( (n-1) .* log(X./S0).^(n-2) - log(X./S0).^(n-1) );
    idx_ = find(~isnan(out));
    out = interp1( X(idx_), out(idx_), X, 'linear', 'extrap');

% I changed below for above, using interp1().
%     idx = find(isnan(out));
%     if ~isempty(idx)
%         if idx==length(out)
%             out(idx)=out(idx-1);
%         elseif idx==1
%             out(idx)=out(2);
%         else
%             out(idx) = 1/2*(out(idx-1)+out(idx+1));
%         end
%     end
end
