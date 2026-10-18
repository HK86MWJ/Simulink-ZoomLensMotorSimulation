function [trajectory,complete]=precomputeZoomTrajectory(options)
%PRECOMPUTEZOOMTRAJECTORY Optimize the 29 states and cache verified results.
arguments
    options.Force (1,1) logical = false
    options.BatchSize (1,1) double {mustBePositive} = Inf
end
[nominal,meta]=loadZoomSystem;
complete=true;
folder=fullfile(meta.Root,'Cache');
if ~isfolder(folder), mkdir(folder); end
file=fullfile(folder,'zoom_trajectory.mat');
if isfile(file) && ~options.Force
    data=load(file,'trajectory');
    trajectory=data.trajectory;
    if isequal(trajectory.HelperSource,meta.HelperSource) && ...
            trajectory.SchemaVersion==meta.SchemaVersion && ...
            isequal(trajectory.MinGaps,meta.MinGaps) && ...
            strcmp(trajectory.MATLABVersion,version)
        return
    end
end
assert(license('test','Optimization_Toolbox'),'zoom:Dependency','Optimization Toolbox is required to build the trajectory.');
targets=(70:5:210)';
n=numel(targets);
gaps=zeros(n,2); actual=zeros(n,1); rms=zeros(n,1);
exitflags=zeros(n,1); iterations=zeros(n,1); elapsed=zeros(n,1);
focalWeights=ones(n,1);
opts=optimoptions('fmincon','Display','off','Algorithm','sqp', ...
    'FiniteDifferenceStepSize',1e-4,'StepTolerance',1e-7, ...
    'OptimalityTolerance',1e-5,'ConstraintTolerance',1e-8, ...
    'MaxIterations',100,'MaxFunctionEvaluations',600);
x=meta.NominalGaps;
checkpointFile=fullfile(folder,'zoom_checkpoint.mat');
first=1;
if isfile(checkpointFile) && ~options.Force
    checkpoint=load(checkpointFile);
    if isequal(checkpoint.helperSource,meta.HelperSource) && strcmp(checkpoint.matlabVersion,version)
        gaps=checkpoint.gaps; actual=checkpoint.actual; rms=checkpoint.rms;
        exitflags=checkpoint.exitflags; iterations=checkpoint.iterations; elapsed=checkpoint.elapsed;
        if isfield(checkpoint,'focalWeights'), focalWeights=checkpoint.focalWeights; end
        first=checkpoint.k+1;
        x=gaps(checkpoint.k,:);
    end
end
helperSource=meta.HelperSource;
matlabVersion=version;
k=first-1;
for k=first:min(n,first+options.BatchSize-1)
    timerValue=tic;
    fun=@(candidate) merit(candidate,nominal,meta,targets(k),1);
    [x,~,exitflags(k),output]=fmincon(fun,x,[1 1],meta.MaxGapSum,[],[], ...
        meta.MinGaps,[],[],opts);
    configured=configureZoomSystem(nominal,x,meta);
    state=evaluateZoomState(configured,Rays=false,Spot=true);
    if abs(state.FocalLength-targets(k))>=0.25
        % At the tele limit, spot quality competes with exact focal length.
        % Keep the geometry constraints; increase focal priority explicitly.
        focalWeights(k)=100;
        fun=@(candidate) merit(candidate,nominal,meta,targets(k),focalWeights(k));
        [x,~,exitflags(k),output]=fmincon(fun,x,[1 1],meta.MaxGapSum,[],[], ...
            meta.MinGaps,[],[],opts);
        configured=configureZoomSystem(nominal,x,meta);
        state=evaluateZoomState(configured,Rays=false,Spot=true);
    end
    assert(exitflags(k)>0 && abs(state.FocalLength-targets(k))<0.25, ...
        'zoom:Optimization','Optimization did not meet focal tolerance at %.1f mm (actual %.6f, exit %d).', ...
        targets(k),state.FocalLength,exitflags(k));
    gaps(k,:)=x; actual(k)=state.FocalLength; rms(k)=state.SpotRMS;
    iterations(k)=output.iterations; elapsed(k)=toc(timerValue);
    save(checkpointFile,'gaps','actual','rms','exitflags','iterations','elapsed','k','helperSource','matlabVersion','focalWeights');
    logFile=fopen(fullfile(meta.Root,'Results','optimization_progress.log'),'a');
    fprintf(logFile,'%s %2d/29 target=%.1f actual=%.6f gaps=[%.6f %.6f] rms=%.6f exit=%d time=%.2fs\n', ...
        char(datetime('now')),k,targets(k),actual(k),x(1),x(2),rms(k),exitflags(k),elapsed(k));
    fclose(logFile);
    fprintf('%2d/29 target=%6.1f actual=%10.6f gap=[%9.5f %9.5f] RMS=%8.5f mm (%5.1fs)\n', ...
        k,targets(k),actual(k),x(1),x(2),rms(k),elapsed(k));
end
if k<n
    trajectory=[];
    complete=false;
    return
end
trajectory=struct('TargetFocalLength',targets,'Gaps',gaps,'ActualFocalLength',actual, ...
    'SpotRMS',rms,'ExitFlag',exitflags,'Iterations',iterations,'ElapsedSeconds',elapsed,'FocalWeight',focalWeights, ...
    'HelperSource',meta.HelperSource,'SchemaVersion',meta.SchemaVersion, ...
    'MinGaps',meta.MinGaps,'MATLABVersion',version,'Created',char(datetime('now')));
save(file,'trajectory');
writetable(table(targets,gaps(:,1),gaps(:,2),actual,actual-targets,rms,exitflags,iterations,elapsed,focalWeights, ...
    'VariableNames',{'Target_mm','Gap1_mm','Gap2_mm','Actual_mm','Error_mm','SpotRMS_mm','ExitFlag','Iterations','Seconds','FocalWeight'}), ...
    fullfile(meta.Root,'Results','zoom_trajectory.csv'));
end

function value=merit(gaps,nominal,meta,target,focalWeight)
% Smooth focal residual plus RMS penalty, at the official primary wavelength.
try
    o=configureZoomSystem(nominal,gaps,meta);
    s=evaluateZoomState(o,Rays=false,Spot=true);
    value=focalWeight*(s.FocalLength-target)^2+(10*s.SpotRMS)^2;
catch exception
    if startsWith(exception.identifier,'zoom:Geometry')
        value=1e10;
    else
        rethrow(exception)
    end
end
end
