% Retrieve the MEF-formatted EEG channels
%
% Example: 
% [eeg, xeeg, labels]=readOOmefeeg('R', 'PY12N005', '13-Aug-2004 23:43:00', 120, {'DC'; 'EKG'}, {}, 'bipolar');
%
% drive: Drive letter where data located
% PY_ID: PY of the patient dataset
% stime0: string formatted date OR microseconds value in uUTC format of MEF
% duration: duration requested in seconds
% ChExclusionList: channel group to exclude (default: none)
% ChInclusionList: channel group to include (default: all)  
% !!!!! Inclusion override exclusion (eg. it keeps ADC channels even when removing DC channels)
%
%
% eeg: EEG values scaled with the calibration
% xeeg: time stamp of the sampled values (reconstructed)
% labels: labels of the EEG channels read
% maf: data structure
%
% CC Jouny - Johns Hopkins University - 2012-2015 (c) 
%

function [eeg, xeeg, labels, maf]=readOOmefeeg(drive, PYID, stime0, duration, ChExclusionList, ChInclusionList, mode) 

global warninglevel;
warninglevel=1; % Default to 1 to show warnings. Set to zero to disable all warnings. 

eeg=NaN; 
xeeg=NaN;

if strcmp(ChInclusionList, '*'),
    ChInclusionList={};
end

% Input validation
if ~ischar(drive), error('readmefeeg:ArgCheck', 'Drive must be a letter'); end
if ~ischar(PYID), error('readmefeeg:ArgCheck', 'PY_ID must be a string'); end
% Start time
if ischar(stime0),
    utime0=date2usec(stime0);                                               % str to microseconds
else
    utime0=stime0;
end
% Duration
if isnumeric(duration),
    if duration>0, 
        uduration=duration*1e6;
    else
        error('readmefeeg:ArgCheck', 'Duration must be greater then zero');
    end
else
    error('readmefeeg:ArgCheck', 'Duration must be a positive real number');
end
% Montage
if strcmp(mode, 'bipolar'), bipolar=1; else bipolar=0; end

GL = {};
GS = [];
% Inclusion channels
if ~isempty(ChInclusionList),
    if any(isstrprop(ChInclusionList{1}, 'digit')),
        if bipolar,
            if warninglevel>=2, warning('readmefeeg:ArgCheck', 'Warning: Bipolar mode and Single channel inclusion detected. \nAutomatic bipolar montage may failed to assess grid size correctly.'); end
        end
    end
end

% Read MAF
maf=MAF_file;
data_path =  archtype_path(drive, 'MEF');
if isnan(data_path), error('readmefeeg:ArgCheck', 'Invalid drive input'); end
if ~exist(fullfile(data_path, PYID), 'file'), error('readmefeeg:ArgCheck', ['Unable to find the PY folder: ' PYID]); end
mafpath=fullfile(data_path, PYID);
maffile=fullfile(mafpath, [PYID '.maf']);
if exist(maffile, 'file'),
    maf.OpenMAF(mafpath, [PYID '.maf']);
    maf=maf.ReadALLMAF();
else
    error('readmefeeg:ArgCheck', 'Unable to read the MAF file.');
end
maf.mef_included=zeros(1, length(maf.stream_label_list));

for ne=1:length(maf.stream_label_list),

    channel=maf.stream_label_list{ne};
    rootidx= isstrprop(channel, 'alpha');
    rootchannel=channel(rootidx);
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
    maf.mef_included(ne)=1;
end

maf.nb_stream=length(maf.mef_streams);
[maf, eeg, labels, xeeg]=maf.GetEEGData(utime0, uduration);

if bipolar, 
    [eeg, labels]=applymtgmef(eeg, labels, GL, GS);
end

end                               

