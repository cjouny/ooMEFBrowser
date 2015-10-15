%% ooMEFBrowser: EEG Browser for MEF files
%
% MEFBrowser('drive','PYID', time);
%
% drive: letter of the data drive
% PYID: patient code
% Optional parameters:
% time: can be a string or time in microseconds
%
% Keyboard Shortcuts:
%   Left/Right arrow : move forward/backward 1/10th window
%   Space/Backspace  : move forward/backward one window
%   Up/Down arrow    : Increase/decrease sensitivity by factor 2
%   f                : cycle various filters (No, 0.5Hz, 80-150Hz, 200-400 Hz)
%   d                : toggle sample decimation by 1/10 (no AA correction)
%   6                : toogle 60Hz notch filter
%   z                : toggle zscore
%   g                : open window to specify time
%   e                : toggle event display
%   q                : quit
%
%   ** right-click channels or their label to hide channels
%
% Example:> ooMEFBrowser('R','PY14N004', '01/01/2011 01:23:45')
%
%% CC Jouny - Johns Hopkins University - 2012-2015 (c) 
%
% Updates:
% 09/09/2014: added timeaxe jump / fix downsampling & filter / fix scaling
% 09/17/2014: added time label / time marker / clean up code
% 09/18/2014: round jumping to nearest second
% 10/12/2014: hide/show channels
% 10/20/2014: updated for Matlab2014b
% 10/23/2014: added partial REC files support
% 11/05/2014: Fixed disappearing labels
% 12/10/2014: Added Live Streaming from NK DLL
% 12/12/2014: Changed Streaming to LSL DLL
% 03/01/2015: Added MP
% 07/14/2015: Added event list from SZDB.m
% 09/03/2015: Events plotted as patch for SZ in event list
% 09/10/2015: Numerous handle fixes to allow multiple figures
% 09/10/2015: Enable Menu, toolbar and secondary figure for events
% 09/10/2015: Change axe limites, create events area, and display toggle for events
% 10/xx/2015: Moved decimate to EEGPlot
% 10/12/2015: various fixes usec2date, remove 2nd figure
% 10/12/2015: Added reading CSV for events from NK
% 10/15/2015: Moved grid infos to separate DAT file
%
% TODO: fix filters
% TODO: clean up folder application
% TODO: event management from MAF to UI
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

    if length(varargin)>=2,
        drive=varargin{1};
        PY_ID=varargin{2};
    end
    
    global warninglevel;
    global livestream;

    if length(varargin)==1 && (varargin{1}==55 || varargin{1}==56) ,
        livestream=1;
        RM=varargin{1};
    else
        livestream=0;
    end
        
    warninglevel=0;
    
    P=handles;                                              % Main data structure is the handles from Matlab figure
    P.maf=MAF_file;                                         % Create main MAF file class for either types and add it to P
    
    % Windows position
    
    leftmargin=0.04;
    xwidth=0.835;
    lowermargin=0.045;
    yheight=0.93;
    lowermargintime=0.02;
    yheighttime=0.015;
    
    mainwindowpos = [leftmargin lowermargin xwidth yheight];
    timeaxispos   = [leftmargin lowermargintime xwidth yheighttime];
    
    
    if ~livestream,
        %%%%%%%%%%%% MEF Header and initialization
        data_path =  archtype_path(drive, 'MEF');                       % Create and populate the class
        if exist( fullfile(data_path, PY_ID, [PY_ID '.maf']), 'file')==2,
            P.maf.OpenMAF( fullfile(data_path, PY_ID) , [PY_ID '.maf']);
        end
        if ~isempty(P.maf.filename),
            P.maf=P.maf.ReadALLMAF;
            P.dtoggle=1;
            P.typehdr=0;
            %P.eventlisttime=[P.maf.event_list{:,1}];
        else
            % if not MAF check REC
            %%%%%%%%%%%% REC Header and initialization
            data_path =  archtype_path(drive, 'HDR');                       % Create and populate the class
            datasets=getDataset4Session(PY_ID);
            if isempty(datasets),
                     delete(hObject);
                     return;
            end
            nx=1;
            for nd=1:length(datasets.Path),
                P.recfolder{nd}=fullfile(data_path, datasets.Path{nd});
                headerfilenpath=fullfile(data_path, datasets.Path{nd}, datasets.Header{nd});
                if exist(headerfilenpath, 'file')~=2,
                    continue;
                end
                P.hdr{nd}=readhdr(headerfilenpath);
                lstname=P.hdr{nd}.file_fmt.List_file;
                [tfr, P.filen{nd}]=readlist(fullfile(data_path, datasets.Path{nd}, lstname));
                for ns=1:size(tfr,1),
                    P.maf.start_times(nx)=date2usec(datestr(sum(tfr(ns,[1 3])/86400)));
                    P.maf.end_times(nx)=P.maf.start_times(nx)+tfr(ns,2)*1e6;
                    P.maf.nb_stream(nx,:)=[nd ns]; % using nb_stream field to track folder number for REC files and file number in folder
                    nx=nx+1;
                end
            end
            if nx==1, % no REC header files found
                delete(hObject);
                return;
            end
            P.maf.PYID=PY_ID;
            P.maf.nb_episodes=length(P.maf.start_times);
            P.maf.stream_label_list=P.hdr{1}.channels.labels; % take channels from first folder for now
            P.maf.nb_sources=length(P.maf.stream_label_list);
            P.maf.mef_included=ones(1,P.maf.nb_sources);

            P.dtoggle=0;
            P.typehdr=1;
        end
    else
        %Livestream initialization
        p0=pwd;
        P.LSLlib = lsl_loadlib();
        result = {};
        while isempty(result)
            result = lsl_resolve_byprop(P.LSLlib,'source_id', ['nkroom' num2str(RM)]); end 
        P.LSLinlet = lsl_inlet(result{1});
        
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
        end
        
        drive='R';
        PY_ID='PY99N999';
        P.maf.nb_stream=length(P.maf.stream_label_list);
        P.maf.nb_sources=length(P.maf.stream_label_list);
        P.maf.start_times(1)=date2usec(datestr(now));
        P.maf.end_times(1)=date2usec(datestr(now))+3600*1e6;
        P.dtoggle=0;
        cd(p0);
    end
    
    %%%%
    
    %% Common code MAF & REC
    str=sprintf('Patient Code: %s', PY_ID);
    set(P.patienttext, 'String', str, 'HorizontalAlign', 'center');

    if length(varargin)>=3,
        timestart=varargin{3};
        if ischar(timestart),
            P.windowstart=date2usec(timestart);
        else
            P.windowstart=timestart;
        end
    else
        P.windowstart=P.maf.start_times(1);
    end
    P.exclusion={};
    
    % Reading Events
    [ P.events_name, P.events_time, P.exclusion ] = CompileEvent( fullfile(data_path, PY_ID), PY_ID );
     set(P.EventListBox, 'String', P.events_name);
     
    [ P.GL, P.GS ] = read_patient_gridinfo( fullfile(data_path, PY_ID), PY_ID );
        
    P.drive=drive;
    P.PY_ID=PY_ID;
    P.inclusion={};
    
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
    if livestream, P.windowsize=5; end

    P.mode='monopolar';
    
    P.play=0;

    P.T0=P.maf.start_times(1);
    P.Tend=P.maf.end_times(end);

    inclusion={}; %{'PFD'};
    
    P.maf.UpdateChannelSelection(inclusion, P.exclusion);
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
    
    % Create MAIN Object axe
    P.eega=EEG_axes(P.mainoomeffigure, mainwindowpos);
    
    %Create UI axes for time navigation
    P.timeaxe=axes('Parent', P.mainoomeffigure ,'Units','Normalized','Position', timeaxispos);
    
    set(P.timeaxe, 'XTick', [], 'YTick', [], 'Box', 'off', 'visible','off');
    set(P.timeaxe, 'XLim', [P.T0 P.Tend]);
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
    
    if ~livestream,
        %%%%%%%%%%%%%%%%%%%%%%%%%%% First Read
        [P.maf, P.eeg, P.labels, P.xeeg]=GetEEGData(P, P.windowstart, P.windowsize*1e6);

        if P.typehdr,
            P.Fs=P.hdr{1}.file_fmt.Samp_rate;
        else
            P.Fs=P.maf.mef_streams(find(P.maf.mef_included==1, 1, 'first')).fs;
        end
    else
        P.Fs=double(P.LSLinfo.nominal_srate());
        P.ftoggle=1; % no filter
        datanum = P.Fs*P.windowsize;
        P.eeg = zeros(P.maf.nb_stream, datanum);
        P=GetLiveData(P);
    end
    P.FsD=P.Fs; % default to 1/10th only set if downsampling
    
    

    % Choose default command line output for MEFBrowser
    P.output = hObject;
    OOupdatemefplot(P);
