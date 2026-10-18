function info=exportZoomAnimation(filename,trajectory,options)
%EXPORTZOOMANIMATION Export a deterministic >=10-second wide/tele/wide sweep.
arguments
    filename (1,1) string
    trajectory (1,1) struct
    options.Duration (1,1) double {mustBeGreaterThanOrEqual(options.Duration,10)} = 12
    options.FrameRate (1,1) double {mustBePositive} = 10
end
[nominal,meta]=loadZoomSystem;
fig=figure('Name','Zoom lens movie export','NumberTitle','off', ...
    'Position',[80 80 1200 500],'Color','w','MenuBar','none','ToolBar','none','Resize','off');
figureCleanup=onCleanup(@() closeIfValid(fig));
writer=VideoWriter(filename,'MPEG-4'); writer.FrameRate=options.FrameRate;
writer.Quality=95; open(writer);
videoCleanup=onCleanup(@() close(writer));
count=ceil(options.Duration*options.FrameRate);
times=(0:count-1)'/options.FrameRate;
targets=140-70*cos(2*pi*(0:count-1)'/(count-1));
viewer=[]; actual=zeros(count,1);
for k=1:count
    [viewer,s]=drawZoomFrame(fig,viewer,nominal,meta,interpolateZoomGaps(trajectory,targets(k)),targets(k));
    actual(k)=s.FocalLength;
    writeVideo(writer,getframe(fig));
    if mod(k,20)==0, fprintf('Movie frame %d/%d\n',k,count); end
end
clear videoCleanup
reader=VideoReader(filename);
assert(reader.Duration>=10-1e-6,'zoom:Video','Exported movie is too short.');
info=struct('File',filename,'Duration',reader.Duration,'FrameRate',reader.FrameRate, ...
    'FrameCount',count,'MaxFocalError',max(abs(actual-targets)));
[folder,name]=fileparts(filename);
writetable(table(times,targets,actual,'VariableNames',{'Time_s','Target_mm','Actual_mm'}),fullfile(folder,name+"_frames.csv"));
fprintf('Exported %s: %.2f s, %d frames.\n',filename,info.Duration,count);
end

function closeIfValid(fig)
if isgraphics(fig), close(fig); end
end
