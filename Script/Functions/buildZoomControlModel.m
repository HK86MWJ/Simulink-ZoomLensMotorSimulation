function model=buildZoomControlModel(trajectory)
%BUILDZOOMCONTROLMODEL Generate two physical position servos in Simulink.
% Axis 1 displacement = gap1; axis 2 displacement = gap1+gap2.
% The second group also has a fixed offset equal to group 1 thickness.
[~,meta]=loadZoomSystem;
setupZoomProject;
model='ZoomActuatorControl';
if bdIsLoaded(model), close_system(model,0); end
new_system(model);
set_param(model,'Solver','ode4','SolverType','Fixed-step','FixedStep','0.01', ...
    'StopTime','12','ReturnWorkspaceOutputs','on','SaveTime','on');
mw=get_param(model,'ModelWorkspace');
assignin(mw,'focalBreakpoints',trajectory.TargetFocalLength');
assignin(mw,'gap1Table',trajectory.Gaps(:,1)');
assignin(mw,'group2Table',sum(trajectory.Gaps,2)');
assignin(mw,'focalCommand',timeseries([70;70;210;210],[0;1.99;2;12]));
assignin(mw,'disturbance1',timeseries([0;0;.03;.03;0;0],[0;6.99;7;7.49;7.5;12]));
assignin(mw,'disturbance2',timeseries([0;0;-.03;-.03;0;0],[0;6.99;7;7.49;7.5;12]));
assignin(mw,'initial1',trajectory.Gaps(1,1));
assignin(mw,'initial2',sum(trajectory.Gaps(1,:)));
add_block('simulink/Sources/From Workspace',[model '/FocalCommand'], ...
    'VariableName','focalCommand','Interpolate','off','OutputAfterFinalValue','Holding final value','Position',[25 85 140 115]);
add_block('simulink/Discontinuities/Saturation',[model '/FocalRange'], ...
    'LowerLimit','70','UpperLimit','210','Position',[170 80 220 120]);
add_line(model,'FocalCommand/1','FocalRange/1');
tables={'gap1Table','group2Table'};
for axis=1:2
    y=80+(axis-1)*210;
    lookup=sprintf('PositionLookup%d',axis);
    add_block('simulink/Lookup Tables/1-D Lookup Table',[model '/' lookup], ...
        'BreakpointsForDimension1','focalBreakpoints','Table',tables{axis}, ...
        'Position',[275 y 415 y+45]);
    add_line(model,'FocalRange/1',[lookup '/1'],'autorouting','on');
    subsystem=sprintf('Group%dServo',axis);
    createServo([model '/' subsystem],axis,meta,trajectory);
    set_param([model '/' subsystem],'Position',[500 y-10 655 y+90]);
    add_block('simulink/Sources/From Workspace',sprintf('%s/Disturbance%d',model,axis), ...
        'VariableName',sprintf('disturbance%d',axis),'Interpolate','off','OutputAfterFinalValue','Holding final value', ...
        'Position',[285 y+85 415 y+115]);
    add_line(model,[lookup '/1'],[subsystem '/1']);
    add_line(model,sprintf('Disturbance%d/1',axis),[subsystem '/2'],'autorouting','on');
    logSignal(model,[lookup '/1'],sprintf('group%d_command',axis),[710 y-40 865 y-10]);
    logSignal(model,[subsystem '/1'],sprintf('group%d_actual',axis),[710 y+10 865 y+40]);
    logSignal(model,[subsystem '/2'],sprintf('group%d_velocity',axis),[710 y+65 865 y+95]);
end
add_block('simulink/Math Operations/Sum',[model '/Gap2Actual'],'Inputs','+-','Position',[945 205 970 245]);
add_line(model,'Group2Servo/1','Gap2Actual/1','autorouting','on');
add_line(model,'Group1Servo/1','Gap2Actual/2','autorouting','on');
add_block('simulink/Math Operations/Bias',[model '/RemainingGap2Clearance'], ...
    'Bias',num2str(-meta.MinGaps(2),16),'Position',[1000 305 1070 345]);
add_block('simulink/Math Operations/Gain',[model '/ClearanceRate'],'Gain','10','Position',[1110 305 1160 345]);
add_block('simulink/Discontinuities/Saturation',[model '/SafeClosingSpeed'], ...
    'LowerLimit','0','UpperLimit','20','Position',[1200 305 1260 345]);
add_line(model,'Gap2Actual/1','RemainingGap2Clearance/1','autorouting','on');
add_line(model,'RemainingGap2Clearance/1','ClearanceRate/1');
add_line(model,'ClearanceRate/1','SafeClosingSpeed/1');
add_line(model,'SafeClosingSpeed/1','Group1Servo/3','autorouting','on');
add_line(model,'SafeClosingSpeed/1','Group2Servo/3','autorouting','on');
logSignal(model,'Gap2Actual/1','gap2_actual',[1025 205 1145 245]);
logSignal(model,'Group1Servo/1','gap1_actual',[1025 120 1145 155]);
logSignal(model,'FocalRange/1','focal_target',[285 450 415 480]);
annotation=Simulink.Annotation(model, ...
    sprintf('70–210 mm zoom | all lengths in mm\nGroup 1: q1 = gap1; Group 2: q2 = gap1 + gap2\nPI + anti-windup + first-order position actuator + velocity/travel limits\nOptical evaluation is performed offline by syncSimulinkOptics.'));
annotation.Position=[30 540];
formatZoomControlModel(model);
set_param(model,'SimulationCommand','update');
save_system(model,fullfile(meta.Paths.Model,[model '.slx']));
end

function createServo(path,axis,meta,trajectory)
add_block('built-in/Subsystem',path);
if axis==1
    low=meta.MinGaps(1); high=max(trajectory.Gaps(:,1)); tau=.12;
else
    low=min(sum(trajectory.Gaps,2)); high=meta.MaxGapSum; tau=.18;
end
add_block('simulink/Ports & Subsystems/In1',[path '/Command'],'Position',[25 45 55 65]);
add_block('simulink/Ports & Subsystems/In1',[path '/Disturbance'],'Port','2','Position',[420 210 450 230]);
add_block('simulink/Ports & Subsystems/In1',[path '/SafeClosingSpeed'],'Port','3','Position',[590 385 620 405]);
add_block('simulink/Math Operations/Sum',[path '/Error'],'Inputs','+-','Position',[100 40 125 80]);
add_block('simulink/Math Operations/Gain',[path '/Kp'],'Gain','2','Position',[160 35 200 65]);
add_block('simulink/Math Operations/Gain',[path '/Ki'],'Gain','12','Position',[160 105 200 135]);
add_block('simulink/Math Operations/Sum',[path '/IntegralInput'],'Inputs','++','Position',[245 100 270 140]);
add_block('simulink/Continuous/Integrator',[path '/PIIntegral'],'InitialCondition',sprintf('initial%d',axis),'Position',[300 100 335 130]);
add_block('simulink/Math Operations/Sum',[path '/Control'],'Inputs','++','Position',[370 35 395 75]);
add_block('simulink/Discontinuities/Saturation',[path '/TravelCommandLimit'], ...
    'LowerLimit',num2str(low,16),'UpperLimit',num2str(high,16),'Position',[430 35 480 75]);
add_block('simulink/Math Operations/Sum',[path '/AntiWindupError'],'Inputs','+-','Position',[365 285 390 320]);
add_block('simulink/Math Operations/Gain',[path '/AntiWindupGain'],'Gain','15','Position',[235 285 275 315]);
add_block('simulink/Math Operations/Sum',[path '/PlantError'],'Inputs','++-','Position',[525 40 550 100]);
add_block('simulink/Math Operations/Gain',[path '/InverseTau'],'Gain',num2str(1/tau,16),'Position',[590 45 635 75]);
add_block('simulink/Discontinuities/Saturation',[path '/VelocityLimit'],'LowerLimit','-20','UpperLimit','20','Position',[680 40 730 80]);
add_block('simulink/Discontinuities/Saturation Dynamic',[path '/GapInterlock'],'Position',[765 135 810 185]);
add_block('simulink/Sources/Constant',[path '/FreeDirectionLimit'],'Value',num2str(20*(2*axis-3)), ...
    'Position',[655 270 695 300]);
if axis==1
    add_line(path,'SafeClosingSpeed/1','GapInterlock/1','autorouting','on');
    add_line(path,'FreeDirectionLimit/1','GapInterlock/3','autorouting','on');
else
    add_block('simulink/Math Operations/Gain',[path '/NegativeClosingSpeed'],'Gain','-1','Position',[685 385 725 415]);
    add_line(path,'SafeClosingSpeed/1','NegativeClosingSpeed/1');
    add_line(path,'FreeDirectionLimit/1','GapInterlock/1','autorouting','on');
    add_line(path,'NegativeClosingSpeed/1','GapInterlock/3','autorouting','on');
end
add_block('simulink/Continuous/Integrator',[path '/Position'],'InitialCondition',sprintf('initial%d',axis), ...
    'LimitOutput','on','LowerSaturationLimit',num2str(low,16),'UpperSaturationLimit',num2str(high,16),'Position',[780 40 815 80]);
add_block('simulink/Ports & Subsystems/Out1',[path '/ActualPosition'],'Position',[900 45 930 65]);
add_block('simulink/Ports & Subsystems/Out1',[path '/ActualVelocity'],'Port','2','Position',[900 160 930 180]);
connections={ 'Command/1','Error/1';'Position/1','Error/2';'Error/1','Kp/1'; ...
    'Error/1','Ki/1';'Ki/1','IntegralInput/1';'IntegralInput/1','PIIntegral/1'; ...
    'Kp/1','Control/1';'PIIntegral/1','Control/2';'Control/1','TravelCommandLimit/1'; ...
    'TravelCommandLimit/1','AntiWindupError/1';'Control/1','AntiWindupError/2'; ...
    'AntiWindupError/1','AntiWindupGain/1';'AntiWindupGain/1','IntegralInput/2'; ...
    'TravelCommandLimit/1','PlantError/1';'Disturbance/1','PlantError/2'; ...
    'Position/1','PlantError/3';'PlantError/1','InverseTau/1';'InverseTau/1','VelocityLimit/1'; ...
    'VelocityLimit/1','GapInterlock/2';'GapInterlock/1','Position/1'; ...
    'Position/1','ActualPosition/1';'GapInterlock/1','ActualVelocity/1'};
for k=1:size(connections,1), add_line(path,connections{k,1},connections{k,2},'autorouting','on'); end
end

function logSignal(model,source,name,position)
add_block('simulink/Sinks/To Workspace',[model '/' name],'VariableName',name, ...
    'SaveFormat','Timeseries','Position',position);
add_line(model,source,[name '/1'],'autorouting','on');
end