end

%% Jump time bar
function PointNClickTimeBar(hObject, eventdata)
    P=guidata(hObject);
    axesHandle  = get(hObject,'Parent');
    coordinates = get(axesHandle,'CurrentPoint');  % X scale is in microseconds
    P.windowstart = round(coordinates(1,1)/1e6)*1e6; % round to nearest second
    [P.maf, P.eeg, P.labels, P.xeeg]=GetEEGData(P, P.windowstart, P.windowsize*1e6);
    OOupdatemefplot(P);
end

%% Update Channel selection from the check box array 
function UpdateChannelSelect(hObject, eventdata)
    global livestream;
    
    P=guidata(hObject);
    val=get(hObject, 'Value');
    ngrid=get(hObject, 'userdata');
    P.grid_inclusion(ngrid)=val;
    %add permanent exclusion
    exclusion_select=P.grid_label(find(P.grid_inclusion==0)); %#ok<FNDSB>
    exclusion=[exclusion_select(:); P.exclusion];
    P.maf=P.maf.UpdateChannelSelection(P.grid_label(find(P.grid_inclusion)), exclusion); %#ok<FNDSB>
    if livestream,
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
function MEF_KeyPressFcn(hObject, eventdata, handles) 

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

% group radio panel
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

% --- Executes on button press in pushbutton8. (Backward <)
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

