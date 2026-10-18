function formatZoomControlModel(model)
%FORMATZOOMCONTROLMODEL Apply a repeatable layout without changing dynamics.
%   Operates on the loaded model; the caller decides when to save it.
if nargin==0, model='ZoomActuatorControl'; end
load_system(model);
addClosingSpeedTags(model);
blue='[0.88 0.94 1]'; green='[0.88 0.96 0.90]';
amber='[1 0.95 0.82]'; purple='[0.94 0.90 0.98]'; grey='[0.95 0.95 0.95]';
systems={model,[model '/Group1Servo'],[model '/Group2Servo']};
for k=1:numel(systems)
    sys=systems{k};
    blocks=find_system(sys,'SearchDepth',1,'Type','Block');
    blocks(strcmp(blocks,sys))=[];
    for j=1:numel(blocks)
        set_param(blocks{j},'FontName','Arial','FontSize','12', ...
            'FontWeight','normal','ForegroundColor','black','BackgroundColor','white', ...
            'ShowName','on','DropShadow','off','Orientation','right');
        if strcmp(get_param(blocks{j},'BlockType'),'Sum')
            set_param(blocks{j},'IconShape','rectangular');
        end
    end
    annotations=find_system(sys,'FindAll','on','SearchDepth',1,'Type','annotation');
    for j=1:numel(annotations)
        if strcmp(get_param(annotations(j),'Tag'),'ZoomLayout')
            delete(annotations(j));
        end
    end
    set_param(sys,'ZoomFactor','FitSystem');
end
place(model,'FocalCommand',[40 325 185 365],purple);
place(model,'FocalRange',[235 325 290 365],amber);
place(model,'focal_target',[45 440 235 478],grey,'left');
for axis=1:2
    dy=(axis-1)*275;
    place(model,sprintf('PositionLookup%d',axis),[365 175+dy 525 205+dy],blue);
    place(model,sprintf('Disturbance%d',axis),[365 230+dy 525 260+dy],purple);
    place(model,sprintf('Group%dServo',axis),[670 165+dy 855 325+dy],green);
    place(model,sprintf('group%d_command',axis),[365 110+dy 525 150+dy],grey,'left');
    place(model,sprintf('group%d_actual',axis),[985 185+dy 1190 225+dy],grey);
    place(model,sprintf('group%d_velocity',axis),[985 265+dy 1190 305+dy],grey);
    place(model,sprintf('ClosingSpeedFrom%d',axis),[465 285+dy 615 315+dy],amber);
    set_param([model sprintf('/ClosingSpeedFrom%d',axis)],'ShowName','off');
    formatServo([model sprintf('/Group%dServo',axis)],axis);
end
place(model,'gap1_actual',[1285 185 1485 225],grey);
place(model,'Gap2Actual',[1420 830 1455 890],blue,'left');
place(model,'gap2_actual',[1210 935 1380 975],grey,'left');
place(model,'RemainingGap2Clearance',[1190 830 1380 890],amber,'left');
place(model,'ClearanceRate',[1005 830 1100 890],amber,'left');
place(model,'SafeClosingSpeed',[790 830 925 890],amber,'left');
place(model,'ClosingSpeedGoto',[550 840 730 880],amber,'left');
set_param([model '/ClosingSpeedGoto'],'ShowName','off');
note(model,'ZOOM POSITION CONTROL | 70-210 mm',[40 20],18,true);
note(model,'FOCAL COMMAND',[40 85],13,true);
note(model,'POSITION REFERENCES',[365 85],13,true);
note(model,'TWO PHYSICAL AXES',[670 85],13,true);
note(model,'LOGGED SIGNALS',[985 40],13,true);
note(model,'GROUP CLEARANCE INTERLOCK  |  q2 - q1',[790 775],13,true);
note(model,'safe_close_v [mm/s]: same local signal at both servo inputs',[365 720],12,false);
note(model,'q1 = gap1     q2 = gap1 + gap2     gap2 = q2 - q1',[365 1015],12,false);
note(model,'Blue: reference / PI    Green: actuator    Amber: limits    Purple: inputs    Grey: logs', ...
    [365 1050],11,false);
% Retain the original model description, moving it below the signal diagram.
annotations=find_system(model,'FindAll','on','SearchDepth',1,'Type','annotation');
for j=1:numel(annotations)
    if ~strcmp(get_param(annotations(j),'Tag'),'ZoomLayout')
        a=get_param(annotations(j),'Object');
        a.Position=[40 1115]; a.FontSize=11;
    end
end
routeTop(model);
for axis=1:2
    sys=[model sprintf('/Group%dServo',axis)];
    routeServo(sys,axis);
end
% Explicit branch points must survive saving and regeneration. No automatic
% routing pass is applied after the nets below have been drawn.
for k=1:numel(systems), set_param(systems{k},'ZoomFactor','FitSystem'); end
end

