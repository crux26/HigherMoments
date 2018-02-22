function [T] = IVextrap_ByExdate_mat(T_OpData, TTM)
%% IV interp/extrap by exdate.
[exdate_ByDate, idx_exdate_ByDate] = unique(T_OpData.exdate);

idx_exdate_ByDate = [idx_exdate_ByDate; length(T_OpData.exdate) + 1];
m = 1e+3;   % The number of moneyness grids.
T = [];
for i=1:length(exdate_ByDate)
    tmpIdx = idx_exdate_ByDate(i) : (idx_exdate_ByDate(i+1)-1);
    moneyness_grid = linspace(1e-4, 3, m); % 0.01% seems to be 1%, but trusting the paper's value.
    % In fact, they're more or less the same. 
    % find(min(abs(moneyness_grid-1)))==332, 334 for 1e-2, 1e-4 case, respectively.
    
    moneyness_min = min(T_OpData.moneyness(tmpIdx)); moneyness_max = max(T_OpData.moneyness(tmpIdx));
    
    idx_middle = find(moneyness_grid >= moneyness_min & moneyness_grid <= moneyness_max);
    IV_extrap = zeros(m,1);
    IV_extrap(idx_middle) = interp1(T_OpData.moneyness(tmpIdx), T_OpData.IV(tmpIdx), moneyness_grid(idx_middle), 'pchip');
    % OpData(:,17): moneyness, OpData(:,6): IV
    idx_max = find(moneyness_grid > moneyness_max);
    idx_min = find(moneyness_grid < moneyness_min);
    % Constant IV for ITM part.
    IV_extrap(idx_max) = IV_extrap( min(idx_max) - 1);
    IV_extrap(idx_min) = IV_extrap( max(idx_min) + 1);
    
    % unique() should have length 1.
    S = T_OpData.S(1); r=unique(T_OpData.r(tmpIdx))*252; q=unique(T_OpData.q(tmpIdx));
    TTM_ = unique(TTM.TTM(tmpIdx));
    if length(r)~=1 || length(q)~=1
        error('r.len()~=1 or q.len()~=1.');
    end
    if length(TTM_)~=1
        error('TTM_.len()~=1.');
    end
    
    K = S ./ moneyness_grid';
    
    if T_OpData.cpflag(1) == 1
        OpPrice = myblsput(S, K, r, TTM_, IV_extrap, q);
    else
        OpPrice = myblscall(S, K, r, TTM_, IV_extrap, q);
    end

    
    T_ = table(repmat(T_OpData.date(1),m,1), repmat(exdate_ByDate(i), m, 1), ...
        K, IV_extrap, moneyness_grid', repmat(S,m,1), repmat(r,m,1), ...
        repmat(q,m,1), OpPrice, repmat(TTM_, m, 1), ...
    'VariableName', {'date', 'exdate', 'strike', 'IV_extrap', 'moneyness', 'S', 'r', 'q', 'OpPrice', 'TTM'} );
    
    T = [T; T_];
end

% CallData = [date, exdate, strike_price, volume, open_interest, impl_volatility, ...
%     delta, gamma, vega, theta, spindx, sprtrn, ...
%     tb_m3, div, spxset, spxset_expiry, moneyness, mid, ...
%     opret];