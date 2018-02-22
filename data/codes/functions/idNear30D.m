function [T_CallData_, T_PutData_] = idNear30D(T_CallData, T_PutData)
% Extracts only 1 exdate if(exdate==30D) or 2 exdates closest to 30D.

DTM_C = T_CallData.exdate - T_CallData.date;  % calendar day dif. Do not use daysdif(~,~,13).
DTM_P = T_PutData.exdate - T_PutData.date;

[~, idx_near30D_C] = min(abs(DTM_C - 30)); % length(idx_)==1 even if multiple minimum
[~, idx_near30D_P] = min(abs(DTM_P - 30));
% idx_near30D_C_multiple = find(DTM_C == DTM_C(idx_near30D_C)); % selects all min
% idx_near30D_P_multiple = find(DTM_P == DTM_P(idx_near30D_P));

[vC_unique, ~] = unique(abs(DTM_C));
[vP_unique, ~] = unique(abs(DTM_P));

idxC_unique = find(vC_unique == DTM_C(idx_near30D_C)); % min_near30D_C ~= DTM_C(idx_near30D_C)
idxP_unique = find(vP_unique == DTM_P(idx_near30D_P));
%%
% Reason for try-catch: on j==50, 51, DTM=[2;37;65], [36;64] --> error on j==51.
% try-catch removed: Not supported in MEX.
if DTM_C(idx_near30D_C) == 30
    T_CallData_ = T_CallData(DTM_C == DTM_C(idx_near30D_C), :);
elseif DTM_C(idx_near30D_C) - 30 > 0
    if length(vC_unique) >= 2 && any(DTM_C < 30)
        tmpExpiry_C = [vC_unique(idxC_unique-1); vC_unique(idxC_unique)];
        T_CallData_ = [T_CallData(DTM_C == tmpExpiry_C(1), :); T_CallData(DTM_C == tmpExpiry_C(2), :)];
    else
        T_CallData_ = T_CallData(DTM_C == DTM_C(idx_near30D_C), :);
    end
else
    if length(vC_unique) >= 2 && any(DTM_C > 30)
        tmpExpiry_C = [vC_unique(idxC_unique); vC_unique(idxC_unique+1)];
        T_CallData_ = [T_CallData(DTM_C == tmpExpiry_C(1), :); T_CallData(DTM_C == tmpExpiry_C(2), :)];
    else
        T_CallData_ = T_CallData(DTM_C == DTM_C(idx_near30D_C), :);
    end
end

if DTM_P(idx_near30D_P) == 30
    T_PutData_ = T_PutData(DTM_P == DTM_P(idx_near30D_P), :);
elseif DTM_P(idx_near30D_P) - 30 > 0
    if length(vP_unique) >= 2 && any(DTM_P < 30)
        tmpExpiry_P = [vP_unique(idxP_unique-1); vP_unique(idxP_unique)];
        T_PutData_ = [T_PutData(DTM_P == tmpExpiry_P(1), :); T_PutData(DTM_P == tmpExpiry_P(2), :)];
    else
        T_PutData_ = T_PutData(DTM_P == DTM_P(idx_near30D_P), :);
    end
else
    if length(vP_unique) >= 2 && any(DTM_P > 30)
        tmpExpiry_P = [vP_unique(idxP_unique); vP_unique(idxP_unique+1)];
        T_PutData_ = [T_PutData(DTM_P == tmpExpiry_P(1), :); T_PutData(DTM_P == tmpExpiry_P(2), :)];
    else
        T_PutData_ = T_PutData(DTM_P == DTM_P(idx_near30D_P), :);
    end
end

if isempty(T_CallData_)
    error('Check the data again.');
end
if isempty(T_PutData_)
    error('Check the data again.');
end