function tests=testZoomModel
tests=functiontests(localfunctions);
end

function setupOnce(testCase)
scriptFolder=fileparts(fileparts(mfilename('fullpath')));
addpath(scriptFolder);
setupZoomProject;
[testCase.TestData.Nominal,testCase.TestData.Meta]=loadZoomSystem;
testCase.TestData.Trajectory=precomputeZoomTrajectory;
end

function testOfficialPrescription(testCase)
o=testCase.TestData.Nominal;
verifyEqual(testCase,numel(o.Components),13);
verifyEqual(testCase,height(o.SurfaceTable),27);
verifyEqual(testCase,paraxialInfo(o).FocalLength,72.0158,'AbsTol',1e-3);
end

function testAllOptimizedAndIntermediateStates(testCase)
data=testCase.TestData;
for target=70:2.5:210
    gaps=interpolateZoomGaps(data.Trajectory,target);
    [o,geometry]=configureZoomSystem(data.Nominal,gaps,data.Meta);
    verifyGreaterThanOrEqual(testCase,geometry.SurfaceClearances,data.Meta.Clearance-1e-8);
    verifyLessThan(testCase,abs(paraxialInfo(o).FocalLength-target),.25);
    positions=vertcat(o.Components.Position);
    verifyEqual(testCase,positions([1 2 13],:),data.Meta.NominalPositions([1 2 13],:),'AbsTol',1e-9);
    for group={3:4,5:12}
        idx=group{1};
        verifyEqual(testCase,positions(idx,:)-positions(idx(1),:), ...
            data.Meta.NominalPositions(idx,:)-data.Meta.NominalPositions(idx(1),:),'AbsTol',1e-9);
    end
end
verifyEqual(testCase,vertcat(data.Nominal.Components.Position),data.Meta.NominalPositions);
end

function testInvalidAndIntersectingStates(testCase)
data=testCase.TestData;
verifyError(testCase,@() configureZoomSystem(data.Nominal,[-1 10],data.Meta),'zoom:Geometry');
verifyError(testCase,@() configureZoomSystem(data.Nominal,[10 -1],data.Meta),'zoom:Geometry');
verifyError(testCase,@() configureZoomSystem(data.Nominal,[50 50],data.Meta),'zoom:Geometry');
% Positive vertex gap, but the spherical surfaces collide at their edges.
verifyError(testCase,@() configureZoomSystem(data.Nominal,[1 10],data.Meta),'zoom:Geometry');
end

function testCopyIsolationAndReproducibility(testCase)
data=testCase.TestData;
g=interpolateZoomGaps(data.Trajectory,140);
a=configureZoomSystem(data.Nominal,g,data.Meta);
b=configureZoomSystem(data.Nominal,g,data.Meta);
verifyEqual(testCase,paraxialInfo(a).FocalLength,paraxialInfo(b).FocalLength,'AbsTol',1e-10);
a.Components(3).Position(3)=a.Components(3).Position(3)+.1;
verifyNotEqual(testCase,a.Components(3).Position,b.Components(3).Position);
verifyEqual(testCase,vertcat(data.Nominal.Components.Position),data.Meta.NominalPositions);
end

function testInterpolationRejectsOutOfRange(testCase)
trajectory=testCase.TestData.Trajectory;
verifyTrue(testCase,throws(@() interpolateZoomGaps(trajectory,69)));
verifyTrue(testCase,throws(@() interpolateZoomGaps(trajectory,211)));
verifyTrue(testCase,throws(@() interpolateZoomGaps(trajectory,NaN)));
end

function testControlArtifacts(testCase)
data=testCase.TestData;
verifyTrue(testCase,isfile(fullfile(data.Meta.Paths.Model,'ZoomActuatorControl.slx')));
for scenario=["step","sweep"]
    loaded=load(fullfile(data.Meta.Root,'Results',scenario+"_simulink.mat"),'simulation');
    s=loaded.simulation;
    gaps=[s.gap1_actual.Data(:) s.gap2_actual.Data(:)];
    verifyTrue(testCase,all(gaps>=data.Meta.MinGaps-1e-8,'all'));
    verifyLessThanOrEqual(testCase,sum(gaps,2),data.Meta.MaxGapSum+1e-8);
    verifyLessThanOrEqual(testCase,max(abs(diff(s.group1_actual.Data)./diff(s.group1_actual.Time))),20+1e-6);
    verifyLessThanOrEqual(testCase,max(abs(diff(s.group2_actual.Data)./diff(s.group2_actual.Time))),20+1e-6);
    comparison=readtable(fullfile(data.Meta.Root,'Results',scenario+"_optics.csv"));
    verifyTrue(testCase,all(isfinite(comparison.ActualFocal_mm)));
    if scenario=="step"
        verifyLessThan(testCase,abs(comparison.FocalError_mm(end)),.25);
        verifyGreaterThan(testCase,max(abs(comparison.FocalError_mm)),10);
    end
end
end

function yes=throws(fun)
try
    fun(); yes=false;
catch
    yes=true;
end
end
