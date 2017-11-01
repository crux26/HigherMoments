function [T] = IVextrap_ByExdate(OpData, TTM, cpflag)
%% IV interp/extrap by exdate.
[exdate_ByDate, idx_exdate_ByDate] = unique(OpData.exdate);

idx_exdate_ByDate = [idx_exdate_ByDate; length(OpData.exdate) + 1];
m = 1000;
T = [];
for i=1:length(exdate_ByDate)
    tmpIdx = idx_exdate_ByDate(i) : (idx_exdate_ByDate(i+1)-1);
    moneyness_grid = linspace(0.01, 3, m);
    moneyness_min = min(OpData.moneyness(tmpIdx)); moneyness_max = max(OpData.moneyness(tmpIdx));
    
    idx_middle= find(moneyness_grid >= moneyness_min & moneyness_grid <= moneyness_max);
    IV_extrap = zeros(1000,1);    
    IV_extrap(idx_middle) = interp1(OpData.moneyness(tmpIdx), OpData.IV_extrap(tmpIdx), moneyness_grid(idx_middle), 'pchip');
    
    idx_max = find(moneyness_grid > moneyness_max);
    idx_min = find(moneyness_grid < moneyness_min);
    
    IV_extrap(idx_max) = IV_extrap( min(idx_max) - 1);
    IV_extrap(idx_min) = IV_extrap( max(idx_min) + 1);
    
    % unique() should have length 1.
    S = OpData.S(1); r=unique(OpData.r(tmpIdx)); q=unique(OpData.q(tmpIdx));
    TTM_ = unique(TTM.TTM(tmpIdx));
    if length(r)~=1 || length(q)~=1
        error('r.len()~=1 or q.len()~=1.');
    end
    if length(TTM_)~=1
        error('TTM_.len()~=1.');
    end
    
    K = moneyness_grid' * S;
    
    if cpflag == 1
        [~, OpPrice] = blsprice(S, moneyness_grid'*S, r, TTM_, IV_extrap);
    else
        [OpPrice, ~] = blsprice(S, moneyness_grid'*S, r, TTM_, IV_extrap);
    end
    
    T_ = table(repmat(OpData.date(1),m,1), repmat(exdate_ByDate(i), m, 1), ...
        K, IV_extrap, moneyness_grid', repmat(S,m,1), repmat(r,m,1), ...
        repmat(q,m,1), OpPrice, repmat(TTM_, m, 1), ...
    'VariableName', {'date', 'exdate', 'strike', 'IV_extrap', 'moneyness', 'S', 'r', 'q', 'OpPrice', 'TTM'} );
    
    T = [T; T_];
end

% CallData = [date, exdate, strike_price, volume, open_interest, impl_volatility, ...
%     delta, gamma, vega, theta, spindx, sprtrn, ...
%     tb_m3, div, spxset, spxset_expiry, moneyness, mid, ...
%     opret];