function [T_OpData_Exdate1, T_OpData_Exdate2] = SplitByExdate(T_OpData)
% This function is run after idNear30D(). Hence, 2 exdates at maximum.
[~, idx_exdate, ~] = unique(T_OpData.exdate);
idx_exdate = [idx_exdate; length(T_OpData.exdate)+1];
idx_exdate_next = idx_exdate(2:end)-1; idx_exdate = idx_exdate(1:end-1);

% idx_exdate(jj):idx_exdate_next(jj)
T_OpData_Exdate1 = T_OpData(idx_exdate(1):idx_exdate_next(1), :);

switch length(unique(T_OpData.exdate))
    case 2
        T_OpData_Exdate2 = T_OpData(idx_exdate(2):idx_exdate_next(2), :);
    case 1
        T_OpData_Exdate2 = [];
    case 0
        error('T_OpData.exdate.unique().len()==0. This is a fatal error.');
    otherwise
        error('Number of distinct exdates > 2. This is an error.');
end
