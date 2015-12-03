%% ooMEFBrowser: EEG Browser for MEF files
%
% ooMEFBrowser Open the UI for reading MEF files
% 
% Optional parameters 
% 
% RM: Room number for live streaming (no other paramters accepted)
%       >    ooMEFBrowser(55)
%
% Drive: letter of the data drive
% PYID: patient code/folder name
%       >   ooMEFBrowser('R','PY14N012', '2001/01/01 13:00:00')
% 
% Optional parameters:
% Time: can be a string or time in microseconds
%
% Keyboard Shortcuts:
%   Left/Right arrow : move forward/backward 1/10th window
%   Space/Backspace  : move forward/backward one window
%   Up/Down arrow    : Increase/decrease sensitivity by factor 2
%   f                : cycle various filters (No, 0.5Hz, 80-150Hz, 200-400 Hz)
%   d                : toggle sample downsampling
%   6                : toogle 60Hz notch filter
%   z                : toggle zscore
%   g                : open window to specify time
%   q                : quit
%
%   ** right-click channels or their label to hide channels

%% CC Jouny - Johns Hopkins University - 2012-2015 (c) 
%%

function varargout = ooMEFBrowser(varargin)
    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @ooMEFBrowser_OpeningFcn, ...
                       'gui_OutputFcn',  @ooMEFBrowser_OutputFcn, ...
                       'gui_LayoutFcn',  [] , ...
                       'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
    % End initialization code - DO NOT EDIT
end

% --- Executes just before MEFBrowser is made visible.
function ooMEFBrowser_OpeningFcn(hObject, ~, handles, varargin)

    global warninglevel;
    global streamtype;

    P=handles;                                              % Main data structure is the handles from Matlab figure
    P.windowstart=0;
    
    if length(varargin)==1 && (varargin{1}==55 || varargin{1}==56) ,
        streamtype=2; % Live
        RM=varargin{1};
    else
        streamtype=1; % Offline
        if length(varargin)>=2,
            drive=varargin{1};
            PY_ID=varargin{2};
            if length(varargin)>=3,
                timestart=varargin{3};
                if ischar(timestart),
                    P.windowstart=date2usec(timestart);
                else
                    P.windowstart=timestart;
                end
            end
        end
        if isempty(varargin),
            % open empty browser
            streamtype=0; %No file
        end
    end

    % Initialization of the figure

    % Windows position
    leftmargin=0.04;
    xwidth=0.835;
    lowermargin=0.045;
    yheight=0.93;
    lowermargintime=0.02;
    yheighttime=0.015;
    
    mainwindowpos = [leftmargin lowermargin xwidth yheight];
    timeaxispos   = [leftmargin lowermargintime xwidth yheighttime];
    
    % Create MAIN Object axe
    P.eega=EEG_axes(P.mainoomeffigure, mainwindowpos);
    %Create UI axes for time navigation
    P.timeaxe=axes('Parent', P.mainoomeffigure ,'Units','Normalized','Position', timeaxispos, 'Visible','off');

    
    warninglevel=0;
    P.maf=MAF_file;                                         % Create main MAF file class for either types and add it to P
    
    % Constants
    P.ftoggle=2;
    P.hfotoggle=0;
    P.evttoggle=1;
    P.filter60=0;
    P.aliasing=1;
    P.xtick=1;

    P.filters=[NaN NaN; 0.5 NaN; 80 200; 200 400];
    P.filtername={'No filtering'; 'High-Pass 0.5Hz'; 'Ripple (80-200Hz)'; 'Fast ripple (200-400Hz)'};
    P.hfotoggle=0;
    P.zscore=0;

    P.windowchoice={0.001;0.01;0.05;0.1;0.25;0.5;1;2;4;5;10;20;30;60;120;300;600};
    P.windowsize=10;

    P.exclusion={};
    P.inclusion={};  % overwriting inclusion can be added here
    P.mode='monopolar';
    P.play=0;

    % Choose default command line output for MEFBrowser
    P.output = hObject;
    
    switch streamtype,
        case 0
            % Empty browser
            guidata(hObject, P);
        case 1
            % Offline file from cmd line
            P.drive=drive;
            P.PY_ID=PY_ID;
            data_path =  archtype_path(drive, 'MEF');
            PathName=fullfile(data_path, PY_ID);
            FileName=[PY_ID '.maf'];
            P=OpenOfflineFile(P, PathName, FileName);
            if ~isempty(P.maf.filename),
                guidata(hObject, P);
                InitDisplay(hObject);
            else
                Quit_Callback([], [], P);
            end
        case 2
            % Livestream initialization
            P=OpenLiveStream(P, RM);
            guidata(hObject, P);
            InitDisplay(hObject);
        otherwise
            guidata(hObject, P);
    end
   