function formatServo(sys,axis)
blue='[0.88 0.94 1]'; green='[0.88 0.96 0.90]';
amber='[1 0.95 0.82]'; purple='[0.94 0.90 0.98]';
place(sys,'Command',[35 200 65 220],purple);
place(sys,'Error',[145 190 175 230],blue);
place(sys,'Kp',[240 190 300 230],blue);
place(sys,'Ki',[240 305 300 345],blue);
place(sys,'IntegralInput',[350 315 385 355],blue);
place(sys,'PIIntegral',[440 315 490 355],blue);
place(sys,'Control',[570 190 605 230],blue);
place(sys,'TravelCommandLimit',[685 185 790 235],amber);
place(sys,'AntiWindupError',[575 425 610 465],blue,'left');
place(sys,'AntiWindupGain',[390 425 460 465],blue,'left');
place(sys,'Disturbance',[740 100 770 120],purple);
place(sys,'PlantError',[850 180 885 240],green);
place(sys,'InverseTau',[925 190 985 230],green);
place(sys,'VelocityLimit',[1045 185 1135 235],amber);
place(sys,'GapInterlock',[1205 180 1260 240],amber);
place(sys,'Position',[1325 190 1375 230],green);
place(sys,'ActualPosition',[1480 200 1510 220],green);
place(sys,'ActualVelocity',[1330 320 1360 340],green);
if axis==1
    place(sys,'SafeClosingSpeed',[1045 100 1075 120],purple);
    place(sys,'FreeDirectionLimit',[1090 335 1150 375],amber);
else
    place(sys,'FreeDirectionLimit',[1090 100 1150 140],amber);
    place(sys,'SafeClosingSpeed',[905 355 935 375],purple);
    place(sys,'NegativeClosingSpeed',[1090 345 1150 385],amber);
end
note(sys,sprintf('GROUP %d POSITION SERVO',axis),[35 20],18,true);
note(sys,'PI CONTROLLER',[240 65],13,true);
note(sys,'ACTUATOR',[800 35],13,true);
note(sys,'VELOCITY / CLEARANCE LIMITS',[1040 35],13,true);
note(sys,'POSITION',[1330 65],13,true);
note(sys,'Integral path',[240 285],11,false);
note(sys,'Anti-windup: limited command - raw command',[350 520],11,false);
note(sys,'Position feedback',[45 605],11,false);
if axis==1
    label='q1 = gap1 | tau = 0.12 s | position: mm | velocity: mm/s';
else
    label='q2 = gap1 + gap2 | tau = 0.18 s | position: mm | velocity: mm/s';
end
note(sys,label,[35 655],12,false);
end

function place(sys,name,position,color,orientation)
if nargin<5, orientation='right'; end
set_param([sys '/' name],'Position',position,'BackgroundColor',color,'Orientation',orientation);
end

function note(sys,text,position,size,bold)
a=Simulink.Annotation(sys,text);
a.Tag='ZoomLayout'; a.Position=position;
a.FontName='Arial'; a.FontSize=size;
a.ForegroundColor='[0.13 0.20 0.30]';
if bold, a.FontWeight='bold'; end
end

function addClosingSpeedTags(model)
% Local Goto/From blocks carry the same scalar with no delay or arithmetic.
if getSimulinkBlockHandle([model '/ClosingSpeedGoto'])~=-1, return; end
p=get_param([model '/SafeClosingSpeed'],'PortHandles');
line=get_param(p.Outport(1),'Line');
dest=get_param(line,'DstPortHandle');
expected=zeros(2,1);
for axis=1:2
    q=get_param([model sprintf('/Group%dServo',axis)],'PortHandles');
    expected(axis)=q.Inport(3);
end
assert(isequal(sort(dest(:)),sort(expected)), ...
    'zoom:LayoutConnections','Unexpected closing-speed connections.');
delete_line(line);
add_block('simulink/Signal Routing/Goto',[model '/ClosingSpeedGoto'], ...
    'GotoTag','safe_close_v','TagVisibility','local');
add_line(model,'SafeClosingSpeed/1','ClosingSpeedGoto/1');
for axis=1:2
    block=sprintf('ClosingSpeedFrom%d',axis);
    add_block('simulink/Signal Routing/From',[model '/' block],'GotoTag','safe_close_v');
    add_line(model,[block '/1'],sprintf('Group%dServo/3',axis));
end
end

function routeTop(sys)
net(sys,'FocalCommand/1',{'FocalRange/1',[]});
net(sys,'FocalRange/1',{ ...
    'PositionLookup1/1',[320 345;320 190]; ...
    'PositionLookup2/1',[320 345;320 465]; ...
    'focal_target/1',[305 345;305 460]});
for axis=1:2
    dy=(axis-1)*275;
    net(sys,sprintf('PositionLookup%d/1',axis),{ ...
        sprintf('Group%dServo/1',axis),[]; ...
        sprintf('group%d_command/1',axis),[550 190+dy;550 130+dy]});
    net(sys,sprintf('Disturbance%d/1',axis),{sprintf('Group%dServo/2',axis),[]});
    net(sys,sprintf('ClosingSpeedFrom%d/1',axis),{sprintf('Group%dServo/3',axis),[]});
    net(sys,sprintf('Group%dServo/2',axis),{ ...
        sprintf('group%d_velocity/1',axis),[]});
