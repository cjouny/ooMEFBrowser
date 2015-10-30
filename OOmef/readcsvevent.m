function [event_name, event_time] = readcsvevent(data_path, PYID )
%READCSVEVENT : Read CSV event list from NK

filename=fullfile(data_path, [PYID '.csv']);

event_name={};
event_time=[];

try
    if exist(filename, 'file'),
        M=readtable(filename, 'delimiter', '\t','ReadVariableNames',false);
        [nbevt, ~]=size(M);
        if nbevt~=0,
            event_name=cell(nbevt,1);
            event_time=zeros(nbevt,1);
            for ne=1:nbevt,
                event_name{ne}=M{ne,1}{1};
                string_time=M{ne,2}{1};
                millisec=sscanf(string_time(end-3:end), '%d');
                event_time(ne)=date2usec(string_time(1:end-4))+millisec*1e3;
            end
        end
    end
catch
    disp('Error while reading event from CSV list.');
end

end
