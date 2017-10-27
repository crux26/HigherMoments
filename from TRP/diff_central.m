function dOpPrice = diff_central(OpPrice, Strike, DiffStepSize)
% OpPrice: column vector
% Strike: column vector
% |dOpPrice(end) - dOpPrice(end-1)| < eps. The "last" value is duplicated in order to retain the size "N".
if nargin < 3
    DiffStepSize=1;
end

N = size(OpPrice,1);

if N == 1
    error('The number of provided options is 1. Provide a volatility curve.');
end

dOpPrice = zeros(N,1);

for i = 1+DiffStepSize : N-DiffStepSize
    dOpPrice(i,1) = (OpPrice(i+DiffStepSize,1)-OpPrice(i-DiffStepSize,1)) /...
        (Strike(i+DiffStepSize,1)-Strike(i-DiffStepSize,1));
end

if DiffStepSize > 1
    for i=DiffStepSize:-1:2
        % central difference
        dOpPrice(i,1) = (OpPrice(i+(i-1),1)-OpPrice(i-(i-1),1)) /...
            (Strike(i+(i-1),1)-Strike(i-(i-1),1));
    end

    for i=N-DiffStepSize+1:N-1
        % central difference
        dOpPrice(i,1) = (OpPrice(i+(N-i),1)-OpPrice(i-(N-i),1)) /...
            (Strike(i+(N-i),1)-Strike(i-(N-i),1));
    end
end

dOpPrice(1,1) = (OpPrice(2,1)-OpPrice(1,1)) / (Strike(2,1)-Strike(1,1));
dOpPrice(N,1) = (OpPrice(N,1)-OpPrice(N-1,1)) / (Strike(N,1)-Strike(N-1,1));