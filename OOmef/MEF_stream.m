classdef MEF_stream < handle
    %% MEF_STREAM: collection MEF_files
    %%
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    %% CC Jouny - Johns Hopkins University - 2014 (c) 
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
        label                   % Channel label
        ID                      % Unique Identifier
        mef_files               % Vector of MEF files / sources over time
        valid_files             % Fast index of valid files
        current_episode         % Current episode in the stream
        start_times             % Episodes start times
        end_times               % Episodes end times
        fs                      % Sampling frequency
        EEG                     % Requested EEG data portion
        tEEG0                   % Onset of data read
        tEEG                    % Corresponding time scale (in microseconds)
    end
    
    methods
        
        function MEFStream=MEF_stream()
        end

        function MEFStream=Init_Stream(MEFStream, label)
            MEFStream.label=label;
        end
        
        function MEFStream=GetEEGData(MEFStream, utime0, uduration)
            
            global warninglevel;
            
            % Search starting MAF index
            nfidx=find(utime0>=MEFStream.start_times & utime0<MEFStream.end_times);                             % find start 
            if isempty(nfidx),
                nfidx2=find(MEFStream.start_times>utime0 & MEFStream.start_times<utime0+uduration, 1, 'first');     % is any episode matching partially
                if isempty(nfidx2),
                    if warninglevel, fprintf(2, 'Period requested for channel %s is not in the dataset.\n', MEFStream.label); end
                    MEFStream.EEG=[];
                    return;
                else
                    if warninglevel, 
                        fprintf(2, 'Start time is not in the dataset. Skipping to next data point available.\n'); 
                    end
                    nfidx=nfidx2;
                end
            end
            if length(nfidx)>1,
                if warninglevel, fprintf(2, 'Overlapping time stamps found. Check MAF file.\n'); end
                MEFStream.EEG=[];
                return;
            end
            
            MEFStream.current_episode=nfidx;
            
            [MEFStream.mef_files(nfidx), eegread]=MEFStream.mef_files(nfidx).GetEEGData(utime0, uduration);
            n0=length(eegread);
                       
            if n0==0, % no data read - file missing or IO error
                if warninglevel, fprintf('Unable to read data from %s\n', MEFStream.mef_files(nfidx).filename); end
                return;
            else
                MEFStream.fs=MEFStream.mef_files(nfidx).fs;         % update fs in stream
                nsampleneeded=floor(uduration*MEFStream.fs/1e6);    % calculate total number of samples needed
                MEFStream.EEG=NaN*zeros(1, nsampleneeded);          % initialize the full EEG array
                MEFStream.EEG(1:n0)=eegread;                        % Copy the eegread data in the EEG matrix
                nsampleread=n0;
                x0=MEFStream.mef_files(nfidx).header.recording_start_time+((MEFStream.mef_files(nfidx).sample_start-1-MEFStream.mef_files(nfidx).skip_points)/MEFStream.mef_files(nfidx).header.sampling_frequency)*1e6;
            end
            
            %% Loop for other data if not complete
            if nsampleread<nsampleneeded,
                uduration1=uduration;
                nfset=nfidx+1;
                Tstop=0;
                Tnf=length(MEFStream.mef_files);
            
                while ~Tstop && nfset<Tnf,                                                              % Loop for remaining data   
                    
                    Ts=1/MEFStream.fs;
                    utime1=MEFStream.mef_files(nfset-1).header.recording_end_time + Ts*1e6 ; % next point is 1 period after the end of last file
                    
                    % duration left to read
                    uduration1=uduration1-(utime1-utime0);
                    MEFStream.current_episode=nfset;
                    
                    if uduration1>0,                                                                % continued 
                        
                        [MEFStream.mef_files(nfset), eegread]=MEFStream.mef_files(nfset).GetEEGData(utime1, uduration1);
                        n0=length(eegread);
                        if n0>0,
                            MEFStream.EEG(nsampleread+1:nsampleread+n0)=eegread;
                            nsampleread=nsampleread+n0;
                        else
                            disp('Unable to read the data - Reading function incomplete');
                            return;
                        end
                    else
                        Tstop=1;
                    end
                    
                    if nsampleread>=nsampleneeded, Tstop=1; end
                    
                    if Tstop, break; end
                    nfset=nfset+1;
                    
                end
            end
            
            % Generic time scale
            MEFStream.tEEG0=x0;

        end
        
    end
    
end

