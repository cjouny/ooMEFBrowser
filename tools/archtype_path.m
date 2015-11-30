% ARCH_PATH: Return the path to drive according to the architecture
%
% CC Jouny - Johns Hopkins University - 2012-2013 (c) 

function data_path=archtype_path(drive, type)

data_path=NaN;
if ~ischar(drive),
    disp('Invalid Drive Letter');
    return;
end
if length(drive)>1,
    disp('Too many character. Only input the drive letter (eg. "R")');
    return;
end
    

switch type,
    case {'MEF', 'HDR'}     % MEF and HDR formated files
        switch computer
             case 'MACI64'                          % MAC
                 switch drive
                     case 'T'
                        data_path='/Volumes/ERL/EEG';
                     otherwise
                         data_path=['/Volumes/' drive '_Share/EEG'];
                 end
            case {'PCWIN';'PCWIN32';'PCWIN64'}      % WINDOWS
                 data_path=[drive ':\EEG'];
             case {'GLNX86';'GLNXA64'}              % LINUX
                 switch drive
                     case 'R'
                        data_path='/comp/rdrive/EEG';
                     otherwise
                         disp(['Unknown drive: ' drive]);
                 end
        end


    case 'BR'       % Blackrock
        % Not use
        
    case 'NK',      % NK original files (mostly for NKmonitor)
        switch computer
            case {'PCWIN';'PCWIN32';'PCWIN64'}              % WINDOWS
                switch drive
                    case 'Z'
                        data_path='Z:\';
                end
            case 'MACI64'                                   % MAC
                switch drive
                    case 'Z'
                        data_path='/Volumes/NKData';
                end
        end

        
end






