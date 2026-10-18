function [viewer,state]=drawZoomFrame(parent,previous,nominal,meta,gaps,target)
%DRAWZOOMFRAME Render exactly one chart; never accumulate charts or ray sets.
[o,geometry]=configureZoomSystem(nominal,gaps,meta);
state=evaluateZoomState(o);
if ~isempty(previous) && isvalid(previous), delete(previous); end
viewer=view2d(o,Parent=parent,Labels="component", ...
    Title=sprintf('Target %.1f mm  |  Actual %.3f mm  |  F/%.2f\ngap1 %.3f mm  |  gap2 %.3f mm  |  sensor Z %.4f mm', ...
    target,state.FocalLength,state.FNumber,gaps(1),gaps(2),meta.FixedImagePlaneZ));
viewer.ZLim=[-15 195]; viewer.YLim=[-33 33];
addRays(viewer,state.Rays);
state.Geometry=geometry;
drawnow;
end