end

%% Jump time bar
function PointNClickTimeBar(hObject, ~)
    P=guidata(hObject);
    axesHandle  = get(hObject,'Parent');
    coordinates = get(axesHandle,'CurrentPoint');  % X scale is in microseconds
    P.windowstart = round(coordinates(1,1)/1e6)*1e6; % round to nearest second
    [P.maf, P.eeg, P.labels, P.xeeg]=GetEEGData(P, P.windowstart, P.windowsize*1e6);
    OOupdatemefplot(P);
end

%% Update Channel selection from the check box array 
function UpdateChannelSelect(hObject, ~)
    global streamtype;
    
    P=guidata(hObject);
    val=get(hObject, 'Value');
    ngrid=get(hObject, 'userdata');
    P.grid_inclusion(ngrid)=val;
    %add permanent exclusion
    exclusion_select=P.grid_label(find(P.grid_inclusion==0)); %#ok<FNDSB>
    exclusion=[exclusion_select(:); P.exclusion];
    P.maf=P.maf.UpdateChannelSelection(P.grid_label(find(P.grid_inclusion)), exclusion); %#ok<FNDSB>
    if streamtype==2,
        P=GetLiveData(P);
    else
        [P.maf, P.eeg, P.labels, P.xeeg]=GetEEGData(P, P.windowstart, P.windowsize*1e6);
    end
    OOupdatemefplot(P);
end

% --- Outputs from this function are returned to the command line.
function varargout = ooMEFBrowser_OutputFcn(~, ~, handles)
    varargout{1} = handles;
end

% --- Executes on key press with focus on mainoomeffigure and none of its controls.
function MEF_KeyPressFcn(hObject, eventdata, handles)  %#ok<*DEFNU>

P=handles;
switch eventdata.Key,
    % quit
    case 'q', 
        %close(P.eventfigure);
        close(P.mainoomeffigure);
    % move forward backward
    case 'leftarrow',
        pushbutton8_Callback(P.pushbutton8, [], P);
        return;
    case 'rightarrow',
        pushbutton9_Callback(P.pushbutton9, [], P);
        return;
    case 'backspace',
        pushbutton10_Callback(P.pushbutton10, [], P);
        return;
    case 'space',
        pushbutton11_Callback(P.pushbutton11, [], P);
        return;
    % scale 
    case 'downarrow',
        P.eega.Scale(0.5);
    case 'uparrow',
        P.eega.Scale(2);
    case 'z',
        P.zscore=1-P.zscore;
        if P.zscore, P.eega.Scale(100);
        else P.eega.Scale(0.01);
        end
    % toggle function
    case 'd',
        P.dtoggle=1-P.dtoggle;
    case 'f',
        P.ftoggle=P.ftoggle+1;
        if P.ftoggle>size(P.filters,1),
            P.ftoggle=1;
            P.eega.Scale(1);
        end
        if P.ftoggle>2,
            P.eega.Scale(10);
        else
            P.eega.Scale(0.1);
        end
        
    case 'g',
        prompt = {'Enter Date and Time:'};
        dlg_title = 'Go to';
        num_lines = 1;
        def = {usec2date(P.windowstart)};
        answer = inputdlg(prompt,dlg_title,num_lines,def);
        if ~isempty(answer),
            newtime=date2usec(answer);
            if ~isnan(newtime),
                P.windowstart=newtime;
                [P.maf, P.eeg, P.labels, P.xeeg]=GetEEGData(P, P.windowstart, P.windowsize*1e6);
            end
        end
    case 'h',
        P.hfotoggle=1-P.hfotoggle;
    case 'e',
        P.evttoggle=1-P.evttoggle;
        hevts=findobj(P.eega.h, 'Tag', 'SZ');
        if P.evttoggle, set(hevts,'Visible', 'on');
        else set(hevts,'Visible', 'off');
        end
        guidata(hObject, P);
        return;
        
    case '6',
        P.filter60=1-P.filter60;
    case 'x',
        P.xtick=1-P.xtick;
        P.eega=plotXtick(P.eega, P.xtick);
        guidata(hObject, P);
        return;

    otherwise,
        disp(['No command associated with key: ' eventdata.Key]);
    %case 'h',
    %    P.hfotoggle=1-P.hfotoggle;
        
