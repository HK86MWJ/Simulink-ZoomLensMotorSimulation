function results=runZoomControlDemo(trajectory)
%RUNZOOMCONTROLDEMO Simulate step/sweep commands plus position disturbances.
paths=setupZoomProject;
if nargin==0, trajectory=precomputeZoomTrajectory; end
model=buildZoomControlModel(trajectory);
root=paths.Root;
for scenario=["step","sweep"]
    if scenario=="step"
        t=[0;1.99;2;12]; f=[70;70;210;210];
    else
        t=(0:.01:12)'; f=140-70*cos(2*pi*t/12);
    end
    input=Simulink.SimulationInput(model);
    input=input.setVariable('focalCommand',timeseries(f,t),'Workspace',model);
    simulation=sim(input);
    save(fullfile(root,'Results',scenario+"_simulink.mat"),'simulation');
    comparison=syncSimulinkOptics(simulation,trajectory,scenario);
    results.(scenario)=comparison;
end
end
