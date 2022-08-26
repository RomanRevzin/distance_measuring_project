classdef Stereo_Image_App < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        StereoImagePairDropDown       matlab.ui.control.DropDown
        StereoImagePairDropDownLabel  matlab.ui.control.Label
        RectifiedPairLabel            matlab.ui.control.Label
        FeatureExtractionLabel        matlab.ui.control.Label
        RightImageLabel               matlab.ui.control.Label
        LeftImageLabel                matlab.ui.control.Label
        OriginalLeftImage             matlab.ui.control.Image
        NextButton                    matlab.ui.control.Button
        FeatureExtractionImage        matlab.ui.control.Image
        RectifedPairImage             matlab.ui.control.Image
        RectifyImagesButton           matlab.ui.control.Button
        OriginalRightImage            matlab.ui.control.Image
        BrowseButton                  matlab.ui.control.Button
        BrowseButton_2                matlab.ui.control.Button
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            assignin('base','GUI_handler', app);
            StereoImagePairDropDownValueChanged(app, event.EventData)
            run("Stereo_Image_App_SecondStep.m")
            SecondStep = evalin('base', 'SecondStep');
            SecondStep.UIFigure.Visible = 'off';
            app.NextButton.Visible = 'off';
            app.UIFigure.Visible = 'on';
        end

        % Button pushed function: BrowseButton_2
        function BrowseButton_2Pushed(app, event)
            path = imgetfile;
            assignin('base','I2', imread(path))
            app.OriginalRightImage.ImageSource = path;
            app.OriginalRightImage.Visible = 'on';
            app.NextButton.Visible = 'off';
            app.UIFigure.Visible = 'on';
        end

        % Button pushed function: BrowseButton
        function BrowseButtonPushed(app, event)
            try
                path = imgetfile;
                assignin('base','I1', imread(path));
                app.OriginalLeftImage.ImageSource = path;
                app.OriginalLeftImage.Visible = 'on';
            catch
                % if cancel button pressed in brose window
            end
            app.UIFigure.Visible = 'on';
        end

        % Button pushed function: RectifyImagesButton
        function RectifyImagesButtonPushed(app, event)
            I1 = evalin('base', 'I1');
            I2 = evalin('base', 'I2');
            try
                [I1_rectified,I2_rectified, matchedImage] = rectifyImages(I1,I2);
                app.FeatureExtractionImage.ImageSource = matchedImage;
                app.RectifedPairImage.ImageSource = [I1_rectified,I2_rectified];
                app.FeatureExtractionImage.Visible = 'on';
                app.RectifedPairImage.Visible = 'on';
                assignin('base','I1_rect', I1_rectified);
                assignin('base','I2_rect', I2_rectified);
                app.NextButton.Visible = 'on';
                SecondStep = evalin('base', 'SecondStep');
                
                SecondStep.InteractivePanel.Visible = 'off';
                SecondStep.DepthPanel.Visible = 'off';
                SecondStep.ControlPanel.Visible = 'off';
                cla(SecondStep.InteractiveImage);

            catch ex
                uialert(app.UIFigure,ex.message,'Error','Icon','error');
            end
        end

        % Button pushed function: NextButton
        function NextButtonPushed(app, event)
            app.UIFigure.Visible = 'off';
            SecondStep = evalin('base', 'SecondStep');
            disparityMap = disparity(evalin('base', 'I1_rect'),evalin('base', 'I2_rect'));
            imshow(disparityMap,[],'Parent',SecondStep.DisparityImage, ...
               Colormap=jet),colorbar(SecondStep.DisparityImage);
            SecondStep.DisparityImage.Title.String = "Disparity Map";
            assignin('base','disparityMap',disparityMap)
            disableDefaultInteractivity(SecondStep.DisparityImage)
            SecondStep.BaseDistanceLengthUnitEditField.Value = evalin('base', 'base');
            SecondStep.FocalLengthpxEditField.Value = evalin('base', 'focal');
            SecondStep.MaxDistanceLengthUnitEditField.Value = evalin('base', 'maxDistance');
            SecondStep.UIFigure.Visible = 'on';
        end

        % Value changed function: StereoImagePairDropDown
        function StereoImagePairDropDownValueChanged(app, event)
            base = 0;
            focal = 0;
            maxDistance = 0;
            if(strcmpi(app.StereoImagePairDropDown.Value ,'Custom')==1)
                app.BrowseButton.Visible = 'on';
                app.BrowseButton_2.Visible = 'on';
            else
                app.BrowseButton.Visible = 'off';
                app.BrowseButton_2.Visible = 'off';
                % absolute path to the folder containing the mlapp file;
                root = fileparts(mfilename('fullpath'));
                path_left = ""; 
                path_right = "";
                switch(app.StereoImagePairDropDown.Value)
                    case 'Set  1'
                        path_left = "\images\LowChangeLeft.jpeg";
                        path_right = "\images\LowChangeRight.jpeg";
                        base = 10;
                        focal = 1300;
                        maxDistance = 250;
                    case 'Set  2'
                        path_left = "\images\GoodOneLeft.jpeg";
                        path_right = "\images\GoodOneRight.jpeg";
                        base = 10;
                        focal = 1300;
                        maxDistance = 250;
                    case 'Set  3'
                        path_left = "\images\UnevenLightingLeft.jpg";
                        path_right = "\images\UnevenLightingRight.jpg";
                        base = 16;
                        focal = 1300;
                        maxDistance = 400;
                end
                try
                    % absolute path to the folder containing the mlapp file;
                    full_path_left = fullfile(root, path_left);
                    full_path_right = fullfile(root, path_right);
                    app.OriginalLeftImage.ImageSource = full_path_left;
                    app.OriginalRightImage.ImageSource = full_path_right;
                    assignin('base','I1', imread(full_path_left));
                    assignin('base','I2', imread(full_path_right));
                catch
                   % error('One or more paths not found!')
                end
            end
            assignin('base', 'base', base);
            assignin('base', 'focal', focal);
            assignin('base', 'maxDistance', maxDistance);
            app.NextButton.Visible = 'off';
                
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1594 948];
            app.UIFigure.Name = 'First Step';
            app.UIFigure.WindowState = 'maximized';

            % Create BrowseButton_2
            app.BrowseButton_2 = uibutton(app.UIFigure, 'push');
            app.BrowseButton_2.ButtonPushedFcn = createCallbackFcn(app, @BrowseButton_2Pushed, true);
            app.BrowseButton_2.Visible = 'off';
            app.BrowseButton_2.Tooltip = {'Browse for image'};
            app.BrowseButton_2.Position = [1097 539 100 22];
            app.BrowseButton_2.Text = 'Browse';

            % Create BrowseButton
            app.BrowseButton = uibutton(app.UIFigure, 'push');
            app.BrowseButton.ButtonPushedFcn = createCallbackFcn(app, @BrowseButtonPushed, true);
            app.BrowseButton.Visible = 'off';
            app.BrowseButton.Tooltip = {'Browse for image'};
            app.BrowseButton.Position = [342 539 100 22];
            app.BrowseButton.Text = 'Browse';

            % Create OriginalRightImage
            app.OriginalRightImage = uiimage(app.UIFigure);
            app.OriginalRightImage.Position = [781 580 733 318];
            %app.OriginalRightImage.ImageSource = 'C:\Users\peppa\Desktop\ruppin\year 3\semester 2\IMAGE PROCESSING\final_proj\images\LowChangeRight.jpeg';

            % Create RectifyImagesButton
            app.RectifyImagesButton = uibutton(app.UIFigure, 'push');
            app.RectifyImagesButton.ButtonPushedFcn = createCallbackFcn(app, @RectifyImagesButtonPushed, true);
            app.RectifyImagesButton.FontName = 'Arial';
            app.RectifyImagesButton.Tooltip = {'Perform rectification of the images'};
            app.RectifyImagesButton.Position = [342 47 100 22];
            app.RectifyImagesButton.Text = 'Rectify Images';

            % Create RectifedPairImage
            app.RectifedPairImage = uiimage(app.UIFigure);
            app.RectifedPairImage.Visible = 'off';
            app.RectifedPairImage.Position = [794 93 719 378];

            % Create FeatureExtractionImage
            app.FeatureExtractionImage = uiimage(app.UIFigure);
            app.FeatureExtractionImage.Visible = 'off';
            app.FeatureExtractionImage.Position = [1 95 777 376];

            % Create NextButton
            app.NextButton = uibutton(app.UIFigure, 'push');
            app.NextButton.ButtonPushedFcn = createCallbackFcn(app, @NextButtonPushed, true);
            app.NextButton.Tooltip = {'Proceed to the next step'};
            app.NextButton.Position = [1104 47 100 22];
            app.NextButton.Text = 'Next';

            % Create OriginalLeftImage
            app.OriginalLeftImage = uiimage(app.UIFigure);
            app.OriginalLeftImage.Position = [1 580 765 318];
            %app.OriginalLeftImage.ImageSource = 'C:\Users\peppa\Desktop\ruppin\year 3\semester 2\IMAGE PROCESSING\final_proj\images\LowChangeLeft.jpeg';

            % Create LeftImageLabel
            app.LeftImageLabel = uilabel(app.UIFigure);
            app.LeftImageLabel.FontName = 'David';
            app.LeftImageLabel.FontSize = 20;
            app.LeftImageLabel.FontWeight = 'bold';
            app.LeftImageLabel.Position = [337 908 106 26];
            app.LeftImageLabel.Text = 'Left Image';

            % Create RightImageLabel
            app.RightImageLabel = uilabel(app.UIFigure);
            app.RightImageLabel.FontName = 'David';
            app.RightImageLabel.FontSize = 20;
            app.RightImageLabel.FontWeight = 'bold';
            app.RightImageLabel.Position = [1094 908 120 26];
            app.RightImageLabel.Text = 'Right Image';

            % Create FeatureExtractionLabel
            app.FeatureExtractionLabel = uilabel(app.UIFigure);
            app.FeatureExtractionLabel.FontName = 'David';
            app.FeatureExtractionLabel.FontSize = 20;
            app.FeatureExtractionLabel.FontWeight = 'bold';
            app.FeatureExtractionLabel.Position = [316 481 181 26];
            app.FeatureExtractionLabel.Text = 'Feature Extraction';

            % Create RectifiedPairLabel
            app.RectifiedPairLabel = uilabel(app.UIFigure);
            app.RectifiedPairLabel.FontName = 'David';
            app.RectifiedPairLabel.FontSize = 20;
            app.RectifiedPairLabel.FontWeight = 'bold';
            app.RectifiedPairLabel.Position = [1097 481 133 26];
            app.RectifiedPairLabel.Text = 'Rectified Pair';

            % Create StereoImagePairDropDownLabel
            app.StereoImagePairDropDownLabel = uilabel(app.UIFigure);
            app.StereoImagePairDropDownLabel.HorizontalAlignment = 'right';
            app.StereoImagePairDropDownLabel.FontName = 'David';
            app.StereoImagePairDropDownLabel.FontWeight = 'bold';
            app.StereoImagePairDropDownLabel.Position = [642 518 97 22];
            app.StereoImagePairDropDownLabel.Text = 'Stereo Image Pair';

            % Create StereoImagePairDropDown
            app.StereoImagePairDropDown = uidropdown(app.UIFigure);
            app.StereoImagePairDropDown.Items = {'Set  1', 'Set  2', 'Set  3', 'Custom'};
            app.StereoImagePairDropDown.ValueChangedFcn = createCallbackFcn(app, @StereoImagePairDropDownValueChanged, true);
            app.StereoImagePairDropDown.Position = [754 518 100 22];
            app.StereoImagePairDropDown.Value = 'Set  1';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Stereo_Image_App

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