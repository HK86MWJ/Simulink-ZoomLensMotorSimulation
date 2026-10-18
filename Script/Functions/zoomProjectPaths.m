function paths=zoomProjectPaths()
%ZOOMPROJECTPATHS Resolve project folders independently of the current folder.
paths.Root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
paths.Script=fullfile(paths.Root,'Script');
paths.Functions=fullfile(paths.Script,'Functions');
paths.Official=fullfile(paths.Functions,'Official');
paths.Examples=fullfile(paths.Script,'Examples','Official');
paths.Tests=fullfile(paths.Script,'Tests');
paths.Model=fullfile(paths.Root,'Model');
paths.Results=fullfile(paths.Root,'Results');
paths.Cache=fullfile(paths.Root,'Cache');
paths.Docs=fullfile(paths.Root,'Docs');
end