end

if eventdata.Key~='q',
    OOupdatemefplot(P);
end
end

%% group radio panel for bipolar/monopolar mode
function uipanelmontage_SelectionChangeFcn(~, eventdata, handles) 
    P=handles;
    switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
        case 'mono'
            P.mode='monopolar';
        case 'bi'
            P.mode='bipolar';
    end
    OOupdatemefplot(P);
end

%% --- Executes on button press in pushbutton8. (Backward <)
function pushbutton8_Callback(~, ~, handles)
    P=handles;
    shift=P.windowsize/10;
    tread=P.windowstart-shift*1e6-1e6/P.Fs;
    if tread>=P.T0, 
        [P.maf, neeg, ~, xeeg]=GetEEGData(P, tread, shift*1e6);
        laneeg=size(neeg,2);
        P.eeg=[neeg P.eeg(:,1:end-laneeg)];
        P.xeeg=[xeeg P.xeeg(1:end-laneeg)];
        P.windowstart=P.windowstart-shift*1e6;
        OOupdatemefplot(P);
    end
end

%% --- Executes on button press in pushbutton9. (Forward > )
function pushbutton9_Callback(~, ~, handles) 
    P=handles;
    tread=P.windowstart+P.windowsize*1e6+1e6/P.Fs;
    shift=P.windowsize/10;
    if tread+shift*1e6<=P.Tend, 
        [P.maf, neeg, ~, xeeg]=GetEEGData(P, tread, shift*1e6);
        laneeg=size(neeg,2);
        P.eeg=[P.eeg(:,(laneeg+1):end) neeg(:,:)];
        P.xeeg=[P.xeeg((laneeg+1):end) xeeg];
        P.windowstart=P.windowstart+shift*1e6;
        OOupdatemefplot(P);
    end
end

%% --- Executes on button press in pushbutton10. (Backward - Backspace key)
function pushbutton10_Callback(~, ~, handles)
    P=handles;
    tread=P.windowstart-P.windowsize*1e6;
    shift=P.windowsize;
    if tread>=P.T0, 
        [P.maf, P.eeg, ~, P.xeeg]=GetEEGData(P, tread, shift*1e6);
        P.windowstart=P.windowstart-shift*1e6;
        OOupdatemefplot(P);
    end
end

%% --- Executes on button press in pushbutton11. (FF - Space bar)
function pushbutton11_Callback(~, ~, handles)
    P=handles;
    tread=P.windowstart+P.windowsize*1e6+1e6/P.Fs;
    shift=P.windowsize;
    if tread+shift*1e6<=P.Tend, 
        [P.maf, P.eeg, ~, P.xeeg]=GetEEGData(P, tread, shift*1e6);
        P.windowstart=P.windowstart+shift*1e6;
        OOupdatemefplot(P);
    end
end

%% --- Executes on button press in pushbutton12. (Play)
function pushbutton12_Callback(hObject, ~, handles)
global streamtype;
    P=handles;   
    P.play=1;
    guidata(hObject, P);
    while P.play,
        P=guidata(hObject);
        if streamtype==2,
            % read live data
            P=GetLiveData(P);
            OOupdatemefplot(P);
        else
            pushbutton11_Callback(hObject, [], P);
        end
        drawnow;
    end
end

%% --- Executes on button press in pushbutton13.
function pushbutton13_Callback(hObject, ~, handles)
    P=handles;
    P.play=0;
    guidata(hObject, P);
