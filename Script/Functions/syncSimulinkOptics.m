function comparison=syncSimulinkOptics(simulation,trajectory,label,options)
%SYNCSIMULINKOPTICS Evaluate actual gaps offline, preserving the fixed sensor.
arguments
    simulation (1,1) Simulink.SimulationOutput
    trajectory (1,1) struct
    label (1,1) string = "control"
    options.SamplePeriod (1,1) double {mustBePositive} = .1
end
[nominal,meta]=loadZoomSystem;
gap1=simulation.gap1_actual; gap2=simulation.gap2_actual;
% Validate every solver sample, including those not ray-traced below.
allGaps=[gap1.Data(:),gap2.Data(:)];
assert(all(allGaps>=meta.MinGaps-1e-8,'all') && all(sum(allGaps,2)<=meta.MaxGapSum+1e-8), ...
    'zoom:Geometry','A simulated state violates group clearance. Optical evaluation stopped.');
t=(gap1.Time(1):options.SamplePeriod:gap1.Time(end))';
actualGaps=[interp1(gap1.Time,gap1.Data,t),interp1(gap2.Time,gap2.Data,t)];
target=interp1(simulation.focal_target.Time,simulation.focal_target.Data,t,'previous');
commandGaps=interpolateZoomGaps(trajectory,target);
actualFocal=zeros(size(t)); idealFocal=zeros(size(t)); focusOffset=zeros(size(t));
for k=1:numel(t)
    o=configureZoomSystem(nominal,actualGaps(k,:),meta);
    s=evaluateZoomState(o,Rays=true);
    actualFocal(k)=s.FocalLength; focusOffset(k)=s.FocusOffset;
    ideal=configureZoomSystem(nominal,commandGaps(k,:),meta);
    idealFocal(k)=paraxialInfo(ideal).FocalLength;
end
comparison=table(t,target,commandGaps(:,1),actualGaps(:,1),commandGaps(:,2),actualGaps(:,2), ...
    actualFocal,actualFocal-target,idealFocal,actualFocal-idealFocal,focusOffset, ...
    'VariableNames',{'Time_s','TargetFocal_mm','Gap1Command_mm','Gap1Actual_mm', ...
    'Gap2Command_mm','Gap2Actual_mm','ActualFocal_mm','FocalError_mm','IdealFocal_mm','ServoFocalError_mm','FocusOffset_mm'});
writetable(comparison,fullfile(meta.Root,'Results',label+"_optics.csv"));
fig=figure('Name',label+" position control and optics",'Position',[80 60 1200 850],'Color','w');
layout=tiledlayout(fig,3,2,'TileSpacing','compact');
for axis=1:2
    ax=nexttile(layout); plot(ax,t,[commandGaps(:,axis),actualGaps(:,axis)],'LineWidth',1.3);
    grid(ax,'on'); title(ax,sprintf('Gap %d',axis)); ylabel(ax,'Position (mm)'); legend(ax,'Command','Actual');
end
ax=nexttile(layout); plot(ax,t,[target actualFocal],'LineWidth',1.3); grid(ax,'on');
ylabel(ax,'Focal length (mm)'); legend(ax,'Command','Actual');
ax=nexttile(layout); plot(ax,t,actualGaps-commandGaps,'LineWidth',1.2); grid(ax,'on');
ylabel(ax,'Gap error (mm)'); legend(ax,'Gap 1','Gap 2');
ax=nexttile(layout); plot(ax,t,[actualFocal-target actualFocal-idealFocal],'LineWidth',1.2); grid(ax,'on');
ylabel(ax,'Focal error (mm)'); xlabel(ax,'Time (s)'); legend(ax,'Total','Servo contribution');
ax=nexttile(layout); plot(ax,t,focusOffset,'LineWidth',1.2); grid(ax,'on');
ylabel(ax,'Paraxial focus offset (mm)'); xlabel(ax,'Time (s)');
title(layout,label+" | PI servos, first-order actuators, 20 mm/s limit; disturbance at 7–7.5 s");
exportgraphics(fig,fullfile(meta.Root,'Results',label+"_control.png"),'Resolution',150);
savefig(fig,fullfile(meta.Root,'Results',label+"_control.fig"));
close(fig);
plotZoomDisturbance(comparison,label);
fprintf('%s: %d optical samples, peak focal error %.4f mm, final error %.4f mm.\n', ...
    label,height(comparison),max(abs(comparison.FocalError_mm)),comparison.FocalError_mm(end));
end