% --- Executes on button press in pushbutton9. (Forward > )
function pushbutton9_Callback(~, ~, handles) %#ok<*INUSD,*DEFNU>
    P=handles;
    tread=P.windowstart+P.windowsize*1e6+1e6/P.Fs;
    shift=P.windowsize/10;
    if tread+shift*1e6<=P.Tend, 
        [P.maf, neeg, ~, xeeg]=GetEEGData(P, tread, shift*1e6);
        laneeg=size(neeg,2);
        P.eeg=[P.eeg(:,(laneeg+1):end) neeg(:,:)];
        P.xeeg=[P.xeeg((laneeg+1):end) xeeg];
        P.windowstart=P.windowstart+shift*1e6;
        %guidata(hObject, P);
        OOupdatemefplot(P);
    end
end

% --- Executes on button press in pushbutton10. (Backward - Backspace key)
function pushbutton10_Callback(~, ~, handles)
    P=handles;
    tread=P.windowstart-P.windowsize*1e6;
    shift=P.windowsize;
    if tread>=P.T0, 
        [P.maf, P.eeg, ~, P.xeeg]=GetEEGData(P, tread, shift*1e6);
        %P.xeeg=P.maf.mef_streams(find(P.maf.mef_included==1, 1, 'first')).tEEG;
        P.windowstart=P.windowstart-shift*1e6;
        %guidata(hObject, P);
        OOupdatemefplot(P);
    end
end