end

%% --- Executes on selection change in ws (Window Size).
function ws_Callback(hObject, ~, handles)
    P=handles;
    items = get(hObject,'String');
    index_selected = get(hObject,'Value');
    item_selected = items(index_selected,:);
    P.windowsize=str2double(item_selected);
    tread=P.windowstart;
    shift=P.windowsize;
    if tread+shift*1e6<=P.Tend, 
        [P.maf, P.eeg, ~, P.xeeg]=GetEEGData(P, tread, shift*1e6);
        OOupdatemefplot(P);
    end
end

%% --- Populate the Windows Size Popup
function ws_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    set(hObject, 'String', [0.001;0.01;0.05;0.1;0.25;0.5;1;2;4;5;10;20;30;60;120;300;600], 'Value', 11);
end

%% Reading function to get EEG data
function [maf, eeg, labels, xeeg]=GetEEGData(P, windowstart, windowsize)
    maf=P.maf;
    eeg=[];
    xeeg=[];
    labels={};
    try
        [maf, eeg, labels, xeeg]=maf.GetEEGData(windowstart, windowsize);
    catch Merror
        errordlg(Merror.message , 'Error reading EEG');
    end
end

function P=GetLiveData(P)
    P.T0=P.windowstart;
    data=P.eeg;
    datanum=size(data, 2);
    [chunk,~] = P.LSLinlet.pull_chunk();
    nreadframe=size(chunk,2);
    
    if (nreadframe>0)
        data(:, 1:datanum-nreadframe) = data(:, nreadframe+1:datanum);
        data(:, datanum-nreadframe+1:datanum)=chunk(find(P.maf.mef_valid),:); %#ok<FNDSB>
    end
    T0=now;
    usec=rem(rem(T0,1)*86400,1)*1000*1000;
    P.windowstart=date2usec(datestr(T0))+usec;
    P.xeeg=P.windowstart+(1:size(data,2))*1e6/P.Fs;

    P.eeg=data(find(P.maf.mef_included),:); %#ok<FNDSB>
    P.labels=P.labels(find(P.maf.mef_included)); %#ok<FNDSB>

end


%% --- Executes on selection change in EventListBox.
function EventListBox_Callback(hObject, ~, handles)
    P=handles;
    index_selected = get(hObject,'Value');
    event_time__selected = P.events_time(index_selected); 
    P.windowstart=event_time__selected-P.windowsize*1e6/2;
    [P.maf, P.eeg, P.labels, P.xeeg]=GetEEGData(P, P.windowstart, P.windowsize*1e6);
    if ~isempty(P.eeg), 
        OOupdatemefplot(P);
    end
end

%% --- Executes during object creation, after setting all properties.
function EventListBox_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

%% --- Open File
function P=OpenOfflineFile(P, PathName, FileName)
    % MEF Header and initialization
    if exist( fullfile(PathName, FileName), 'file')==2,
        P.maf.OpenMAF( PathName ,  FileName);
        if ~isempty(P.maf.filename),
            P.maf=P.maf.ReadALLMAF;
            P.dtoggle=1;
        end
    end
    if isempty(P.maf.filename),
        warndlg('The path and PYID does not match to a valid MAF file', 'Error opening MAF file');
    end
end

