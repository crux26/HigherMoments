function [UQ, UP] = index_C_tail(dC_OTM, Kc_OTM, alpha, S, r, T)
%% This is equivalent to index_R_tail
% Separated index_C_tail & index_R_tail, because calculation for tails are
% slightly different, though they are "symmetric".

%% index_C_Rtail
% If "=" added in find(), then index_C_tail will be problematic if equality holds
index_C_Rtail = find(-dC_OTM < alpha*exp(-r*T));
tmp_index2 = min(index_C_Rtail);
if isempty(index_C_Rtail)
    warning('-dC_OTM >> alpha*exp(-rT). This is data error.');
    return;
end
if tmp_index2 == 1
    tmp_index2 = index_C_Rtail(find(diff(index_C_Rtail)~=1, 1, 'first')+1);
end

% tmp_index2 = index_C_Rtail(find(diff(index_C_Rtail)~=1, 1, 'last')) + 1;
% tmp_index2 = index_C_Rtail(find(diff(index_C_Rtail)~=1, 1, 'first'));

%% index_C_Ltail
% If "=" added in find(), then index_C_tail will be problematic if equality holds
index_C_Ltail = find(-dC_OTM > alpha*exp(-r*T));
% tmp_index1 = index_C_Ltail(find(diff(index_C_Ltail)~=1, 1, 'first'));
% tmp_index1 = index_C_Ltail(find(diff(index_C_Ltail)~=1, 1, 'last'))-1;
if ~isempty(index_C_Ltail)
    tmp_index1 = tmp_index2-1;
else
    tmp_index1 = tmp_index2;
    tmp_index2 = tmp_index2+1;
end

% if index_C_Rtail has no "jump" in its value, tmp_index == []. Then choose the "most left" value of the index_C_Rtail
% --> Whole index_C_Rtail can be empty if -dC_OTM0 << alpha*exp(-r*T) or
% -dC_OTM0 >> alpha*exp(-r*T). Then below is problematic.



%% New if-condition part.

if ~isempty(tmp_index1)
    if isempty(tmp_index2)
        warning('This should never happen, but happens if there is a fluctuation in dC.');
        i=1;
        while true
            if dC_OTM(tmp_index2) - dC_OTM(tmp_index1) > 0
                break;
            end
            tmp_index1 = index_C_Ltail(end-i);
            tmp_index2 = index_C_Ltail(end);
            i=i+1;
        end
    else
        disp('Both tmp_index1,2 are not empty. Nothing to be done. The most ideal case.');
        % On j==81, while both ~isempty(), have crazy dP_OTM value. Hence, dP_OTM1-dP_OTM0 < 0 happens.
        % (Note that this is the put case, but "sanity check" below.)
        % Below is for "sanity check" in essential.
        i=1;
        while true
            if dC_OTM(tmp_index2) - dC_OTM(tmp_index1) > 0
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
            if dC_OTM(tmp_index2) - dC_OTM(tmp_index1) > 0
                break;
            end
            
            if ~isempty(index_C_Ltail) && ~isempty(index_C_Rtail)
                % ideal case.
                tmp_index1 = index_C_Ltail(end-(i-1));
                tmp_index2 = index_C_Rtail(1+(i-1));

            elseif ~isempty(index_C_Ltail) && isempty(index_C_Rtail)
                % isempty(index_C_Rtail). Using index_C_Ltail instead.
                tmp_index1 = index_C_Ltail(end-i);
                tmp_index2 = index_C_Ltail(end);

            elseif isempty(index_C_Ltail) && ~isempty(index_C_Rtail)
                % isempty(index_C_Ltail). Using index_C_Rtail instead.
                tmp_index1 = index_C_Rtail(1);
                tmp_index2 = index_C_Rtail(1+i);

            elseif isempty(index_C_Ltail) && isempty(index_C_Rtail)
                error('This should never happen.');
            end
            i=i+1;
        end
       
    else
        warning('This should never happen, but happens if there is a fluctuation in dC.');
        i=1;
        while true
            if dC_OTM(tmp_index2) - dC_OTM(tmp_index1) > 0
                break;
            end            
            tmp_index1 = index_C_Rtail(1);
            tmp_index2 = index_C_Ltail(1+i);
            i=i+1;
        end
    end
end

if tmp_index2 - tmp_index1 <= 0
    error('tmp_index2 <- tmp_index1. Fix it.');
end

Kc_OTM0 = Kc_OTM(tmp_index1, 1);
dC_OTM0 = dC_OTM(tmp_index1, 1);

Kc_OTM1 = Kc_OTM(tmp_index2, 1);
dC_OTM1 = dC_OTM(tmp_index2, 1);


%%
% UQ: Upside Quantile
% UP: Upside Potential


UQ = log(Kc_OTM0 + (Kc_OTM1 - Kc_OTM0)*(-alpha*exp(-r*T) - dC_OTM0)/(dC_OTM1-dC_OTM0)) - log(S);
UP = UQ/T;

if isnan(UQ)
    warning('UQ, UP are NaN.');
end