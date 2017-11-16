function [tbl_coeff, tbl_SE, tbl_t, res] = myARMA11(yvar)
% Cheked res is more or less the same of EViews' residual for running ARMA11.
% Hence, this is not a software problem. They had run a different model.
ARMA11 = arima('ARLags', 1, 'MALags', 1); fprintf('\nUsing arima(). This is equiv. to EViews.SKEW(-1)\n');
% ARMA11 = regARIMA(1,0,1); fprintf('\nUsing regARIMA(). This is equiv. to Eviews.AR(1)\n');

Display='off';   % off, full, diagnostics, iter, params(default)
[Est, EstCov, ~, ~] = estimate(ARMA11, yvar, 'Display', Display);
[res,~,~] = infer(Est, yvar);
diag_ = sqrt(diag(EstCov));
coeff_AR1 = cell2mat(Est.AR(:));  % AR(1)
coeff_MA1 = cell2mat(Est.MA(:));  % MA(1)
coeff_SE = diag_(2:end-1);   % AR(1).SE() & MA(1).SE()
coeff_t = [coeff_AR1; coeff_MA1] ./ coeff_SE;

const = Est.Constant;
const_SE = diag_(1);
const_t = const / const_SE;

Var = Est.Variance;
Var_SE = diag_(end);
Var_t = Var / Var_SE;


AR1_SE = coeff_SE(1);
MA1_SE = coeff_SE(2);
AR1_t = coeff_t(1);
MA1_t = coeff_t(2);

tbl_coeff = table(const, coeff_AR1, coeff_MA1, Var);
tbl_SE = table(const_SE, AR1_SE, MA1_SE, Var_SE);
tbl_t = table(const_t, AR1_t, MA1_t, Var_t);