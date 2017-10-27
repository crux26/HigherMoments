function [IV_C_constMaturity, IV_P_constMaturity] = IV_constMaturity(constMaturity, t1, CallIV1, PutIV1, t2, CallIV2, PutIV2)

IV_C_constMaturity = interp1([t1; t2], [CallIV1; CallIV2], constMaturity, 'linear', 'extrap');
IV_P_constMaturity = interp1([t1; t2], [PutIV1; PutIV2], constMaturity, 'linear', 'extrap');