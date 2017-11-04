function [OpData_extrap_] = MatMatch(OpData_extrap_, TTM)
idx = [];
for i=1:length(TTM)
    idx_ = find(OpData_extrap_.TTM == TTM(i));
    idx = [idx; idx_];
end
OpData_extrap_ = OpData_extrap_(idx, :);