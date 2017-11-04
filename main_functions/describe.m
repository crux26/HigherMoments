function describe(X)
% This is for descriptive statistics.
% Compare with summary(T).
nX = size(X,2);
fprintf('\n---------------------------------------------------------------------\n');
for j=1:nX
    fprintf('\n %1.0f-th moment) mean:%4.4f, std:%4.4f\n', j, mean(X(:,j)), std(X(:,j)));
    [a,b]=max(X(:,j)); [c,d]=min(X(:,j));
    fprintf('\n %1.0f-th moment) max:%4.4f, idx_max:%4.0f, min:%4.4f, idx_min:%4.0f\n', j,a,b,c,d);
end
fprintf('\n---------------------------------------------------------------------\n');