%% --- Open Live Stream
function P=OpenLiveStream(P, RM)

    %Livestream initialization
    p0=pwd;
    P.LSLlib = lsl_loadlib();
    result = {};
    while isempty(result)
        result = lsl_resolve_byprop(P.LSLlib,'source_id', ['nkroom' num2str(RM)]); end 
    P.LSLinlet = lsl_inlet(result{1});
    % Get Stream Infos & Channels
    P.LSLinfo=P.LSLinlet.info;
    ch = P.LSLinfo.desc().child('channels').child('channel');
    channels = {};
    indexdropch=[];
    indexch=0;
    while ~ch.empty()
        name = ch.child_value_n('label');
        indexch=indexch+1;
        if name,
            channels{end+1} = name; %#ok<AGROW>
        else
            indexdropch=[indexdropch indexch]; %#ok<AGROW>
        end
        ch = ch.next_sibling_n('channel');
    end
    P.maf.stream_label_list=channels;
    P.labels=P.maf.stream_label_list;

    if length(channels) ~= P.LSLinfo.channel_count(),
        P.maf.mef_valid=ones(1,P.LSLinfo.channel_count());
        P.maf.mef_valid(indexdropch)=0;
        disp([int2str(length(indexdropch)) ' empty channels dropped']); % if empty channel are dropped, need to save the index of channels to drop from the stream chunk
    else
        P.maf.mef_valid=ones(1,P.LSLinfo.channel_count());
    end

    P.drive='R';
    P.PY_ID='PY99N999';
    P.maf.nb_stream=length(P.maf.stream_label_list);
    P.maf.nb_sources=length(P.maf.stream_label_list);
    P.maf.start_times(1)=date2usec(datestr(now));
    P.maf.end_times(1)=date2usec(datestr(now))+3600*1e6;
    P.dtoggle=0;
    cd(p0);

end

%% --- Init Display after file/stream opened
function InitDisplay(hObject)

    global streamtype;
    
    P=guidata(hObject);

    % Patient Label
    str=sprintf('Patient Code: %s', P.PY_ID);
    set(P.patienttext, 'String', str, 'HorizontalAlign', 'center');

    if P.windowstart==0;
        P.windowstart=P.maf.start_times(1);
    end
    P.T0=P.maf.start_times(1);
    P.Tend=P.maf.end_times(end);
    
    % Reading Events
    [ P.events_name, P.events_time, P.exclusion ] = CompileEvent( P.maf.filepath, P.PY_ID );
    convertedtimes=usec2date(P.events_time);
    listboxinfo={};
    for ni=1:length(convertedtimes),
        listboxinfo{ni}=[P.events_name{ni} '@' convertedtimes{ni}]; %#ok<AGROW>
    end
    set(P.EventListBox, 'String', listboxinfo);
     
    % Read Grid Infos
    [ P.GL, P.GS ] = read_patient_gridinfo( P.maf.filepath, P.PY_ID );
    %inclusion={};
    P.maf.UpdateChannelSelection(P.inclusion, P.exclusion);

    % create UI electrodes grid panel entries
    [S, G, ~]=channel_group(P.maf.stream_label_list);
    Gcode=unique(G);
    % Loop on grid
    for ngrid=1:length(Gcode), 
        idx=find(G==Gcode(ngrid));  % index of channels in this grid
        rootidx= isstrprop(S{idx(1)}, 'alpha');
        P.grid_label{ngrid}=S{idx(1)}(rootidx); 
        P.grid_inclusion(ngrid)=1;
        even=1-mod(ngrid,2);
        row=floor((ngrid-1)/2)+1;
        P.cbh(ngrid) = uicontrol('Parent',P.uipanelelectrodes,'Style','checkbox',...
                    'String',P.grid_label{ngrid},...
                    'Value',1,...
                    'Units','normalized',...
                    'FontSize', 7,...
                    'Position',[0.05+even*0.5, 1-row*0.075, 0.4, 0.05],...
                    'userdata', ngrid,...
                    'Callback',@UpdateChannelSelect);
    end
    
    % Set Time Axe tick and limits
    set(P.timeaxe, 'XTick', [], 'YTick', [], 'Box', 'off', 'visible','off');
    set(P.timeaxe, 'XLim', [P.T0 P.Tend]);
    set(P.timeaxe, 'Visible','on');
    % Draw periods
    for nepisode=1:length(P.maf.start_times),
        set(P.timeaxe, 'NextPlot','Add');
        t0=P.maf.start_times(nepisode);
        t1=P.maf.end_times(nepisode);
        hp=patch([t0 t1 t1 t0], [0 0 1 1], 'g', 'FaceColor', [0.3 0.7 0.3],  'EdgeColor','none', 'Parent', P.timeaxe);
        set(hp, 'ButtonDownFcn', @PointNClickTimeBar);
    end
    % Add Dates / Time Scale
    D0=(floor(P.T0/1e6/3600/24)*24*3600*1e6);
    D1=(ceil(P.Tend/1e6/3600/24)*24*3600*1e6);
    iList=[1 2 3 6 12 24 48 72 96];
    interval=1;
    xticktime=D0:iList(interval)*3600*1e6:D1;
    while length(xticktime)>10 && interval<9,
        interval=interval+1;
        xticktime=D0:iList(interval)*3600*1e6:D1;
    end
    if interval<6,
        formattime=0;
    else
        formattime=1;
    end
    set(P.timeaxe, 'XLim', [D0 D1]);
    for nt=1:length(xticktime)-1,
        text(xticktime(nt), -0.2, usec2date(xticktime(nt), formattime), 'FontSize', 7, 'HorizontalAlign','center', 'VerticalAlign','top', 'FontName','Arial Rounded MT', 'Parent', P.timeaxe);
        plot([1 1]*xticktime(nt), [0 1], 'k:', 'LineW',1, 'Parent', P.timeaxe);
    end
    % Time marker
    P.timemarker=patch([P.windowstart*[1 1] (P.windowstart+P.windowsize*1e6)*[1 1]], [0 1 1 0], 'r', 'EdgeColor', 'r', 'LineW', 4, 'Parent', P.timeaxe);
    
    % First Read
    if streamtype==1,
        [P.maf, P.eeg, P.labels, P.xeeg]=GetEEGData(P, P.windowstart, P.windowsize*1e6);
        P.Fs=P.maf.mef_streams(find(P.maf.mef_included==1, 1, 'first')).fs;
    else
        P.Fs=double(P.LSLinfo.nominal_srate());
        P.ftoggle=1; % no filter
        datanum = P.Fs*P.windowsize;
        P.eeg = zeros(P.maf.nb_stream, datanum);
        P=GetLiveData(P);
    end
    
    P.FsD=P.Fs; % default to 1/10th only set if downsampling
    
    toggleUI(P, 1);
    
    % generic Update Plots
    OOupdatemefplot(P);
