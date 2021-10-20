classdef response_finder_app_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                   matlab.ui.Figure
        ExportButton               matlab.ui.control.Button
        ResponseButton             matlab.ui.control.Button
        planeDisplay               matlab.ui.control.NumericEditField
        SelectButton               matlab.ui.control.Button
        AverageButton              matlab.ui.control.Button
        LoadStimButton             matlab.ui.control.Button
        ZPlaneSlider               matlab.ui.control.Slider
        ZPlaneSliderLabel          matlab.ui.control.Label
        ResolutionFactorKnob       matlab.ui.control.DiscreteKnob
        ResolutionFactorKnobLabel  matlab.ui.control.Label
        LoadTiffButton             matlab.ui.control.Button
        coordinateList             matlab.ui.control.Table
        SavePositionButton         matlab.ui.control.Button
        PlotPostionButton          matlab.ui.control.Button
        SelectCellButton           matlab.ui.control.Button
        ManualButton               matlab.ui.control.Button
        XEditFieldLabel            matlab.ui.control.Label
        XEditField                 matlab.ui.control.NumericEditField
        YEditFieldLabel            matlab.ui.control.Label
        YEditField                 matlab.ui.control.NumericEditField
        LoadConfigButton           matlab.ui.control.Button
        UIAxes5                    matlab.ui.control.UIAxes
        UIAxes4                    matlab.ui.control.UIAxes
        UIAxes3                    matlab.ui.control.UIAxes
        UIAxes2                    matlab.ui.control.UIAxes
        UIAxes                     matlab.ui.control.UIAxes
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: LoadTiffButton
        function LoadTiffButtonPushed(app, event)
            clear var
            global var
            var.coord_points = [];
            [file, path] = uigetfile('*.tif','Select Tiff Files','Multiselect','on');
            if iscell(file)
                var.multi_file = 1;
                for i = 1:length(file)
                    var.frame_per_file(i) = length(imfinfo([path file{i}]));
                end
                var.num_file = length(file);
                var.num_frames = sum(var.frame_per_file);
                var.fileName = [path file{1}];
                var.file = file;
                var.path = path;
            else
                var.multi_file = 0;
                var.num_file = 1;
                var.num_frames = length(imfinfo([path file]));
                var.fileName = [path file];
                var.file{1} = file;
                var.frame_per_file = length(imfinfo([path file]));
                var.path = path;
            end
            data = imread(var.fileName,1);
            imagesc(app.UIAxes,data)
            app.UIAxes.YLim = [0 size(data,1)];
            app.UIAxes.XLim = [0 size(data,2)];
            app.UIAxes.YLim = [0 size(data,1)];
            app.UIAxes.XLim = [0 size(data,2)];
            var.count = 0;
            app.UIAxes.Toolbar.Visible = 'off';
            app.UIAxes2.Toolbar.Visible = 'on';
            app.UIAxes3.Toolbar.Visible = 'on';
            app.UIAxes4.Toolbar.Visible = 'off';
            app.UIAxes5.Toolbar.Visible = 'off';
            
        end

        % Button pushed function: LoadStimButton
        function LoadStimButtonPushed(app, event)
            global var
            [file, path] = uigetfile('*.mat');
            stim_struct = load([path file]);
            var.stim_onset = stim_struct.stim_onset_frame;
        end

        % Button pushed function: LoadConfigButton
        function LoadConfigButtonPushed(app, event)
            global var
            [file, path] = uigetfile('*.mat');
            param_struct = load([path file]);
            var.num_average = param_struct.num_average;
            var.pre_stim_frame = param_struct.pre_stim_frame;
            var.post_stim_frame = param_struct.post_stim_frame;
            var.num_z_planes = param_struct.num_z_planes;
            app.ZPlaneSlider.Limits = [0 var.num_z_planes];
            if var.num_z_planes<=10
                app.ZPlaneSlider.MajorTicks = min(app.ZPlaneSlider.Limits):1:max(app.ZPlaneSlider.Limits);
            elseif var.num_z_planes>10 && var.num_z_planes<=20
                app.ZPlaneSlider.MajorTicks = min(app.ZPlaneSlider.Limits):2:max(app.ZPlaneSlider.Limits);
            else
                app.ZPlaneSlider.MajorTicks = min(app.ZPlaneSlider.Limits):5:max(app.ZPlaneSlider.Limits);
            end
        end

        % Callback function
        function PlanesSpinnerValueChanged(app, event)
            global var
            value = app.PlanesSpinner.Value;
            var.num_z_planes = value;
            app.ZPlaneSlider.Limits = [0 var.num_z_planes];
            if var.num_z_planes<=10
                app.ZPlaneSlider.MajorTicks = min(app.ZPlaneSlider.Limits):1:max(app.ZPlaneSlider.Limits);
            elseif var.num_z_planes>10 && var.num_z_planes<=20
                app.ZPlaneSlider.MajorTicks = min(app.ZPlaneSlider.Limits):2:max(app.ZPlaneSlider.Limits);
            else
                app.ZPlaneSlider.MajorTicks = min(app.ZPlaneSlider.Limits):5:max(app.ZPlaneSlider.Limits);
            end
        end

        % Value changed function: ZPlaneSlider
        function ZPlaneSliderValueChanged(app, event)
            global var
            var.zvalue = round(app.ZPlaneSlider.Value);
            if var.zvalue ~= 0
                imagesc(app.UIAxes,imread(var.fileName,var.zvalue));
                app.planeDisplay.Value = var.zvalue;
            end
        end

        % Value changed function: planeDisplay
        function planeDisplayValueChanged(app, event)
            global var
            var.zvalue = app.planeDisplay.Value;
            app.ZPlaneSlider.Value = var.zvalue;
            if var.zvalue ~= 0
                imagesc(app.UIAxes,imread(var.fileName,var.zvalue));
            end
        end

        % Button pushed function: AverageButton
        function AverageButtonPushed(app, event)
            global var
            clear var.all_z_slice
            seq_temp = var.zvalue:var.num_z_planes:var.num_frames;
            
            if length(seq_temp)>var.num_average
                seq = seq_temp(1:var.num_average);
            else
                seq = seq_temp;
            end
            
            sample_frame = imread(var.fileName, seq(1));
            all_z_slice = zeros(size(sample_frame,1),size(sample_frame,2),length(seq));
            for i = 1:length(seq)
                all_z_slice(:,:,i) = imread(var.fileName, seq(i));
            end
            imagesc(app.UIAxes,mean(all_z_slice,3));
            var.all_z_slice = all_z_slice;
        end

        % Button pushed function: SelectButton
        function SelectButtonPushed(app, event)
            
            global var
            
            bottom_left = drawpoint(app.UIAxes,'Color','r','InteractionsAllowed','None','HandleVisibility','off','Visible','off');
            top_right = drawpoint(app.UIAxes,'Color','r','InteractionsAllowed','None','HandleVisibility','off','Visible','off');
            X = [bottom_left.Position(1); top_right.Position(1)];
            Y = [bottom_left.Position(2); top_right.Position(2)];
            
            var.xmin = round(min(X)); var.xmax = round(max(X));
            var.ymin = round(min(Y)); var.ymax = round(max(Y));
            xs = [var.xmin var.xmax var.xmax var.xmin var.xmin];
            ys = [var.ymin var.ymin var.ymax var.ymax var.ymin];
            
            hold(app.UIAxes, 'on')
            plot(app.UIAxes,xs, ys, 'r-');
            zoom_mean = mean(var.all_z_slice(var.ymin:var.ymax,var.xmin:var.xmax,:),3);
            imagesc(app.UIAxes2,zoom_mean)
            app.UIAxes2.YLim = [1 size(zoom_mean,1)];
            app.UIAxes2.XLim = [1 size(zoom_mean,2)];
            app.ResolutionFactorKnob.Value = 0;
            cla(app.UIAxes3)
        end

        % Value changed function: ResolutionFactorKnob
        function ResolutionFactorKnobValueChanged(app, event)
            global var
            var.scale_factor = app.ResolutionFactorKnob.Value;
            if var.scale_factor == 0
                imagesc(app.UIAxes3,mean(var.all_z_slice(var.ymin:var.ymax,var.xmin:var.xmax,:),3))
                var.final_stack = var.all_z_slice(var.ymin:var.ymax,var.xmin:var.xmax,:);
                app.UIAxes3.YLim = [1 size(var.final_stack,1)];
                app.UIAxes3.XLim = [1 size(var.final_stack,2)];
            else
                clear all_z_slice_small
                size_temp = size(imresize(var.all_z_slice(var.ymin:var.ymax,var.xmin:var.xmax,1),1/var.scale_factor));
                all_z_slice_small = zeros(size_temp(1),size_temp(2), size(var.all_z_slice,3));
                for i = 1:size(var.all_z_slice,3)
                    all_z_slice_small(:,:,i) = imresize(var.all_z_slice(var.ymin:var.ymax,var.xmin:var.xmax,i),1/var.scale_factor);
                end
                imagesc(app.UIAxes3,mean(all_z_slice_small,3))
                app.UIAxes3.YLim = [1 size(all_z_slice_small,1)];
                app.UIAxes3.XLim = [1 size(all_z_slice_small,2)];
                var.resolved_imaged = mean(all_z_slice_small,3);
            end
        end

        % Button pushed function: ResponseButton
        function ResponseButtonPushed(app, event)
            global var
            clear cropped_trial var.frame_list frame_list
            seq = var.zvalue:var.num_z_planes:var.num_frames;
            var.stim_onset_corrected = seq(cell2mat(arrayfun(@(x) find(seq-x>0,1),var.stim_onset,'UniformOutput',false)));
            if var.multi_file == 1
                frame_list(1,:) = 1:sum(var.frame_per_file);
            else
                frame_list(1,:) = 1:var.frame_per_file;
            end
            frame_list(2,:) = cell2mat(arrayfun(@(x,y) ones(1,x)*y,var.frame_per_file,1:length(var.frame_per_file),'UniformOutput',false));
            frame_list(3,:) = cell2mat(arrayfun(@(x,y) 1:x, var.frame_per_file, 1:length(var.frame_per_file), 'UniformOutput', false));
        
            var.frame_list = frame_list;
            
            voxel_response = zeros(size(var.resolved_imaged,1),size(var.resolved_imaged,2),var.num_file);
            example_frame_size = size(imread(var.fileName,var.zvalue));
            
            for trial = 1:length(var.stim_onset_corrected)
                stim_index = find(seq==var.stim_onset_corrected(trial));
                pre_stim_index = seq((stim_index-var.pre_stim_frame):stim_index-1);
                post_stim_index = seq(stim_index:(stim_index+var.post_stim_frame)-1);
                
                which_vid = var.frame_list(2,[pre_stim_index post_stim_index]);
                which_frame = var.frame_list(3,[pre_stim_index post_stim_index]);
                
                current_trial = zeros(example_frame_size(1),example_frame_size(2),length(which_vid));
                cropped_trial = imresize(current_trial(var.ymin:var.ymax,var.xmin:var.xmax,length(which_vid)),1/var.scale_factor);
                
                for i = 1:length(which_vid)
                    current_trial(:,:,i) = imread([var.path var.file{which_vid(i)}], which_frame(i));
                    cropped_trial(:,:,i) = imresize(current_trial(var.ymin:var.ymax,var.xmin:var.xmax,i),1/var.scale_factor);
                    %                     current_trial(var.ymin:var.ymax,var.xmin:var.xmax,i);
                    %                     resize_trial(:,:,i) = imresize(cropped_trial(:,:,i))
                end
                
                voxel_response(:,:,trial) = mean(cropped_trial(:,:,var.pre_stim_frame+1:(var.pre_stim_frame+var.post_stim_frame)),3)...
                    - mean(cropped_trial(:,:,1:var.pre_stim_frame),3);
                
                var.all_cropped_trial{trial} = cropped_trial;
                clear current_trial cropped_trial
            end
            
            var.mean_voxel_response = mean(voxel_response,3);
            imagesc(app.UIAxes4,var.mean_voxel_response)
            app.UIAxes4.YLim = [1 size(voxel_response,1)];
            app.UIAxes4.XLim = [1 size(voxel_response,2)];
        end

        % Button pushed function: SelectCellButton
        function SelectCellButtonPushed(app, event)
            global var
            point_select = drawpoint(app.UIAxes4,'Color','r','InteractionsAllowed','None','HandleVisibility','off','Visible','off');
            var.pick_x = round(point_select.Position(1));
            var.pick_y = round(point_select.Position(2));
            app.XEditField.Value = (var.pick_x*var.scale_factor)+var.xmin;
            app.YEditField.Value = (var.pick_y*var.scale_factor)+var.ymin;
            
            clear pre_stim post_stim raw_response_trial f0 normalized_response
            hold(app.UIAxes5, 'off')
            for trial = 1:length(var.stim_onset_corrected)
                raw_response_trial = double(squeeze(var.all_cropped_trial{trial}(var.pick_y,var.pick_x,:)));
                f0 = mean(raw_response_trial(1:var.pre_stim_frame));
                normalized_response = (raw_response_trial-f0)/f0;
                plot(app.UIAxes5,(1:length(raw_response_trial))-var.pre_stim_frame,normalized_response);
                hold(app.UIAxes5, 'on')
            end
            plot(app.UIAxes5,[0 0],app.UIAxes5.YLim,'k')
        end

        % Button pushed function: PlotPostionButton
        function PlotPostionButtonPushed(app, event)
            global var
            hold(app.UIAxes4, 'on')
            plot(app.UIAxes4,var.pick_x,var.pick_y,'ro')
            hold(app.UIAxes4, 'off')
            hold(app.UIAxes3, 'on')
            plot(app.UIAxes3,var.pick_x,var.pick_y,'ro')
            hold(app.UIAxes3, 'off')
            hold(app.UIAxes2, 'on')
            plot(app.UIAxes2,var.pick_x*var.scale_factor,var.pick_y*var.scale_factor,'ro')
            hold(app.UIAxes2, 'off')
            hold(app.UIAxes, 'on')
            plot(app.UIAxes,(var.pick_x*var.scale_factor)+var.xmin,(var.pick_y*var.scale_factor)+var.ymin,'ro')
            hold(app.UIAxes, 'on')
        end

        % Button pushed function: ManualButton
        function ManualButtonPushed(app, event)
            global var
            var.pick_x = round((app.XEditField.Value-var.xmin)/var.scale_factor);
            var.pick_y = round((app.YEditField.Value-var.ymin)/var.scale_factor);
            
            cla(app.UIAxes5);
            clear pre_stim post_stim raw_response_trial f0 normalized_response
            hold(app.UIAxes5, 'off')
            for trial = 1:length(var.stim_onset_corrected)
                raw_response_trial = double(squeeze(var.all_cropped_trial{trial}(var.pick_y,var.pick_x,:)));
                f0 = mean(raw_response_trial(1:var.pre_stim_frame));
                normalized_response = (raw_response_trial-f0)/f0;
                plot(app.UIAxes5,(1:length(raw_response_trial))-var.pre_stim_frame,normalized_response);
                hold(app.UIAxes5, 'on')
            end
            plot(app.UIAxes5,[0 0],app.UIAxes5.YLim,'k')
        end

        % Button pushed function: SavePositionButton
        function SavePositionButtonPushed(app, event)
            global var
            clear new_coord_points
            var.count = var.count + 1;
            new_coord_points = [var.count ...
                var.pick_x*(var.scale_factor)+var.xmin ...
                var.pick_y*(var.scale_factor)+var.ymin ...
                var.zvalue ...
                var.mean_voxel_response(var.pick_y,var.pick_x) ...
                {false}];
            var.coord_points = [var.coord_points; new_coord_points];
            T = array2table(var.coord_points);
            app.coordinateList.Data = T;
        end

        % Button pushed function: ExportButton
        function ExportButtonPushed(app, event)
            coord_array = table2array(app.coordinateList.Data);
            coord_array_valid_temp = reshape([coord_array{:}],size(coord_array,1),[]);
            valid_coordinates = coord_array_valid_temp(coord_array_valid_temp(:,6)==1,2:4);
            
            [filename, pathname] = uiputfile('*.mat','Save Coordinate Variables As');
            newfilename = fullfile(pathname, filename);
            save(newfilename, 'valid_coordinates')
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1346 620];
            app.UIFigure.Name = 'MATLAB App';

            % Create ExportButton
            app.ExportButton = uibutton(app.UIFigure, 'push');
            app.ExportButton.ButtonPushedFcn = createCallbackFcn(app, @ExportButtonPushed, true);
            app.ExportButton.Tooltip = {'Export ''Keep'' coordinates as mat file'};
            app.ExportButton.Position = [1211 569 100 22];
            app.ExportButton.Text = 'Export';

            % Create ResponseButton
            app.ResponseButton = uibutton(app.UIFigure, 'push');
            app.ResponseButton.ButtonPushedFcn = createCallbackFcn(app, @ResponseButtonPushed, true);
            app.ResponseButton.Tooltip = {'Compute the response of each pixel to the stimulus. Response window is specified by config file.'};
            app.ResponseButton.Position = [672 198 90 22];
            app.ResponseButton.Text = 'Response';

            % Create planeDisplay
            app.planeDisplay = uieditfield(app.UIFigure, 'numeric');
            app.planeDisplay.ValueChangedFcn = createCallbackFcn(app, @planeDisplayValueChanged, true);
            app.planeDisplay.Position = [371 109 40 22];

            % Create SelectButton
            app.SelectButton = uibutton(app.UIFigure, 'push');
            app.SelectButton.ButtonPushedFcn = createCallbackFcn(app, @SelectButtonPushed, true);
            app.SelectButton.Tooltip = {'Select area of interest. First point selects the bottom left coordinates, second point selects the top right coordinates.'};
            app.SelectButton.Position = [241 49 170 22];
            app.SelectButton.Text = 'Select';

            % Create AverageButton
            app.AverageButton = uibutton(app.UIFigure, 'push');
            app.AverageButton.ButtonPushedFcn = createCallbackFcn(app, @AverageButtonPushed, true);
            app.AverageButton.Tooltip = {'Averages the current z-plane by n number of frames as set by config file'};
            app.AverageButton.Position = [51 49 170 22];
            app.AverageButton.Text = 'Average';

            % Create LoadStimButton
            app.LoadStimButton = uibutton(app.UIFigure, 'push');
            app.LoadStimButton.ButtonPushedFcn = createCallbackFcn(app, @LoadStimButtonPushed, true);
            app.LoadStimButton.Tooltip = {'Load stimulus file. File must contain variable "stim_time". Stimulus time must be based on raw frame time (not segmented frame time)'};
            app.LoadStimButton.Position = [141 569 100 22];
            app.LoadStimButton.Text = 'Load Stim';

            % Create ZPlaneSlider
            app.ZPlaneSlider = uislider(app.UIFigure);
            app.ZPlaneSlider.Limits = [0 50];
            app.ZPlaneSlider.ValueChangedFcn = createCallbackFcn(app, @ZPlaneSliderValueChanged, true);
            app.ZPlaneSlider.MinorTicks = [];
            app.ZPlaneSlider.Position = [109 128 242 3];

            % Create ZPlaneSliderLabel
            app.ZPlaneSliderLabel = uilabel(app.UIFigure);
            app.ZPlaneSliderLabel.HorizontalAlignment = 'right';
            app.ZPlaneSliderLabel.Position = [41 119 47 22];
            app.ZPlaneSliderLabel.Text = 'Z Plane';

            % Create ResolutionFactorKnob
            app.ResolutionFactorKnob = uiknob(app.UIFigure, 'discrete');
            app.ResolutionFactorKnob.Items = {'Off', '0', '2', '4', '6', '8', '10'};
            app.ResolutionFactorKnob.ItemsData = [0 0 2 4 6 8 10];
            app.ResolutionFactorKnob.ValueChangedFcn = createCallbackFcn(app, @ResolutionFactorKnobValueChanged, true);
            app.ResolutionFactorKnob.Tooltip = {'Change resolution reduction factor for speed'};
            app.ResolutionFactorKnob.FontWeight = 'bold';
            app.ResolutionFactorKnob.Position = [508 73 60 60];
            app.ResolutionFactorKnob.Value = 0;

            % Create ResolutionFactorKnobLabel
            app.ResolutionFactorKnobLabel = uilabel(app.UIFigure);
            app.ResolutionFactorKnobLabel.HorizontalAlignment = 'center';
            app.ResolutionFactorKnobLabel.FontWeight = 'bold';
            app.ResolutionFactorKnobLabel.Position = [485 36 108 22];
            app.ResolutionFactorKnobLabel.Text = 'Resolution Factor';

            % Create LoadTiffButton
            app.LoadTiffButton = uibutton(app.UIFigure, 'push');
            app.LoadTiffButton.ButtonPushedFcn = createCallbackFcn(app, @LoadTiffButtonPushed, true);
            app.LoadTiffButton.Tooltip = {'Import raw tiff from SPIM. You can upload mulitple consecutive tiffs. '};
            app.LoadTiffButton.Position = [31 569 100 22];
            app.LoadTiffButton.Text = 'Load Tiff';

            % Create coordinateList
            app.coordinateList = uitable(app.UIFigure);
            app.coordinateList.ColumnName = {'Cell'; 'X'; 'Y'; 'Z'; 'Response'; 'Keep'};
            app.coordinateList.ColumnWidth = {35, 35, 35, 35, 80};
            app.coordinateList.RowName = {};
            app.coordinateList.ColumnEditable = [false false false false false true];
            app.coordinateList.Position = [1021 41 290 490];

            % Create SavePositionButton
            app.SavePositionButton = uibutton(app.UIFigure, 'push');
            app.SavePositionButton.ButtonPushedFcn = createCallbackFcn(app, @SavePositionButtonPushed, true);
            app.SavePositionButton.Tooltip = {'Save the position for export'};
            app.SavePositionButton.Position = [1021 569 100 22];
            app.SavePositionButton.Text = 'Save Position';

            % Create PlotPostionButton
            app.PlotPostionButton = uibutton(app.UIFigure, 'push');
            app.PlotPostionButton.ButtonPushedFcn = createCallbackFcn(app, @PlotPostionButtonPushed, true);
            app.PlotPostionButton.Tooltip = {'Plot selected position on main window and zoomed window'};
            app.PlotPostionButton.Position = [899 169 90 22];
            app.PlotPostionButton.Text = 'Plot Postion';

            % Create SelectCellButton
            app.SelectCellButton = uibutton(app.UIFigure, 'push');
            app.SelectCellButton.ButtonPushedFcn = createCallbackFcn(app, @SelectCellButtonPushed, true);
            app.SelectCellButton.Tooltip = {'Select ROI for futher insepction'};
            app.SelectCellButton.Position = [672 169 90 22];
            app.SelectCellButton.Text = 'Select Cell';

            % Create ManualButton
            app.ManualButton = uibutton(app.UIFigure, 'push');
            app.ManualButton.ButtonPushedFcn = createCallbackFcn(app, @ManualButtonPushed, true);
            app.ManualButton.Tooltip = {'Manual selection of ROI'};
            app.ManualButton.Position = [899 198 88 22];
            app.ManualButton.Text = 'Manual';

            % Create XEditFieldLabel
            app.XEditFieldLabel = uilabel(app.UIFigure);
            app.XEditFieldLabel.HorizontalAlignment = 'right';
            app.XEditFieldLabel.Position = [785 198 25 22];
            app.XEditFieldLabel.Text = 'X';

            % Create XEditField
            app.XEditField = uieditfield(app.UIFigure, 'numeric');
            app.XEditField.Position = [825 198 47 22];

            % Create YEditFieldLabel
            app.YEditFieldLabel = uilabel(app.UIFigure);
            app.YEditFieldLabel.HorizontalAlignment = 'right';
            app.YEditFieldLabel.Position = [785 169 25 22];
            app.YEditFieldLabel.Text = 'Y';

            % Create YEditField
            app.YEditField = uieditfield(app.UIFigure, 'numeric');
            app.YEditField.Position = [825 169 47 22];

            % Create LoadConfigButton
            app.LoadConfigButton = uibutton(app.UIFigure, 'push');
            app.LoadConfigButton.ButtonPushedFcn = createCallbackFcn(app, @LoadConfigButtonPushed, true);
            app.LoadConfigButton.Tooltip = {'Load cofiguration file for number of frames for averaging, pre and post stimulus window sizes. See doc for more information. '};
            app.LoadConfigButton.Position = [251 569 100 22];
            app.LoadConfigButton.Text = 'Load Config';

            % Create UIAxes5
            app.UIAxes5 = uiaxes(app.UIFigure);
            title(app.UIAxes5, 'Response Trace')
            xlabel(app.UIAxes5, 'Time (frame)')
            ylabel(app.UIAxes5, 'DF/F')
            app.UIAxes5.TickDir = 'out';
            app.UIAxes5.Position = [630 22 359 134];

            % Create UIAxes4
            app.UIAxes4 = uiaxes(app.UIFigure);
            title(app.UIAxes4, 'Response')
            app.UIAxes4.XTick = [];
            app.UIAxes4.XTickLabel = '';
            app.UIAxes4.YTick = [];
            app.UIAxes4.YTickLabel = '';
            app.UIAxes4.Box = 'on';
            app.UIAxes4.Position = [651 231 338 320];

            % Create UIAxes3
            app.UIAxes3 = uiaxes(app.UIFigure);
            title(app.UIAxes3, 'Resolution')
            app.UIAxes3.XTick = [];
            app.UIAxes3.YTick = [];
            app.UIAxes3.Box = 'on';
            app.UIAxes3.Position = [441 161 190 190];

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.UIFigure);
            title(app.UIAxes2, 'Zoom')
            app.UIAxes2.XTick = [];
            app.UIAxes2.YTick = [];
            app.UIAxes2.Box = 'on';
            app.UIAxes2.Position = [441 361 190 190];

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'Main Window')
            app.UIAxes.XTick = [];
            app.UIAxes.YTick = [];
            app.UIAxes.Box = 'on';
            app.UIAxes.Position = [21 161 400 390];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = response_finder_app_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

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