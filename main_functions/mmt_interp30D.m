function [T_] = mmt_interp30D(T)
% Input: near30D SKEW & KURT, 2 data at maximum (1 data at minimum).
% Output: 30D SKEW & KURT, time interpolated.
nRow = size(T,1);
if nRow > 1
    SKEW_ = interp1(T.DTM, T.SKEW, 30, 'linear', 'extrap');
    KURT_ = interp1(T.DTM, T.KURT, 30, 'linear', 'extrap');
elseif nRow == 1
    SKEW_ = T.SKEW;
    KURT_ = T.KURT;
else
    error('idnear30D() is problematic. More than 2 rows are provided.');
end

% No more exdate: As it is time-interpolated at 30D level.
% Instead, generated "exdate_artificial", for my information.
T_ = table(unique(T.dates_), unique(T.dates_)+30, SKEW_, KURT_, 30, ...
    'VariableNames', {'date_', 'exdate_artificial', 'SKEW', 'KURT', 'DTM'});
