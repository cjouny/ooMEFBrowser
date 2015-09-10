classdef MEF_file < handle
    %% MEF_FILE Read MEF formatted EEG file
    %% 
    %%
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    %% CC Jouny - Johns Hopkins University - 2014 (c) 
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties (SetAccess = public)
        filepath            % Path of MEF file
        filename            % MEF filename
        label               % Channel label
        sample_start        % Start sample of points currently read
        sample_end          % End sample of points currently read
        skip_points
    end
    properties (SetAccess = private)
        fileexist           % True if file exists
        header              % MEF Header
        fs                  % Sampling Frequency
        nbpt                % Number of points currently read
    end
    
    methods
        function MEFFile=MEF_file()                                         % Constructor
        end

        function MEFFile=CheckFileExist(MEFFile, filepath, filename)        % Initialize Strings and check file exist (!slow on some OS)
            MEFFile.filepath=filepath;
            MEFFile.filename=filename;
            if exist(fullfile(filepath, filename), 'file')==2,
                MEFFile.fileexist=true;
            else
                MEFFile.fileexist=false;
            end
        end
        function MEFFile=CheckIFileExist(MEFFile)                           % Check file exist if strings already set
            if exist(fullfile(MEFFile.filepath, MEFFile.filename), 'file')==2,
                MEFFile.fileexist=true;
            else
                MEFFile.fileexist=false;
            end
        end
        
        function MEFFile=OpenFile(MEFFile, filepath, filename)              % Open MEF file
            if isempty(MEFFile.fileexist),
                MEFFile=CheckFileExist(MEFFile, filepath, filename);
            end
            if MEFFile.fileexist,
                MEFFile.filepath=filepath;
                MEFFile.filename=filename;
                MEFFile.header=MEF_header();
                MEFFile.header.ReadFromFile(fullfile(filepath, filename));
                MEFFile.fs=MEFFile.header.sampling_frequency;
                MEFFile.label=deblank(MEFFile.header.channel_name);
            end
        end
        function MEFFile=OpenIFile(MEFFile)
            if isempty(MEFFile.fileexist),
                MEFFile=CheckIFileExist(MEFFile);
            end
            if MEFFile.fileexist,
                MEFFile.header=MEF_header();
                MEFFile.header.ReadFromFile(fullfile(MEFFile.filepath, MEFFile.filename));
                MEFFile.fs=MEFFile.header.sampling_frequency;
                MEFFile.label=deblank(MEFFile.header.channel_name);
            end
        end
        
        
        %% READ DATA by Sample
        function [MEFFile, eegfiledata]=GetSampleEEG(MEFFile, S0, S1)
            
            if ~ispc, % Using original MEF sources code from Mayo (for MacOS & Linux)
                        % From G:\Box Sync\work\sources\git\mef_lib_2_1_MAC
                yread=decomp_mef_mex(fullfile(MEFFile.filepath, MEFFile.filename), double(S0), double(S1), '');
                eegfiledata=single(yread)*MEFFile.header.voltage_conversion_factor; % Calibration appplied here
            end
            if ispc,  % Using MS Visual Studio compiled library with integrated calibration scaling
                        % From G:\Box Sync\sources\git\mexMEF\x64\Release\mexMEFRead.mexw64
                        % PS: original Mayo code does not compile under
                        % Windows
                eegfiledata=single(mexMEFRead(fullfile(MEFFile.filepath, MEFFile.filename), double(S0), double(S1)));
            end

            MEFFile.nbpt=length(eegfiledata);
            MEFFile.sample_start=double(S0);
            if length(eegfiledata)==(S1-S0+1),
                MEFFile.sample_end=double(S1); % if all points needed read, end is S1
            else
                MEFFile.sample_end=double(S0)+length(eegfiledata)-1; % is points missing, end is S0 + length(data)
            end
            
        end % end readsampleeeg
        
        %% Get EEG Data by time and duration
         function [MEFFile, EEG]=GetEEGData(MEFFile, utime0, uduration)
             
             if isempty(MEFFile.header), 
                MEFFile.OpenIFile();
                if ~MEFFile.fileexist,
                    EEG=[];
                    return;
                end
             end
            
            total_dur_sample=floor(uduration*MEFFile.header.sampling_frequency/1e6);  % total number of sample requested
            
            Ts=1/MEFFile.header.sampling_frequency*1e6; %sampling period
            
%             Xpts=(utime0-MEFFile.header.recording_start_time)*MEFFile.header.sampling_frequency/1e6;
%             if Xpts>=0,
%                 offset_sample=max(1,floor(Xpts)+1);  % start in this file. Start reading at offset_sample
%                 skippoints=0;                        % no skip
%             else
%                 offset_sample=1;                      % start was before this file start - read from beginning
%                 skippoints=floor(-Xpts)-1;            % NaN points to add at beginning as requested time is before this file onset 
%             end

            % Exact match +/- Ts
            if abs(utime0-MEFFile.header.recording_start_time)<Ts, % within +/- Ts assume match
                skippoints=0;
                offset_sample=1;
            end
            
            % Better offset points calculation
            if (utime0>=(MEFFile.header.recording_start_time+Ts)), % request is at least one offset point after the start of the file
                %offset_sample=length(MEFFile.header.recording_start_time:Ts:utime0);
                offset_sample=floor((utime0-MEFFile.header.recording_start_time)/Ts)+1;
                %if offset_sample~=offset_sample_bis,
                %    disp(offset_sample_bis);
                %end
                skippoints=0;
            end
           
            % Better Skip points calculation
            if ((utime0+Ts)<=MEFFile.header.recording_start_time), % file starts at least one skip point after the requested time
                skippoints=length(utime0:Ts:(MEFFile.header.recording_start_time-Ts));
                offset_sample=1;
            end
            
            
            request_end_sample=offset_sample+total_dur_sample-1-skippoints;
            
            if request_end_sample>MEFFile.header.number_of_samples,
                end_sample=MEFFile.header.number_of_samples;            % Stop at end of file
                total_dur_sample=total_dur_sample-(request_end_sample-MEFFile.header.number_of_samples);
            else
                end_sample=request_end_sample;
            end
                
            EEG=NaN*zeros(1, total_dur_sample, 'single');
            
            if end_sample>offset_sample,
                [MEFFile, EEGbuffer]=MEFFile.GetSampleEEG(offset_sample, end_sample);
                EEG(skippoints+1:skippoints+1+length(EEGbuffer)-1)=EEGbuffer;
            end
            
            MEFFile.skip_points=skippoints;
            
         end
             
             
        
        
    end
end

