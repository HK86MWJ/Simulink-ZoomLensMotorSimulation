function summary=exportZoomSnapshots(trajectory)
%EXPORTZOOMSNAPSHOTS Save wide, middle, tele states and numerical measurements.
[nominal,meta]=loadZoomSystem;
target=[70;140;210];
gaps=interpolateZoomGaps(trajectory,target);
actual=zeros(3,1); rms=zeros(3,1); fnumber=zeros(3,1); focus=zeros(3,1);
for k=1:3
    o=configureZoomSystem(nominal,gaps(k,:),meta);
    state=evaluateZoomState(o,Spot=true);
    actual(k)=state.FocalLength; rms(k)=state.SpotRMS;
    fnumber(k)=state.FNumber; focus(k)=state.FocusOffset;
    fig=figure('Position',[80 80 1200 500],'Color','w');
    drawZoomFrame(fig,[],nominal,meta,gaps(k,:),target(k));
    exportgraphics(fig,fullfile(meta.Root,'Results',sprintf('zoom_%03dmm.png',target(k))),'Resolution',150);
    close(fig);
    fig=figure('Position',[100 100 650 550],'Color','w');
    show(spot(o,Wavelengths=o.PrimaryWavelength),Parent=fig);
    exportgraphics(fig,fullfile(meta.Root,'Results',sprintf('spot_%03dmm.png',target(k))),'Resolution',150);
    close(fig);
end
summary=table(target,gaps(:,1),gaps(:,2),actual,actual-target,rms,fnumber,focus, ...
    'VariableNames',{'Target_mm','Gap1_mm','Gap2_mm','Actual_mm','Error_mm','SpotRMS_mm','FNumber','FocusOffset_mm'});
writetable(summary,fullfile(meta.Root,'Results','representative_states.csv'));
disp(summary);
end
