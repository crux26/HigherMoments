function [DQ, VaR, Kp_OTM0, dP_OTM0, Kp_OTM1, dP_OTM1] = index_P_tail(dP_OTM, Kp_OTM, alpha, S, r, T)
%% Finding [the first index of dP_OPM which does exceed alpha*exp(-r*T) ]-1

% This corresponds the "first" of among [the last indices of DP_OTM which does not exceed alpha*exp(-r*T)].
% Note that if dP_OTM alternates across alpha*exp(-r*T), there could be multiple sets of indices for the latter.
% If not, there's only one satisfying the latter.

% See Hull's Appendix of Ch.19 for more of below. Below is the left tail of the return distribution.

% If options are correctly priced, P must be an increasing function of K (ceteris paribus).
% Then dP will be an increasing function as well.
% However, this may not be true in reality. Hence, if P starts to decrease at some K_,
% discard all Ps larger than K_, and keep Ps with Ks no larger than K_.
% Below is to do that.

% UNLESS dP_OTM alternates ACROSS alpha*exp(-r*T), dP_OTM will increase in general (must be, in principle)
% so there wouldn't be jumps in index_Ltail in general. Anyway, below is to capture that if any.
% (Alternating at << alpha*exp(-r*T) doesn't matter.)
% Below focuses only on the "first" such jump. This corresponds to the smallest K among those candidates.


% If "=" added in find(), then index_C_tail will be problematic if equality holds
index_P_Ltail = find(dP_OTM < alpha*exp(-r*T)); % First derivatives' index.
                                                % dP_OTM is a cdf from -inf to K. So have different dP_OTM values w.r.t.
                                                % different K levels. One's looking for K such that
                                                % whose cdf (or dP_OTM) being smaller than alpha (significance level).
                                                % This corresponds to the concept of VaR.
                                                % Note that dP_OTM is increasing in K, in principle.
                                                % However, this relation can break up in reality, usually in ITM part.

tmp_index1 = max(index_P_Ltail);
if isempty(index_P_Ltail)
    warning('dP_OTM >> alpha*exp(-rT). This is data error.');
    return;
end
if tmp_index1==length(dP_OTM)
    tmp_index1 = index_P_Ltail(find(diff(index_P_Ltail)~=1, 1, 'last'));
end

% index_Ltail finds K_OTM's indices whose dP_OTM (corresponding to given K) satisfies "< alpha*exp(-r*T)".
% This essentially looks for K such that F(x<=K)=alpha. As this is CDF, this must be an increasing function.
% Hence, index_Ltail should have no "jump" in its data, but may not in reality.
                                                
% As P (Put prices) are not necessarily monotone, dP, its first diffrence, are not necessarily monotone either.
% Hence, index_Ltail are not necessarily monotone as well.

% Below is to capture the "left-est" index that exceeds the alpha if there's fluctuation in dP above and below alpha.
% tmp_index1 = index_P_Ltail(find(diff(index_P_Ltail)~=1, 1, 'first')); % to choose the "left" index to the reference point (of alpha*exp(-r*T))
% tmp_index1 = index_P_Ltail(find(diff(index_P_Ltail)~=1, 1, 'last')); 


%% Finding [the first index of dP_OTM which does not exceed alpha*exp(-r*T)]-1
% If "=" added in find(), then index_C_tail will be problematic if equality holds
index_P_Rtail = find(dP_OTM > alpha*exp(-r*T));

% Below is to capture the "right-est" index that exceeds the alpha if there's fluctuation in dP above and below alpha.
% tmp_index2 = index_P_Rtail(find(diff(index_P_Rtail)~=1, 1, 'last')) + 1; % "+1" to choose "right" index to the reference point (of alpha*exp(-r*T))
% tmp_index2 = index_P_Rtail(find(diff(index_P_Rtail)~=1, 1, 'last')) ;
if ~isempty(index_P_Rtail)
    tmp_index2 = tmp_index1+1;
else
    tmp_index2 = tmp_index1;
    tmp_index1 = tmp_index1-1;
end


% if index_P_Rtail has no "jump" in its value, tmp_index2 == []. Then choose the "most left" value of the index_P_Rtail
% --> Whole index_P_Rtail can be empty if dP_OTM0 << alpha*exp(-r*T) or
% dP_OTM0 >> alpha*exp(-r*T). Then below is problematic.
%------------------------------------------------------------------------------------
% if index_Ltail has no "jump" in its value, tmp_index == []. Then choose the "most right" value of index_Ltail

%% New if-condition part.

if ~isempty(tmp_index1)
    if isempty(tmp_index2)
        warning('This should never happen, but happens if there is a fluctuation in dP.');
        i=1;
        while true
            if dP_OTM(tmp_index2) - dP_OTM(tmp_index1) > 0
                break;
            end
            tmp_index1 = index_P_Ltail(end-i);
            tmp_index2 = index_P_Ltail(end);
            i=i+1;
        end
    else
        disp('Both tmp_index1,2 are not empty. Nothing to be done. The most ideal case.');
        % On j==81, while both ~isempty(), have crazy dP_OTM value. Hence, dP_OTM1-dP_OTM0 < 0 happens.
        % Below is for "sanity check" in essential.
        i=1;
        while true
            if dP_OTM(tmp_index2) - dP_OTM(tmp_index1) > 0
                break;
            end
            tmp_index1 = tmp_index1-(i-1);
            tmp_index2 = tmp_index2+(i-1);
            i=i+1;
        end
    end
    
elseif isempty(tmp_index1)
       
    if isempty(tmp_index2)
        % No fluctuation in dP above and below alpha: resulting in both tmp_index1,2 being empty.
        i=1;
        while true
            if dP_OTM(tmp_index2) - dP_OTM(tmp_index1) > 0
                break;
            end
            
            if ~isempty(index_P_Ltail) && ~isempty(index_P_Rtail)
                % ideal case.
                tmp_index1 = index_P_Ltail(end-(i-1));
                tmp_index2 = index_P_Rtail(1+(i-1));

            elseif ~isempty(index_P_Ltail) && isempty(index_P_Rtail)
                % isempty(index_P_Rtail). Using index_P_Ltail instead.
                tmp_index1 = index_P_Ltail(end-i);
                tmp_index2 = index_P_Ltail(end);

            elseif isempty(index_P_Ltail) && ~isempty(index_P_Rtail)
                % isempty(index_P_Ltail). Using index_P_Rtail instead.
                tmp_index1 = index_P_Rtail(1);
                tmp_index2 = index_P_Rtail(1+i);

            elseif isempty(index_P_Ltail) && isempty(index_P_Rtail)
                error('This should never happen.');
            end

            i=i+1;
        end
       
    else
        warning('This should never happen, but happens if there is a fluctuation in dP.');
        i=1;
        while true
            if dP_OTM(tmp_index2) - dP_OTM(tmp_index1) > 0
                break;
            end
            tmp_index1 = index_P_Ltail(end-i);
            tmp_index2 = index_P_Ltail(end);
            i=i+1;
        end
    end
end

if tmp_index2 - tmp_index1 <= 0
    error('tmp_index2 <- tmp_index1. Fix it.');
end

Kp_OTM0 = Kp_OTM(tmp_index1, 1);
dP_OTM0 = dP_OTM(tmp_index1, 1);

Kp_OTM1 = Kp_OTM(tmp_index2, 1);
dP_OTM1 = dP_OTM(tmp_index2, 1);

%% 
% VaR: Value at Risk
% DQ: Downside Quantile

DQ = -log(Kp_OTM0 + (Kp_OTM1-Kp_OTM0) * (alpha*exp(-r*T) - dP_OTM0) / (dP_OTM1-dP_OTM0)) + log(S);
VaR = DQ/T;

if isnan(DQ)
    warning('DQ, VaR is NaN.');
end
