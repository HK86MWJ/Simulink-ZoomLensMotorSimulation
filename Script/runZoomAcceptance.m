function report=runZoomAcceptance(options)
%RUNZOOMACCEPTANCE Reproduce all optical, control, UI and video evidence.
arguments
    options.ExportVideo (1,1) logical = true
end
paths=setupZoomProject;
root=paths.Root;
if ~isfolder(fullfile(root,'Results')), mkdir(fullfile(root,'Results')); end
report.Environment=version;
report.Timestamp=char(datetime('now'));
trajectory=precomputeZoomTrajectory;
report.Snapshots=exportZoomSnapshots(trajectory);
report.Control=runZoomControlDemo(trajectory);
testResults=runtests(paths.Tests);
report.Tests=table(testResults);
report.Tests=report.Tests(:,{'Name','Passed','Failed','Incomplete','Duration'});
writetable(report.Tests,fullfile(root,'Results','test_results.csv'));
assertSuccess(testResults);
app=ZoomDemoApp(trajectory);
cleanup=onCleanup(@() delete(app));
app.PlayButton.Value=true; app.toggle();
startTime=tic;
while toc(startTime)<12
    pause(.1);
end
app.stop();
report.UIPlaybackWallSeconds=toc(startTime);
report.UIFrameCount=app.FrameCount;
assert(app.FrameCount>2 && strlength(app.LastError)==0,'zoom:UI','UI playback did not complete successfully.');
app.seek(140);
assert(numel(findall(app.Figure,'-isa','optics.ui.OpticalSystemViewer2D'))==1, ...
    'zoom:UI','UI accumulated optical viewer charts.');
exportapp(app.Figure,fullfile(root,'Results','zoom_app.png'));
if options.ExportVideo
    report.Video=exportZoomAnimation(fullfile(root,'Results','zoom_animation.mp4'),trajectory);
end
save(fullfile(root,'Results','acceptance_report.mat'),'report');
fprintf('Acceptance complete. %d tests passed. UI playback %.2f seconds.\n', ...
    sum([testResults.Passed]),report.UIPlaybackWallSeconds);
end
