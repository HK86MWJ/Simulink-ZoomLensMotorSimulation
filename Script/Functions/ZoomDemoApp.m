classdef ZoomDemoApp < handle
    %ZOOMDEMOAPP Interactive two-group optical zoom; optimization is cached.
    properties (SetAccess=private)
        Figure
        Slider
        PlayButton
        Speed
        Status
        Viewer
        ViewerGrid
        Trajectory
        Nominal
        Meta
        PlaybackTimer
        Phase = 0
        LastTick
        Busy = false
        FrameCount = 0
        LastError = ""
    end
    methods
        function app=ZoomDemoApp(trajectory)
            app.Trajectory=trajectory;
            [app.Nominal,app.Meta]=loadZoomSystem;
            app.Figure=uifigure('Name','70–210 mm Photographic Zoom Lens', ...
                'Position',[80 80 1280 720],'CloseRequestFcn',@(~,~) delete(app));
            grid=uigridlayout(app.Figure,[5 1]);
            grid.RowHeight={38,'1x',60,44,40}; grid.Padding=[20 12 20 12];
            uilabel(grid,'Text','PHOTOGRAPHIC ZOOM  |  70–210 mm  |  Fixed image plane', ...
                'FontSize',22,'FontWeight','bold');
            app.ViewerGrid=uigridlayout(grid,[1 1],'Padding',[0 0 0 0]);
            app.Slider=uislider(grid,'Limits',[70 210],'Value',70, ...
                'MajorTicks',70:20:210,'ValueChangedFcn',@(~,event) app.seek(event.Value));
            row=uigridlayout(grid,[1 5],'ColumnWidth',{130,70,100,180,'1x'},'Padding',[0 0 0 0]);
            app.PlayButton=uibutton(row,'state','Text','Play / Stop','ValueChangedFcn',@(~,~) app.toggle());
            uilabel(row,'Text','Speed');
            app.Speed=uidropdown(row,'Items',{'0.25x','0.5x','1x','2x'},'ItemsData',[.25 .5 1 2],'Value',1);
            uibutton(row,'Text','Save 12 s MP4','ButtonPushedFcn',@(~,~) app.saveMovie());
            uilabel(row,'Text','C1–C2 fixed  |  C3–C4 move  |  C5–C12 move  |  C13 fixed');
            app.Status=uilabel(grid,'Text','Ready','FontSize',14);
            app.PlaybackTimer=timer('ExecutionMode','fixedSpacing','Period',0.1, ...
                'BusyMode','drop','Name','ZoomDemoPlayback','TimerFcn',@(~,~) app.tick());
            app.render(70);
        end
        function render(app,target)
            if app.Busy, return; end
            app.Busy=true;
            cleanup=onCleanup(@() app.releaseBusy());
            try
                gaps=interpolateZoomGaps(app.Trajectory,target);
                [app.Viewer,state]=drawZoomFrame(app.ViewerGrid,app.Viewer,app.Nominal,app.Meta,gaps,target);
                app.FrameCount=app.FrameCount+1;
                app.Slider.Value=target;
                app.Status.Text=sprintf('Target %.2f mm   Actual %.3f mm   Error %+.3f mm   gap1 %.3f mm   gap2 %.3f mm   Focus offset %+.3f mm', ...
                    target,state.FocalLength,state.FocalLength-target,gaps(1),gaps(2),state.FocusOffset);
                if abs(state.FocusOffset)>.5
                    app.Status.FontColor=[.7 .3 .05];
                else
                    app.Status.FontColor=[.1 .1 .1];
                end
            catch exception
                app.LastError=string(exception.message);
                app.stop();
                app.Status.Text="Stopped: "+string(exception.message);
                uialert(app.Figure,exception.message,'Optical analysis stopped');
            end
        end
        function seek(app,target)
            app.stop();
            app.Phase=acos(max(-1,min(1,(140-target)/70)));
            app.render(target);
        end
        function toggle(app)
            if app.PlayButton.Value
                app.LastTick=tic;
                start(app.PlaybackTimer);
            else
                app.stop();
            end
        end
        function tick(app)
            dt=toc(app.LastTick); app.LastTick=tic;
            app.Phase=mod(app.Phase+2*pi*dt*app.Speed.Value/12,2*pi);
            app.render(140-70*cos(app.Phase));
        end
        function stop(app)
            if ~isempty(app.PlaybackTimer) && isvalid(app.PlaybackTimer)
                stop(app.PlaybackTimer);
            end
            if isgraphics(app.PlayButton), app.PlayButton.Value=false; end
        end
        function saveMovie(app)
            app.stop();
            [file,folder]=uiputfile('*.mp4','Save zoom animation',fullfile(app.Meta.Root,'Results','zoom_animation.mp4'));
            if isequal(file,0), return; end
            app.Status.Text='Exporting 12-second animation...'; drawnow;
            try
                exportZoomAnimation(fullfile(folder,file),app.Trajectory);
                app.Status.Text="Saved: "+string(fullfile(folder,file));
            catch exception
                uialert(app.Figure,exception.message,'Export failed');
            end
        end
        function delete(app)
            app.stop();
            if ~isempty(app.PlaybackTimer) && isvalid(app.PlaybackTimer), delete(app.PlaybackTimer); end
            if isgraphics(app.Figure)
                app.Figure.CloseRequestFcn=[];
                delete(app.Figure);
            end
        end
    end
    methods (Access=private)
        function releaseBusy(app)
            if isvalid(app), app.Busy=false; end
        end
    end
end
