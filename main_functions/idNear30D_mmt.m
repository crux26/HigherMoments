function [T_] = idNear30D_mmt(T)
% T = table(dates_, exdate_, SKEW, KURT, DTM_cal);

% Extracts only 1 exdate if(exdate==30D) or 2 exdates closest to 30D.
DTM_ = T.DTM;

[~, idx_near30D] = min(abs(DTM_ - 30)); % length(idx_)==1 even if multiple minimum

[v_unique, ~] = unique(abs(DTM_));

idx_unique = find(v_unique == DTM_(idx_near30D)); % min_near30D_C ~= DTM_C(idx_near30D_C)
%%
% Reason for try-catch: on j==50, 51, DTM=[2;37;65], [36;64] --> error on j==51.
if DTM_(idx_near30D) == 30
    T_ = T(T.DTM == DTM_(idx_near30D), :);
elseif DTM_(idx_near30D) - 30 > 0
    try
        tmpExpiry_C = [v_unique(idx_unique-1); v_unique(idx_unique)];
        T_ = [T(T.DTM == tmpExpiry_C(1), :); T(T.DTM == tmpExpiry_C(2), :)];
    catch
        T_ = T(T.DTM == DTM_(idx_near30D), :);
    end
else
    try
        tmpExpiry_C = [v_unique(idx_unique); v_unique(idx_unique+1)];
        T_ = [T(T.DTM == tmpExpiry_C(1), :); T(T.DTM == tmpExpiry_C(2), :)];
    catch
        T_ = T(T.DTM == DTM_(idx_near30D), :);
    end
end

if isempty(T_)
    error('Check the data again.');
end
