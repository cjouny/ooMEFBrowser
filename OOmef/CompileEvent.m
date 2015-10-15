function [ events_name, events_time, exclusion ] = CompileEvent( data_path, PY_ID )

% COMPILEEVENT : Gather information about the events for the patient 

[nk_event_name, nk_event_time] = readcsvevent(data_path, PY_ID ); % From NK
    
    % Reading custom grid and seizure information if available
    try 
        [sztimes_cj, exclusion]=SZDB_CJ(PY_ID);
        sztimes_cj_name=usec2date(sztimes_cj, 'u');
        [sztimes_de]=SZDB_DE(PY_ID);
        sztimes_de_name=usec2date(sztimes_de, 'u');
    catch
        sztimes_cj=[];
        sztimes_cj_name={};
        sztimes_de=[];
        sztimes_de_name={};
    end
        
    %eventlisttime=[date2usec(sztimes_cj); date2usec(sztimes_de); [P.maf.event_list{:,1}]'];
    
    events_name=[sztimes_cj_name; sztimes_de_name; nk_event_name];
    events_time=[date2usec(sztimes_cj); date2usec(sztimes_de); nk_event_time];
    
    [~, indextime]=sort(events_time);
    
    events_name=events_name(indextime);
    events_time=events_time(indextime);
    
end

