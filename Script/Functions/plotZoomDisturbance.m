function plotZoomDisturbance(comparison,label)
%PLOTZOOMDISTURBANCE Magnify the small positioning errors near disturbance.
paths=zoomProjectPaths;
root=paths.Root;
selected=comparison.Time_s>=6.5 & comparison.Time_s<=9;
c=comparison(selected,:);
fig=figure('Name',label+" disturbance detail",'Position',[100 100 1100 600],'Color','w');
layout=tiledlayout(fig,2,1,'TileSpacing','compact');
ax=nexttile(layout);
plot(ax,c.Time_s,1000*[c.Gap1Actual_mm-c.Gap1Command_mm,c.Gap2Actual_mm-c.Gap2Command_mm],'LineWidth',1.4);
grid(ax,'on'); ylabel(ax,'Gap error (micrometers)'); legend(ax,'Gap 1','Gap 2','Location','best');
xline(ax,7,'--'); xline(ax,7.5,'--');
ax=nexttile(layout);
plot(ax,c.Time_s,c.ServoFocalError_mm,'LineWidth',1.4);
grid(ax,'on'); ylabel(ax,'Servo focal error (mm)'); xlabel(ax,'Time (s)');
xline(ax,7,'--'); xline(ax,7.5,'--');
title(layout,label+" | disturbance interval 7–7.5 s (sweep also contains tracking error)");
exportgraphics(fig,fullfile(root,'Results',label+"_disturbance.png"),'Resolution',150);
close(fig);
end
