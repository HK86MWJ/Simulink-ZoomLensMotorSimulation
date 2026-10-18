function app=main_zoom_demo()
%MAIN_ZOOM_DEMO Open the interactive optical zoom demo.
%   app = main_zoom_demo;  delete(app) closes the UI and its timer.
setupZoomProject;
setupZoomAssets;
trajectory=precomputeZoomTrajectory;
app=ZoomDemoApp(trajectory);
if nargout==0, assignin('base','zoomDemoApp',app); end
end