end
net(sys,'Group1Servo/1',{ ...
    'group1_actual/1',[]; ...
    'gap1_actual/1',[900 205;900 80;1250 80;1250 205]; ...
    'Gap2Actual/2',[1250 80;1590 80;1590 875]});
net(sys,'Group2Servo/1',{ ...
    'group2_actual/1',[]; ...
    'Gap2Actual/1',[900 480;900 355;1540 355;1540 845]});
net(sys,'Gap2Actual/1',{ ...
    'RemainingGap2Clearance/1',[]; ...
    'gap2_actual/1',[1405 860;1405 955]});
net(sys,'RemainingGap2Clearance/1',{'ClearanceRate/1',[]});
net(sys,'ClearanceRate/1',{'SafeClosingSpeed/1',[]});
net(sys,'SafeClosingSpeed/1',{'ClosingSpeedGoto/1',[]});
end

function routeServo(sys,axis)
net(sys,'Command/1',{'Error/1',[100 210;100 200]});
net(sys,'Error/1',{'Kp/1',[];'Ki/1',[205 210;205 325]});
net(sys,'Kp/1',{'Control/1',[530 210;530 200]});
net(sys,'Ki/1',{'IntegralInput/1',[]});
net(sys,'IntegralInput/1',{'PIIntegral/1',[]});
net(sys,'PIIntegral/1',{'Control/2',[520 335;520 220]});
net(sys,'Control/1',{ ...
    'TravelCommandLimit/1',[]; ...
    'AntiWindupError/2',[650 210;650 455]});
net(sys,'TravelCommandLimit/1',{ ...
    'PlantError/1',[815 210;815 190]; ...
    'AntiWindupError/1',[810 210;810 435]});
net(sys,'AntiWindupError/1',{'AntiWindupGain/1',[]});
net(sys,'AntiWindupGain/1',{'IntegralInput/2',[315 445;315 345]});
net(sys,'Disturbance/1',{'PlantError/2',[825 110;825 210]});
net(sys,'PlantError/1',{'InverseTau/1',[]});
net(sys,'InverseTau/1',{'VelocityLimit/1',[]});
net(sys,'VelocityLimit/1',{'GapInterlock/2',[]});
if axis==1
    net(sys,'SafeClosingSpeed/1',{'GapInterlock/1',[1170 110;1170 190]});
    net(sys,'FreeDirectionLimit/1',{'GapInterlock/3',[1170 355;1170 230]});
else
    net(sys,'FreeDirectionLimit/1',{'GapInterlock/1',[1170 120;1170 190]});
    net(sys,'SafeClosingSpeed/1',{'NegativeClosingSpeed/1',[]});
    net(sys,'NegativeClosingSpeed/1',{'GapInterlock/3',[1170 365;1170 230]});
end
net(sys,'GapInterlock/1',{'Position/1',[];'ActualVelocity/1',[1290 210;1290 330]});
net(sys,'Position/1',{ ...
    'ActualPosition/1',[]; ...
    'Error/2',[1420 210;1420 570;110 570;110 220]; ...
    'PlantError/3',[825 570;825 230]});
end

function net(sys,source,routes)
% Replace one signal tree, retaining its exact endpoints and logging settings.
% First route starts at the source port. Subsequent routes start at an
% explicit junction on a route drawn above them; no inferred junctions.
sourcePort=port(sys,source,'Outport');
old=get_param(sourcePort,'Line');
assert(old~=-1,'zoom:LayoutConnections','Missing source %s.',source);
destinations=zeros(size(routes,1),1);
for k=1:size(routes,1), destinations(k)=port(sys,routes{k,1},'Inport'); end
actual=get_param(old,'DstPortHandle');
assert(isequal(sort(actual(:)),sort(destinations)), ...
    'zoom:LayoutConnections','Unexpected connections on %s.',source);
% Data logging/test-point properties belong to unchanged source ports.
parameters={'Name','Tag','UserData','UserDataPersistent'};
supported=fieldnames(get_param(old,'ObjectParameters'));
parameters=parameters(ismember(parameters,supported));
values=cell(size(parameters));
for k=1:numel(parameters), values{k}=get_param(old,parameters{k}); end
delete_line(old);
for k=1:size(routes,1)
    points=routes{k,2};
    if k==1, points=[get_param(sourcePort,'Position');points]; end
    points=[points;get_param(destinations(k),'Position')];
    line=add_line(sys,points);
    if k==1
        for j=1:numel(parameters), set_param(line,parameters{j},values{j}); end
    end
end
end

function handle=port(sys,endpoint,kind)
parts=strsplit(endpoint,'/');
handles=get_param([sys '/' parts{1}],'PortHandles');
handle=handles.(kind)(str2double(parts{2}));
end
