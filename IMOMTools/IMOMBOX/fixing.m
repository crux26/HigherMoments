%%
clear; clc;
Kc = (90:10:120)';
Kp = (80:10:110)';

[~, idxC, idxP] = intersect(Kc, Kp);
Kc(idxC)
Kp(idxP)
intersect(Kc,Kp)