classdef MAF_file < handle
    %% MAF_FILE Read MAF formatted EEG file
    %% 
    %%
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    %% CC Jouny - Johns Hopkins University - 2014 (c) 
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties (SetAccess = public)
        filepath                % path of the MAF file
        filename                % name of the MAF file
        PYID                    % Patient code
        allmafread=false        % True if all MAF content was read
        start_times             % Episodes start times
        end_times               % Episodes end times
        nb_episodes             % Number of Episodes
        current_episode         % Current Episode Read
        stream_label_list       % List of Sources
        nb_sources              % Number of sources in current episode
        mef_streams             % Vector of MEF streams / sources
        nb_stream               % Number of streams over entire dataset
        mef_valid               % Vector of Boolean - True if file exist
        mef_included            % Vector of Boolean - True for file to read
        nbevt                   % Number of events recorded
        event_list              % Structure of events / timestamps
    end
    
    properties (SetAccess = private)
        MAX_EPISODE = 512;      % Default max 512 episodes
        MAX_STREAM = 256;       % Default max 128 streams or channels
    end
    
    methods
        function MAFFile=MAF_file()                                             % Constructor
        end
        
        function MAFFile=OpenMAF(MAFFile, filepath, filename)                   % Initialization
            if exist(fullfile(filepath, filename), 'file')==2,
                MAFFile.filepath=filepath;
                MAFFile.filename=filename;
                MAFFile.current_episode=-1;
                MAFFile.mef_streams=MEF_stream.empty(MAFFile.MAX_STREAM,0);                    
            else
                %fprintf(2, 'MAF file cannot be found in the specified path.\n');
                ME = MException('MAF:OpenMAF','MAF file cannot be found in the specified path');
                throw(ME);
            end
        end

        function MAFFile=ReadALLMAF(MAFFile)                                    % Read entire MAF file - To be optimized!!

            useT=0;
            if exist( fullfile(MAFFile.filepath, [MAFFile.filename(1:end-1) 't']), 'file')==2,
                mmt=dir( fullfile(MAFFile.filepath, [MAFFile.filename(1:end-1) 't']) );
                mmf=dir( fullfile(MAFFile.filepath, [MAFFile.filename(1:end-1) 'f']) );
                if date2usec(mmt.date)>date2usec(mmf.date),                     % Use only if more recent than MAF file
                    useT=1;
                end
            end
            %useT=0;
            if useT,
                tmp=load(fullfile(MAFFile.filepath, [MAFFile.filename(1:end-1) 't']));  % Load MAT file if exist
                cpath=MAFFile.filepath;
                MAFFile=tmp.MAFFile;
                MAFFile.filepath=cpath;
                for ns=1:MAFFile.nb_stream,
                    for nf=1:MAFFile.nb_episodes,
                        MAFFile.mef_streams(ns).mef_files(nf).filepath=cpath;
                    end
                end
            else

                if ~ispc,
                    % For MAC and Linux
                    allmaf=mafread(fullfile(MAFFile.filepath, MAFFile.filename), -1);   % Need to add error checking and read events

                    MAFFile.nb_episodes=length(allmaf.Episode);
                    MAFFile.stream_label_list={};
                    IDcounter=0;
                    for nepisode=1:MAFFile.nb_episodes,                                                 % Loop over episode
                        MAFFile.start_times(nepisode)=allmaf.Episode{nepisode}.recording_start_time;
                        MAFFile.end_times(nepisode)=allmaf.Episode{nepisode}.recording_end_time;
                        for nsource=1:length(allmaf.Episode{nepisode}.Source),                          % Loop of sources
                            current_label=allmaf.Episode{nepisode}.Source{nsource}.label;
                            if ~any(strcmp(MAFFile.stream_label_list, current_label)),                  % Check if stream already exist for this label
                                MAFFile.mef_streams(nsource)=MEF_stream();                              % Add new stream if not
                                MAFFile.mef_streams(nsource).Init_Stream(current_label);                % Initialize the stream
                                IDcounter=IDcounter+1;                                                  % Stream counter
                                MAFFile.stream_label_list{IDcounter}=current_label;                     % Add label to the stream list
                                MAFFile.mef_streams(nsource).ID=IDcounter;                                              % Set stream ID
                                MAFFile.mef_streams(nsource).mef_files=MEF_file.empty(MAFFile.MAX_EPISODE, 0);
                            end
                            MAFFile.mef_streams(nsource).mef_files(nepisode)=MEF_file();                                                                        % Init new MEF File
                            MAFFile.mef_streams(nsource).mef_files(nepisode).CheckFileExist(MAFFile.filepath, allmaf.Episode{nepisode}.Source{nsource}.name);
                            MAFFile.mef_streams(nsource).mef_files(nepisode).label=current_label;                                                               % Add Label
                            if ~isempty(MAFFile.mef_streams(nsource).mef_files(nepisode).fileexist),
                                MAFFile.mef_streams(nsource).valid_files(nepisode)=MAFFile.mef_streams(nsource).mef_files(nepisode).fileexist;
                            else
                                MAFFile.mef_streams(nsource).valid_files(nepisode)=1; % assume exist if no info
                            end
                            if MAFFile.mef_streams(nsource).valid_files(nepisode),                                                                              % If File exist
                                MAFFile.mef_streams(nsource).start_times(nepisode)=allmaf.Episode{nepisode}.recording_start_time;                               % Add start and end times
                                MAFFile.mef_streams(nsource).end_times(nepisode)=allmaf.Episode{nepisode}.recording_end_time;
                            end
                        end
                    end
                    MAFFile.nb_stream=IDcounter;
                    MAFFile.allmafread=true;
                else
                    MAFFile=NMAF2MMAF(MAFFile, MAFFile.filepath, MAFFile.filename); % Using .NET MAF reader
                    if MAFFile.mef_valid,
                        MAFFile.allmafread=true;
                        save( fullfile(MAFFile.filepath, [MAFFile.filename(1:end-1) 't']), 'MAFFile'); % save a MAT of the MAF
                    end
                end
            end
        end
        
        % Fetch EEG data
        function [MAFFile, EEG, Labels, tEEG]=GetEEGData(MAFFile, time0, uduration)               % Get EEG Data for time and duration specified 
            if ~MAFFile.allmafread, ReadALLMAF(MAFFile); end  % Read MAF if not yet done
            if ischar(time0),
                utime0=date2usec(time0); % Convert time/string to microseconds
            else
                utime0=time0; 
            end
            % Validate times
            if utime0>MAFFile.end_times(end) || utime0+uduration<MAFFile.start_times(1),
                ME = MException('MAF:GetEEGData','Requested time is not contained in current folder.');
                %fprintf(2, 'Requested period is not contained in current folder.\n\tIf this is an ongoing recordings, check that the MAF file was updated.\n');
                throw(ME);
            end
            
            mefstreams=MAFFile.mef_streams;
            if ~isempty(MAFFile.mef_included),
                valids=MAFFile.mef_included;
            else
                valids=ones(1,length(mefstreams));
            end
            
            nbpts=zeros(1,MAFFile.nb_stream);
            for nch=1:MAFFile.nb_stream,
                if valids(nch),
                    mefstreams(nch)=GetEEGData(mefstreams(nch), utime0, uduration);
                    nbpts(nch)=length(mefstreams(nch).EEG);
                end
            end
            MAFFile.mef_streams=mefstreams;
            MAFFile.mef_included=valids;
            maxnpts=max(nbpts);
            EEG=zeros(sum(valids), max(nbpts), 'single');
            nvs=1;
            for nstr=MAFFile.nb_stream:-1:1,
                if valids(nstr),
                    if ~isempty(MAFFile.mef_streams(nstr).EEG),
                        EEG(nvs, :)=MAFFile.mef_streams(nstr).EEG;
                    end
                    Labels{nvs}=MAFFile.mef_streams(nstr).label;
                    nvs=nvs+1;
                end
            end
            refstream=find(MAFFile.mef_included==1, 1, 'first');
            if ~isempty(refstream),
                if maxnpts>0,
                    tEEG=MAFFile.mef_streams(refstream(1)).tEEG0+1e6*(0:size(EEG,2)-1)/MAFFile.mef_streams(refstream(1)).fs;
                else
                    tEEG=MAFFile.mef_streams(refstream(1)).tEEG0;
                end
            end
        end
        
        % Build the mef_included vector based on inclusion and exclusion
        function MAFFile=UpdateChannelSelection(MAFFile, ChInclusionList, ChExclusionList)
        
            MAFFile.mef_included=zeros(1, length(MAFFile.stream_label_list));
            for ne=1:length(MAFFile.stream_label_list),
                channel=MAFFile.stream_label_list{ne};
                rootidx= isstrprop(channel, 'alpha');
                rootchannel=channel(rootidx);
                MAFFile.mef_included(ne)=0;
                include=0;
                if ~isempty(ChInclusionList),                       % if non empty -> only selected grid
                    if any(strcmp(rootchannel, ChInclusionList)),   % if match any listed grid -> included
                        if any(strcmp(channel, ChExclusionList)),   % check exclusion individual channel
                            continue;
                        else
                            include=1;                              % if not excluded, then include  
                        end
                    else
                        if any(isstrprop(ChInclusionList{1}, 'digit')),  % include digit indicates full channel code
                            if any(strcmp(ChInclusionList, channel)),    % Match Inclusion 
                                include=1;
                            else
                                continue;
                            end
                        else
                            continue;                                   % no match -> pass
                        end
                    end
                end
                if ~include,                                        % already included cannot be excluded
                    if ~isempty(ChExclusionList),                       % if non-empty, process
                        if any(strcmp(rootchannel, ChExclusionList)),   % if match -> pass
                            continue;
                        end
                        if any(strcmp(channel, ChExclusionList)),   % if match -> pass
                            continue;
                        end
                    end
                end
                MAFFile.mef_included(ne)=1;
            end
            %disp('done');
        end
        
    end
    
end

