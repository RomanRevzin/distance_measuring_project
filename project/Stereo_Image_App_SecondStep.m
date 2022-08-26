classdef Stereo_Image_App_SecondStep < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        PreviousButton                  matlab.ui.control.Button
        ControlPanel                    matlab.ui.container.Panel
        UndefinedLabel                  matlab.ui.control.Label
        InteractiveShowButton           matlab.ui.control.Button
        LengthUnitsEditField            matlab.ui.control.NumericEditField
        LengthUnitsEditFieldLabel       matlab.ui.control.Label
        InteractiveModeSwitch           matlab.ui.control.Switch
        InteractiveMaximalDistanceEditField  matlab.ui.control.NumericEditField
        InteractiveMaximalDistanceEditFieldLabel  matlab.ui.control.Label
        InteractiveMinimalDistanceEditField  matlab.ui.control.NumericEditField
        InteractiveMinimalDistanceEditFieldLabel  matlab.ui.control.Label
        InteractivePanel                matlab.ui.container.Panel
        InteractiveImage                matlab.ui.control.UIAxes
        DepthPanel                      matlab.ui.container.Panel
        DepthImage                      matlab.ui.control.UIAxes
        MaxDistanceLengthUnitEditField  matlab.ui.control.NumericEditField
        MaxDistanceLengthUnitEditFieldLabel  matlab.ui.control.Label
        BaseDistanceLengthUnitEditField  matlab.ui.control.NumericEditField
        BaseDistanceLengthUnitEditFieldLabel  matlab.ui.control.Label
        FocalLengthpxEditField          matlab.ui.control.NumericEditField
        FocalLengthpxEditFieldLabel     matlab.ui.control.Label
        CalculateDepthMapButton         matlab.ui.control.Button
        DisparityImage                  matlab.ui.control.UIAxes
    end

    
    methods (Access = private)
        function InteractiveImageClicked(app,event,eventargs)
            if(app.InteractiveModeSwitch.Value == 'Point')
                z = get(app.InteractiveImage,'CurrentPoint');
                x = z(1, 2); y = z(1, 1);
                x = round(x); y = round(y);
                depthMap = evalin('base', 'depthMap');
                depth = double(squeeze(depthMap(x,y)));
                if(isnan(depth))
                    app.UndefinedLabel.Visible = 'on';
                    app.LengthUnitsEditField.Value = 0;
                else
                    app.UndefinedLabel.Visible = 'off';
                    app.LengthUnitsEditField.Value = depth;
                end
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
           assignin('base','SecondStep', app);
           disableDefaultInteractivity(app.DepthImage)
           disableDefaultInteractivity(app.InteractiveImage)
        end

        % Button pushed function: CalculateDepthMapButton
        function CalculateDepthMapButtonPushed(app, event)
            focal = app.FocalLengthpxEditField.Value;
            base = app.BaseDistanceLengthUnitEditField.Value;
            maxDist = app.MaxDistanceLengthUnitEditField.Value; 
            if(base > 0 && focal > 0 && maxDist > 0)
                depthMap = disparity2depth(base,focal,evalin('base','disparityMap'));
                
                depthMap(depthMap>maxDist)=nan;
                assignin('base','depthMap',depthMap)
    
                imshow(depthMap,[0 maxDist],'Parent',app.DepthImage, ...
                    Colormap=jet),colorbar(app.DepthImage);
                app.DepthImage.Title.String = "Depth Map";
                app.DepthImage.Visible = 'off';
                %disableDefaultInteractivity(app.DepthImage)
                app.LengthUnitsEditField.Visible = 'off';
                app.InteractiveModeSwitch.Visible = 'on';
                app.LengthUnitsEditField.Visible = 'off';
                app.LengthUnitsEditFieldLabel.Visible = 'off';
                app.InteractiveShowButton.Visible = 'on';
                app.InteractiveMaximalDistanceEditField.Visible = 'on';
                app.InteractiveMinimalDistanceEditField.Visible = 'on';
                app.InteractiveMaximalDistanceEditFieldLabel.Visible = 'on';
                app.InteractiveMinimalDistanceEditFieldLabel.Visible = 'on';
                app.InteractiveImage.Visible = "on";
                im = imshow(evalin('base', 'I2_rect'), [], 'Parent',app.InteractiveImage, 'InitialMagnification', 'fit');
                assignin('base', 'interactiveImage', im)     
                app.InteractiveMinimalDistanceEditField.Value = 0;
                app.InteractiveMaximalDistanceEditField.Value = ...
                app.MaxDistanceLengthUnitEditField.Value;
    
                app.InteractivePanel.Visible = 'on';
                app.DepthPanel.Visible = 'on';
                app.ControlPanel.Visible = 'on';
            else 
                uialert(app.UIFigure,'values must be positive','Error','Icon','error');
            end
        end

        % Button pushed function: InteractiveShowButton
        function InteractiveShowButtonPushed(app, event)
            depthMap = evalin('base','depthMap');
            min = app.InteractiveMinimalDistanceEditField.Value;
            max = app.InteractiveMaximalDistanceEditField.Value;
            if(min < max && min > 0)
                range = depthMap < max & depthMap > min;
                rect2 = evalin('base', 'I2_rect');
                if(size(rect2,3) == 1)
                    show = zeros(size(rect2),'uint8');
                    show(range) = rect2(range);
                elseif(size(rect2,3) == 3)
                    show1 = rect2(:,:,1);
                    show2 = rect2(:,:,2);
                    show3 = rect2(:,:,3);
                    sh1 = zeros(size(show1),'uint8');
                    sh2 = zeros(size(show2),'uint8');
                    sh3 = zeros(size(show3),'uint8');
                    sh1(range) = show1(range);
                    sh2(range) = show2(range);
                    sh3(range) = show3(range);
                    show = cat(3, sh1, sh2, sh3);
                end
                
                imshow(show,[], 'Parent', app.InteractiveImage)
            else
                uialert(app.UIFigure,'min must be less than max and both must be positive','Error','Icon','error');
            end
        end

        % Button pushed function: PreviousButton
        function PreviousButtonPushed(app, event)
            app.UIFigure.Visible = 'off';
            GUI = evalin('base', 'GUI_handler');
            GUI.UIFigure.Visible = 'on';
        end

        % Value changed function: InteractiveModeSwitch
        function InteractiveModeSwitchValueChanged(app, event)
            value = app.InteractiveModeSwitch.Value;
            image = evalin('base', 'interactiveImage');
            im = imshow(image.CData, 'Parent',app.InteractiveImage, 'InitialMagnification', 'fit');
            set(im, 'ButtonDownFcn', @app.InteractiveImageClicked);
            app.InteractiveImage
            switch(value)
                case 'Range'
                    app.UndefinedLabel.Visible = 'off';
                    app.LengthUnitsEditField.Visible = 'off';
                    app.LengthUnitsEditFieldLabel.Visible = 'off';
                    app.InteractiveShowButton.Visible = 'on';
                    app.InteractiveMaximalDistanceEditField.Visible = 'on';
                    app.InteractiveMinimalDistanceEditField.Visible = 'on';
                    app.InteractiveMaximalDistanceEditFieldLabel.Visible = 'on';
                    app.InteractiveMinimalDistanceEditFieldLabel.Visible = 'on';
                    app.InteractiveMinimalDistanceEditField.Value = 0;
                    app.InteractiveMaximalDistanceEditField.Value = ...
                    app.MaxDistanceLengthUnitEditField.Value;
                case 'Point'
                    app.LengthUnitsEditField.Visible = 'on';
                    app.LengthUnitsEditFieldLabel.Visible = 'on';
                    app.InteractiveShowButton.Visible = 'off';
                    app.InteractiveMaximalDistanceEditField.Visible = 'off';
                    app.InteractiveMinimalDistanceEditField.Visible = 'off';
                    app.InteractiveMaximalDistanceEditFieldLabel.Visible = 'off';
                    app.InteractiveMinimalDistanceEditFieldLabel.Visible = 'off';
            end
        end

        % Button down function: DepthImage
        function DepthImageButtonDown(app, event)
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1621 704];
            app.UIFigure.Name = 'MATLAB App';

            % Create DisparityImage
            app.DisparityImage = uiaxes(app.UIFigure);
            title(app.DisparityImage, 'Title')
            app.DisparityImage.XTick = [];
            app.DisparityImage.YTick = [];
            app.DisparityImage.Clipping = 'off';
            app.DisparityImage.Position = [1 407 752 297];

            % Create CalculateDepthMapButton
            app.CalculateDepthMapButton = uibutton(app.UIFigure, 'push');
            app.CalculateDepthMapButton.ButtonPushedFcn = createCallbackFcn(app, @CalculateDepthMapButtonPushed, true);
            app.CalculateDepthMapButton.Tooltip = {'Perform Calculations of Distance Map '};
            app.CalculateDepthMapButton.Position = [1447 288 128 22];
            app.CalculateDepthMapButton.Text = 'Calculate Depth Map';

            % Create FocalLengthpxEditFieldLabel
            app.FocalLengthpxEditFieldLabel = uilabel(app.UIFigure);
            app.FocalLengthpxEditFieldLabel.HorizontalAlignment = 'right';
            app.FocalLengthpxEditFieldLabel.Position = [788 288 94 22];
            app.FocalLengthpxEditFieldLabel.Text = 'Focal Length, px';

            % Create FocalLengthpxEditField
            app.FocalLengthpxEditField = uieditfield(app.UIFigure, 'numeric');
            app.FocalLengthpxEditField.HorizontalAlignment = 'center';
            app.FocalLengthpxEditField.Position = [897 288 52 22];

            % Create BaseDistanceLengthUnitEditFieldLabel
            app.BaseDistanceLengthUnitEditFieldLabel = uilabel(app.UIFigure);
            app.BaseDistanceLengthUnitEditFieldLabel.HorizontalAlignment = 'right';
            app.BaseDistanceLengthUnitEditFieldLabel.Position = [965 288 143 22];
            app.BaseDistanceLengthUnitEditFieldLabel.Text = 'Base Distance, length unit';

            % Create BaseDistanceLengthUnitEditField
            app.BaseDistanceLengthUnitEditField = uieditfield(app.UIFigure, 'numeric');
            app.BaseDistanceLengthUnitEditField.HorizontalAlignment = 'center';
            app.BaseDistanceLengthUnitEditField.Position = [1118 288 45 22];

            % Create MaxDistanceLengthUnitEditFieldLabel
            app.MaxDistanceLengthUnitEditFieldLabel = uilabel(app.UIFigure);
            app.MaxDistanceLengthUnitEditFieldLabel.HorizontalAlignment = 'right';
            app.MaxDistanceLengthUnitEditFieldLabel.Position = [1184 288 140 22];
            app.MaxDistanceLengthUnitEditFieldLabel.Text = 'Max Distance, length unit';

            % Create MaxDistanceLengthUnitEditField
            app.MaxDistanceLengthUnitEditField = uieditfield(app.UIFigure, 'numeric');
            app.MaxDistanceLengthUnitEditField.HorizontalAlignment = 'center';
            app.MaxDistanceLengthUnitEditField.Position = [1337 288 66 22];

            % Create DepthPanel
            app.DepthPanel = uipanel(app.UIFigure);
            app.DepthPanel.BorderType = 'none';
            app.DepthPanel.Visible = 'off';
            app.DepthPanel.Position = [786 361 857 343];

            % Create DepthImage
            app.DepthImage = uiaxes(app.DepthPanel);
            title(app.DepthImage, 'Title')
            app.DepthImage.XTick = [];
            app.DepthImage.YTick = [];
            app.DepthImage.Clipping = 'off';
            app.DepthImage.Visible = 'off';
            app.DepthImage.ButtonDownFcn = createCallbackFcn(app, @DepthImageButtonDown, true);
            app.DepthImage.Position = [68 47 789 294];

            % Create InteractivePanel
            app.InteractivePanel = uipanel(app.UIFigure);
            app.InteractivePanel.BorderType = 'none';
            app.InteractivePanel.Visible = 'off';
            app.InteractivePanel.Position = [1 1 752 361];

            % Create InteractiveImage
            app.InteractiveImage = uiaxes(app.InteractivePanel);
            title(app.InteractiveImage, 'Distance Image')
            app.InteractiveImage.XTick = [];
            app.InteractiveImage.YTick = [];
            app.InteractiveImage.NextPlot = 'add';
            app.InteractiveImage.Visible = 'off';
            app.InteractiveImage.Position = [0 20 729 320];

            % Create ControlPanel
            app.ControlPanel = uipanel(app.UIFigure);
            app.ControlPanel.BorderType = 'none';
            app.ControlPanel.Visible = 'off';
            app.ControlPanel.Position = [798 1 415 288];

            % Create InteractiveMinimalDistanceEditFieldLabel
            app.InteractiveMinimalDistanceEditFieldLabel = uilabel(app.ControlPanel);
            app.InteractiveMinimalDistanceEditFieldLabel.HorizontalAlignment = 'right';
            app.InteractiveMinimalDistanceEditFieldLabel.Visible = 'off';
            app.InteractiveMinimalDistanceEditFieldLabel.Position = [26 183 97 22];
            app.InteractiveMinimalDistanceEditFieldLabel.Text = 'Minimal Distance';

            % Create InteractiveMinimalDistanceEditField
            app.InteractiveMinimalDistanceEditField = uieditfield(app.ControlPanel, 'numeric');
            app.InteractiveMinimalDistanceEditField.HorizontalAlignment = 'center';
            app.InteractiveMinimalDistanceEditField.Visible = 'off';
            app.InteractiveMinimalDistanceEditField.Position = [125 183 100 22];

            % Create InteractiveMaximalDistanceEditFieldLabel
            app.InteractiveMaximalDistanceEditFieldLabel = uilabel(app.ControlPanel);
            app.InteractiveMaximalDistanceEditFieldLabel.HorizontalAlignment = 'right';
            app.InteractiveMaximalDistanceEditFieldLabel.Visible = 'off';
            app.InteractiveMaximalDistanceEditFieldLabel.Position = [24 153 100 22];
            app.InteractiveMaximalDistanceEditFieldLabel.Text = 'Maximal Distance';

            % Create InteractiveMaximalDistanceEditField
            app.InteractiveMaximalDistanceEditField = uieditfield(app.ControlPanel, 'numeric');
            app.InteractiveMaximalDistanceEditField.HorizontalAlignment = 'center';
            app.InteractiveMaximalDistanceEditField.Visible = 'off';
            app.InteractiveMaximalDistanceEditField.Position = [127 153 97 22];
            app.InteractiveMaximalDistanceEditField.Value = 200;

            % Create InteractiveModeSwitch
            app.InteractiveModeSwitch = uiswitch(app.ControlPanel, 'slider');
            app.InteractiveModeSwitch.Items = {'Range', 'Point'};
            app.InteractiveModeSwitch.ValueChangedFcn = createCallbackFcn(app, @InteractiveModeSwitchValueChanged, true);
            app.InteractiveModeSwitch.Visible = 'off';
            app.InteractiveModeSwitch.Tooltip = {'Show picture in distance range or distance of a point'};
            app.InteractiveModeSwitch.Position = [56 255 45 20];
            app.InteractiveModeSwitch.Value = 'Range';

            % Create LengthUnitsEditFieldLabel
            app.LengthUnitsEditFieldLabel = uilabel(app.ControlPanel);
            app.LengthUnitsEditFieldLabel.HorizontalAlignment = 'center';
            app.LengthUnitsEditFieldLabel.FontSize = 20;
            app.LengthUnitsEditFieldLabel.FontWeight = 'bold';
            app.LengthUnitsEditFieldLabel.Visible = 'off';
            app.LengthUnitsEditFieldLabel.Position = [87 199 201 26];
            app.LengthUnitsEditFieldLabel.Text = 'Length Units';

            % Create LengthUnitsEditField
            app.LengthUnitsEditField = uieditfield(app.ControlPanel, 'numeric');
            app.LengthUnitsEditField.HorizontalAlignment = 'center';
            app.LengthUnitsEditField.FontSize = 20;
            app.LengthUnitsEditField.FontWeight = 'bold';
            app.LengthUnitsEditField.Visible = 'off';
            app.LengthUnitsEditField.Position = [21 199 100 26];

            % Create InteractiveShowButton
            app.InteractiveShowButton = uibutton(app.ControlPanel, 'push');
            app.InteractiveShowButton.ButtonPushedFcn = createCallbackFcn(app, @InteractiveShowButtonPushed, true);
            app.InteractiveShowButton.Visible = 'off';
            app.InteractiveShowButton.Tooltip = {'Show image in distance range'};
            app.InteractiveShowButton.Position = [21 219 100 22];
            app.InteractiveShowButton.Text = 'Show';

            % Create UndefinedLabel
            app.UndefinedLabel = uilabel(app.ControlPanel);
            app.UndefinedLabel.FontSize = 20;
            app.UndefinedLabel.FontWeight = 'bold';
            app.UndefinedLabel.FontColor = [1 0 0];
            app.UndefinedLabel.Visible = 'off';
            app.UndefinedLabel.Position = [263 199 103 26];
            app.UndefinedLabel.Text = 'Undefined';

            % Create PreviousButton
            app.PreviousButton = uibutton(app.UIFigure, 'push');
            app.PreviousButton.ButtonPushedFcn = createCallbackFcn(app, @PreviousButtonPushed, true);
            app.PreviousButton.Tooltip = {'Return to the previous page'};
            app.PreviousButton.Position = [1461 40 100 22];
            app.PreviousButton.Text = 'Previous';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Stereo_Image_App_SecondStep

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end