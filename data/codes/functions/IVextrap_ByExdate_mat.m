%% IV interp/extrap by exdate, from 0.01% to 300%.
function [T] = IVextrap_ByExdate_mat(T_OpData, TTM)

[exdate_ByDate, idx_exdate_ByDate] = unique(T_OpData.exdate);
idx_exdate_ByDate = [idx_exdate_ByDate; length(T_OpData.exdate) + 1];
m = 1e+3;   % The number of moneyness grids (as in Chang, Christoffersen, Jacobs, 2013).
T = [];
for i=1:length(exdate_ByDate)
    tmpIdx = idx_exdate_ByDate(i) : (idx_exdate_ByDate(i+1)-1);
    moneyness_grid = fliplr(linspace(1e-4, 3, m));  % 0.01% seems to be 1%, but trusting the paper's value.
                                                    % T_OpData.moneyness: decreasing.
                                                    % Hence, moneyness_grid must be decreasing as well.
    % In fact, they're more or less the same. 
    % find(min(abs(moneyness_grid-1)))==332, 334 for 1e-2, 1e-4 case, respectively.

    [moneyness_max, idx_m_max] = max(T_OpData.moneyness(tmpIdx));
    [moneyness_min, idx_m_min] = min(T_OpData.moneyness(tmpIdx));
    
    idx_middle = find(moneyness_grid >= moneyness_min & moneyness_grid <= moneyness_max);
    IV_extrap = zeros(m,1);
    IV_extrap(idx_middle) = interp1(T_OpData.moneyness(tmpIdx), T_OpData.IV(tmpIdx), moneyness_grid(idx_middle), 'pchip');
    % Constant IV for K/S in )0.97, 1.03(, using IV of the lowest/highest available strike price.
    IV_extrap(moneyness_grid > moneyness_max) = T_OpData.IV(idx_m_max);
    IV_extrap(moneyness_grid < moneyness_min) = T_OpData.IV(idx_m_min);

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
%--------------------------------------------------------------------------------
% moneyness < 1 (K/S < 1): for P
% moneyness > 1 (K/S > 1): for C
% Note that I defined moneyness:=S/K, but the CCJ(2013) defined it as K/S, which is a reciprocal.

    if T_OpData.cpflag(1) == 1 
        idx = find(moneyness_grid > 1); % OTMP only
        OpPrice = myblsput(S, K(idx), r, TTM_, IV_extrap(idx), q);
    else
        idx = find(moneyness_grid <= 1); % OTMC only
        OpPrice = myblscall(S, K(idx), r, TTM_, IV_extrap(idx), q);
    end
%--------------------------------------------------------------------------------
    nGrid = length(idx);
    T_ = table(repmat(T_OpData.date(1), nGrid, 1), repmat(exdate_ByDate(i), nGrid, 1), ...
        K(idx), IV_extrap(idx), moneyness_grid(idx)', repmat(S, nGrid, 1), repmat(r, nGrid, 1), ...
        repmat(q, nGrid, 1), OpPrice, repmat(TTM_, nGrid, 1), ...
    'VariableName', {'date', 'exdate', 'strike', 'IV_extrap', 'moneyness', 'S', 'r', 'q', 'OpPrice', 'TTM'} );
    
    T = [T; T_];
end
