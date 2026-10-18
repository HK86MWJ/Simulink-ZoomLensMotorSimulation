function [opsys, meta] = loadZoomSystem()
%LOADZOOMSYSTEM Load the unmodified MathWorks photographic zoom prescription.
paths = zoomProjectPaths;
root = paths.Root;
assert(~verLessThan('matlab','26.2'), 'zoom:Release', 'MATLAB R2026b or newer is required.');
assert(exist('opticalSystem','class') == 8, 'zoom:Dependency', ...
    'Install Image Processing Toolbox Optical Design and Simulation Library.');
asset = paths.Official;
assert(isfile(fullfile(asset,'createPhotoZoom.m')), 'zoom:Asset', ...
    'Run setupZoomAssets to obtain the official helper.');
addpath(asset);
opsys = createPhotoZoom;
t = opsys.SurfaceTable;
assert(height(t)==27 && numel(opsys.Components)==13, 'zoom:Prescription', ...
    'The official prescription must contain 27 surfaces and 13 components.');
meta.Root = root;
meta.Paths = paths;
meta.FixedImagePlaneZ = t.Position(end,3);
meta.NominalPositions = vertcat(opsys.Components.Position);
meta.NominalSurfacePositions = t.Position;
meta.NominalGaps = [distanceAfter(opsys,2), distanceAfter(opsys,4)];
meta.TotalFreeSpace = t.Position(27,3)-t.Position(5,3) ...
    -(t.Position(11,3)-t.Position(6,3))-(t.Position(26,3)-t.Position(12,3));
% Exact radial edge clearance for the coaxial spherical group boundaries.
% The sag difference is monotonic in radius for these spherical surfaces.
pairs = [5 6;11 12;26 27];
meta.SagAllowance = zeros(1,3);
for k=1:3
    a=pairs(k,1); b=pairs(k,2);
    radius=min(t.Shape{a},t.Shape{b});
    meta.SagAllowance(k)=max(0,surfaceSag(t.Radius(a),radius)-surfaceSag(t.Radius(b),radius));
end
meta.Clearance = 0.05; % mm; optical surfaces only, no mechanical barrel model
meta.MinGaps = max([1 0],meta.SagAllowance(1:2)+meta.Clearance);
meta.MaxGapSum = meta.TotalFreeSpace-meta.SagAllowance(3)-meta.Clearance;
meta.PrimaryWavelength = opsys.PrimaryWavelength;
meta.HelperSource = fileread(fullfile(asset,'createPhotoZoom.m'));
meta.SchemaVersion = 1;
end

function z=surfaceSag(r,y)
if r==0 || isinf(r)
    z=0;
else
    z=sign(r)*y.^2/(abs(r)+sqrt(r*r-y.^2));
end
end
