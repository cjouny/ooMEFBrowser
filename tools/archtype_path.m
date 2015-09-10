%% ARCH_PATH: Return the path to drive according to the architecture
%%
%% CC Jouny - Johns Hopkins University - 2012-2013 (c) 
%%
function data_path=archtype_path(drive, type)

data_path=NaN;
if ~ischar(drive),
    disp('Invalid Drive Letter');
    return;
end

switch type,
    case {'MEF', 'HDR'}

        switch computer
             case 'MACI64'                          %% MAC
                 switch drive
                     case 'L'
                         data_path='/Users/cjouny/EEG';
                     case 'P'
                        data_path='/Volumes/P_Share/EEG';
                     case 'R'
                        data_path='/Volumes/R_Share/EEG';
                     case 'T'
                        data_path='/Volumes/ERL/EEG';
                     otherwise
                         %disp(['Unknown drive: ' drive]);
                         data_path=['/Volumes/' drive '_Share/EEG'];
                 end
            case {'PCWIN';'PCWIN32';'PCWIN64'}              %% WINDOWS
                 switch drive
                     case 'E'
                        data_path='E:\EEG';
                     case 'P'
                        data_path='P:\EEG';
                     case 'R'
                        data_path='R:\EEG';
                     case 'T'
                         data_path='T:\EEG';
                     otherwise
                         %disp(['Unknown drive: ' drive]);
                         data_path=[drive ':\EEG'];
                 end

             case {'GLNX86';'GLNXA64'}              %% LINUX
                 switch drive
                     case 'R'
                        data_path='/comp/rdrive/EEG';
                     case 'T'
                        data_path='/comp/tdrive/EEG';
                     otherwise
                         disp(['Unknown drive: ' drive]);
                 end
        end


    case 'BR'
        
        
    case 'NK',
        switch computer
            case {'PCWIN';'PCWIN32';'PCWIN64'}              %% WINDOWS
                switch drive
                    case 'Z'
                        data_path='Z:\';
                end
            case 'MACI64'
                switch drive
                    case 'Z'
                        data_path='/Volumes/NKData';
                end
        end

        
end