% --- Executes on button press in pushbutton11. (FF - Space bar)
function pushbutton11_Callback(~, ~, handles)
%tic;
    P=handles;
    tread=P.windowstart+P.windowsize*1e6+1e6/P.Fs;
    shift=P.windowsize;
    if tread+shift*1e6<=P.Tend, 
        [P.maf, P.eeg, ~, P.xeeg]=GetEEGData(P, tread, shift*1e6);
        %P.xeeg=P.maf.mef_streams(find(P.maf.mef_included==1, 1, 'first')).tEEG;
        P.windowstart=P.windowstart+shift*1e6;
        %guidata(hObject, P);
        OOupdatemefplot(P);
    end
%    disp(toc);
end

% --- Executes on button press in pushbutton12.
function pushbutton12_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%    handles.eega.ClearAllPlots();
global livestream;

    P=guidata(hObject);   
    P.play=1;
    guidata(hObject, P);
    while P.play,
        %tic;
        P=guidata(hObject);
        if livestream,
            % read live data
            P=GetLiveData(P);
            OOupdatemefplot(P);
        else
            pushbutton11_Callback(hObject, [], P);
        end
        drawnow;
        %refreshdata;
        %pause(0.05);
        %disp(toc);
    end
end

% --- Executes on button press in pushbutton13.
function pushbutton13_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    P=guidata(hObject);
    P.play=0;
    guidata(hObject, P);
end

% --- Executes on selection change in ws.
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

% --- Windows Size Popup
function ws_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    set(hObject, 'String', [0.001;0.01;0.05;0.1;0.25;0.5;1;2;4;5;10;20;30;60;120;300;600], 'Value', 11);
end

%%% Reading function
function [maf, eeg, labels, xeeg]=GetEEGData(P, windowstart, windowsize)

maf=P.maf;
if P.typehdr,
    [eeg, labels, xeeg]=RECreadeeg(P, windowstart, windowsize);
    if size(eeg,1)~=length(P.maf.mef_included),
        maf.nb_sources=size(eeg,1);
        maf.mef_included=ones(1,maf.nb_sources);
        maf.stream_label_list=labels;
    end
    eeg=eeg(find(maf.mef_included),:); %#ok<FNDSB>
    labels=labels(find(maf.mef_included)); %#ok<FNDSB>
else
    [maf, eeg, labels, xeeg]=maf.GetEEGData(windowstart, windowsize);
end
end

function P=GetLiveData(P)
    pT0=P.windowstart;
    data=P.eeg;
    datanum=size(data, 2);
    [chunk,~] = P.LSLinlet.pull_chunk();
    nreadframe=size(chunk,2);
    
    if (nreadframe>0)
        data(:, 1:datanum-nreadframe) = data(:, nreadframe+1:datanum);
        data(:, datanum-nreadframe+1:datanum)=chunk(find(P.maf.mef_valid),:);
    end
    T0=now;
    usec=rem(rem(T0,1)*86400,1)*1000*1000;
    P.windowstart=date2usec(datestr(T0))+usec;
    P.xeeg=P.windowstart+(1:size(data,2))*1e6/P.Fs;

    P.eeg=data(find(P.maf.mef_included),:); %#ok<FNDSB>
    P.labels=P.labels(find(P.maf.mef_included)); %#ok<FNDSB>

end


% --- Executes on selection change in EventListBox.
function EventListBox_Callback(hObject, eventdata, handles)
% hObject    handle to EventListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns EventListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from EventListBox
P=handles;

index_selected = get(hObject,'Value');
%list = get(hObject,'String');
event_time__selected = P.events_time(index_selected); 
P.windowstart=event_time__selected-P.windowsize*1e6/2;
[P.maf, P.eeg, P.labels, P.xeeg]=GetEEGData(P, P.windowstart, P.windowsize*1e6);

OOupdatemefplot(P);

end

% --- Executes during object creation, after setting all properties.
function EventListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EventListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
%P=handles;
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end


% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    P=handles;
    close(P.eventfigure);
    close(P.mainoomeffigure);
end
