function [T_CallData] = dropEnd_OTMC(T_CallData)
if isempty(T_CallData)  % Can be empty for "CallData_2".
    T_CallData=[];
    return;
end
tmpMult = 1.5;

%% drop
% if Kc(end) >>> Kc(end-1), crazy extrapolation results occur.
while length(T_CallData.C)>2 && ...
        (T_CallData.Kc(end) > T_CallData.Kc(end-1) + tmpMult*(T_CallData.Kc(end-1)-T_CallData.Kc(end-2)))
%     C = C(1:end-1); Kc = Kc(1:end-1); IV = IV(1:end-1);
	T_CallData = T_CallData(1:end-1,:);
end

%% extrap
% Now has multiple TTMs, which does not work for the below case. should be fixed.
m = length(T_CallData.Kc);
i=m;
while length(T_CallData.C)>2 && (T_CallData.C(i)>=T_CallData.C(i-1))
    IV_ = interp1(T_CallData.Kc(i-4:i-1), T_CallData.IV(i-4:i-1), ...
        T_CallData.Kc(i), 'nearest', 'extrap'); % pchip,spline yields <0 for some cases.
    if IV_ <= T_CallData.IV(i-1) && IV_ < T_CallData.IV(i)
        T_CallData.IV(i) = IV_;
        T_CallData.C(i) = myblscall(unique(T_CallData.S), T_CallData.Kc(i), ...
            unique(T_CallData.r), unique(T_CallData.TTM), T_CallData.IV(i), unique(T_CallData.q));
        i=i+1;
        if i>=m
            break;
        end
    else
        i=i-1;
    end
end