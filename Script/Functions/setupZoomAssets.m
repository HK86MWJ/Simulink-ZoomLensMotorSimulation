function setupZoomAssets()
%SETUPZOOMASSETS Download the official example into this project.
paths=zoomProjectPaths;
folder=paths.Official;
if ~isfile(fullfile(folder,'createPhotoZoom.m'))
    openExample('optics/OptimizePhotographicZoomLensComponentPositionsExample',workDir=paths.Examples);
    if ~isfolder(folder), mkdir(folder); end
    movefile(fullfile(paths.Examples,'createPhotoZoom.m'),fullfile(folder,'createPhotoZoom.m'));
end
assert(isfile(fullfile(folder,'createPhotoZoom.m')),'zoom:Asset','Official helper is missing.');
addpath(folder);
end
