function [exdate_, idx_exdate_, exdate__, idx_exdate__, date] = retrieveExdates(CallData, PutData)

[date_, idx_date_] = unique(CallData.date);
[date__, idx_date__] = unique(PutData.date);
if date_ ~= date__
    error('#dates(Call) ~= #dates(Put). Check the data.');
end

idx_date_ = [idx_date_; length(CallData.date)+1]; % to include the last index.
idx_date__ = [idx_date__; length(PutData.date)+1]; % unique() doesn't return the last index.

exdate_=[]; idx_exdate_=[]; exdate__=[]; idx_exdate__=[]; date=[];

idx_date_next = idx_date_(2:end)-1;
idx_date__next = idx_date__(2:end)-1;

% for: 4.5s, parfor: 105s (DORM PC)
% Calculation below is too less intensive:
% there's overhead sending the work out & receiving results & pooling results altogether.
for j=1:length(date_)
%     tmpIdx1 = idx_date_(j):(idx_date_(j+1)-1) ; % for call
%     tmpIdx2 = idx_date__(j):(idx_date__(j+1)-1) ; % for put
    
    tmpIdx1 = idx_date_(j):idx_date_next(j) ; % for call
    tmpIdx2 = idx_date__(j):idx_date__next(j) ; % for put
    %%
    CallData_ = CallData(tmpIdx1, :);
    PutData_ = PutData(tmpIdx2, :);
    [exdateC, idx_exdateC] = unique(CallData_.exdate);
    [exdateP, idx_exdateP] = unique(PutData_.exdate);
    idx_exdateC = idx_date_(j)-1 + idx_exdateC;
    idx_exdateP = idx_date__(j)-1 + idx_exdateP;
    exdate_ = [exdate_; exdateC];
    idx_exdate_ = [idx_exdate_; idx_exdateC];
    exdate__ = [exdate__; exdateP];
    idx_exdate__ = [idx_exdate__; idx_exdateP];
    date = [date; repmat(date_(j),length(exdateC),1)];
end
