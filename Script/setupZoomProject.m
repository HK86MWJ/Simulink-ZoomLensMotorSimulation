function paths=setupZoomProject()
%SETUPZOOMPROJECT Set session paths and keep generated files in this project.
scriptFolder=fileparts(mfilename('fullpath'));
root=fileparts(scriptFolder);
addpath(scriptFolder,fullfile(scriptFolder,'Functions'), ...
    fullfile(scriptFolder,'Functions','Official'),fullfile(root,'Model'));
paths=zoomProjectPaths;
for folder={paths.Results,paths.Cache,paths.Model}
    if ~isfolder(folder{1}), mkdir(folder{1}); end
end
if ~isempty(which('Simulink.fileGenControl'))
    Simulink.fileGenControl('set','CacheFolder',paths.Cache, ...
        'CodeGenFolder',fullfile(paths.Cache,'codegen'),'createDir',true);
end
end
