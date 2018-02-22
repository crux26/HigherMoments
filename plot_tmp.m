date = T_mmtFactors_dly.date;
iVOL = T_mmtFactors_dly.iVOL;
iSKEW = T_mmtFactors_dly.iSKEW;
iKURT = T_mmtFactors_dly.iKURT;

figure;
plot(date, iVOL, '-k');
xlim([date(1)-100 date(end)+100]);
ylim auto;
tickDates = linspace(date(1),date(end),10);
set(gca, 'XTick', tickDates, 'XTickLabel', datestr(tickDates, 12));
title('iVOL');

figure;
plot(date, iSKEW, '-k');
xlim([date(1)-100 date(end)+100]);
ylim auto;
tickDates = linspace(date(1),date(end),10);
set(gca, 'XTick', tickDates, 'XTickLabel', datestr(tickDates, 12));
title('iSKEW');

figure;
plot(date, iKURT, '-k');
xlim([date(1)-100 date(end)+100]);
ylim auto;
tickDates = linspace(date(1),date(end),10);
set(gca, 'XTick', tickDates, 'XTickLabel', datestr(tickDates, 12));
title('iKURT');