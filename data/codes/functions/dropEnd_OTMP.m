function [T_PutData] = dropEnd_OTMP(T_PutData)
% Copied from TRP, but changed the structure here.
if isempty(T_PutData)   % Can be empty for "PutData_2".
    T_PutData=[];
    return;
end
tmpMult = 1.5;

%% drop
if length(T_PutData.P)>2 && (T_PutData.Kp(1) < T_PutData.Kp(2) - tmpMult*(T_PutData.Kp(3)-T_PutData.Kp(2)))
% 	P = P(2:end); Kp = Kp(2:end); IV = IV(2:end);
    T_PutData = T_PutData(2:end,:);
end

%% extrap 
i=1;
while length(T_PutData.P)>2 && (T_PutData.P(i)>=T_PutData.P(i+1))
    IV_ = interp1(T_PutData.Kp(i+1:i+4), T_PutData.IV(i+1:i+4), ...
        T_PutData.Kp(i), 'nearest', 'extrap');  % pchip, spline can be <0 for some cases.
                                                % P will be near-0 anyway (even if IV>>0)
    if IV_ >= T_PutData.IV(i+1) && IV_ > T_PutData.IV(i)
        T_PutData.IV(i) = IV_;
        T_PutData.P(i) = myblsput(unique(T_PutData.S), T_PutData.Kp(i), ...
            unique(T_PutData.r), unique(T_PutData.TTM), IV(i), unique(T_PutData.q));
        i=i-1;
    else
        i=i+1;
    end
    if i==0
        break;
    end
end