end

%% --- Toggle UI elements
function toggleUI(P, bool)
    
if bool,
    % Enable UI components, disable File Open
    set(P.pushbutton8, 'Enable','on');
    set(P.pushbutton9, 'Enable','on');
    set(P.pushbutton10, 'Enable','on');
    set(P.pushbutton11, 'Enable','on');
    set(P.pushbutton12, 'Enable','on');
    set(P.pushbutton13, 'Enable','on');

    set(P.bi, 'Enable','on');
    set(P.mono, 'Enable','on');
    set(P.ws, 'Enable','on');

    set(P.EventListBox, 'Enable','on');
    
    set(P.OpenMenuItem, 'Enable','off');
    set(P.CloseMenuItem, 'Enable','on');
else
    % Disable UI components, enable File Open
    set(P.pushbutton8, 'Enable','off');
    set(P.pushbutton9, 'Enable','off');
    set(P.pushbutton10, 'Enable','off');
    set(P.pushbutton11, 'Enable','off');
    set(P.pushbutton12, 'Enable','off');
    set(P.pushbutton13, 'Enable','off');

    set(P.bi, 'Enable','off');
    set(P.mono, 'Enable','off');
    set(P.ws, 'Enable','off');

    set(P.EventListBox, 'Enable','off');
    
    set(P.OpenMenuItem, 'Enable','on');
    set(P.CloseMenuItem, 'Enable','off');
end
end

%% Pick and open a file --------------------------------------------------
function OpenMenuItem_Callback(hObject, ~, handles)
    global streamtype;
    P=handles;
    [FileName,PathName,~] = uigetfile('*.maf','Choose MAF file');
    if ~isequal(FileName,0),
        streamtype=1;
        [~, P.PY_ID, ~]=fileparts(FileName);
        P=OpenOfflineFile(P, PathName, FileName);
        guidata(hObject, P);
        InitDisplay(hObject);
    end
end

%% Close the file / disable UI --------------------------------------------
function CloseMenuItem_Callback(~, ~, handles)
    P=handles;
    toggleUI(P, 0);
end

%% Close the app ----------------------------------------------------------
function Quit_Callback(~, ~, handles)
    P=handles;
    close(P.mainoomeffigure);
end
