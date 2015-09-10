% APPLYMTGMEF: Function to automatically create bipolar montage on EEG from MEF files
%
%
% 02/2015: Fix for over 64 channels grid
% 08/2015: Fix for condition that removed 5x channels on 64 grid
% 08/2015: Added support for grid list/grid size infos
%
% CC Jouny - Johns Hopkins University - 2012-2015 (c) 
% 
function [Feeg, Flabels, Blabels, Lindex]=applymtgmef(eeg, labels, gl, gs)

if nargin==2,
    gl=[];
    gs=[];
end

ne=0;
DCidx=[];
[S, G, I]=channel_group(labels);
Gcode=unique(G);

paireeg=zeros(length(labels), 2)*NaN; %Maximum size

for ngrid=1:length(Gcode),
    
    idx=find(G==Gcode(ngrid));
    grid_size=length(idx);
    rootidx= isstrprop(S{idx(1)}, 'alpha');
    
    if ~isempty(gl),
        gridindex=find(strcmp(gl,S{idx(1)}(rootidx)));
        if ~isempty(gridindex),
            grid_size=prod(gs(gridindex,:));
        end
    else
        gridindex=[];
    end
    
    if strcmp(S{idx(1)}(rootidx), 'DC'),
        DCidx=idx;
        continue;
    end
    
    for nbip=1:length(idx)-1,
        numb1=str2double(strtrim(labels{I(idx(nbip))}(find(rootidx, 1, 'last' )+1:end)));
        numb2=str2double(strtrim(labels{I(idx(nbip+1))}(find(rootidx, 1, 'last' )+1:end)));
        
        % Pair matching - continue skip the invalid pairs
        if abs(numb2-numb1)>1, continue; end
        if grid_size>64,
            if mod(grid_size,16)==0 && mod(numb1,16)==0, continue; end %% If grid_size incorrect (eg. only 63 channels) this fails !!
        else
            if (mod(grid_size,8)==0 || mod(grid_size,8)==7)&& mod(numb1,8)==0, continue; end %% If grid_size incorrect (eg. only 63 channels) this fails !!
        end
        if (mod(grid_size,5)==0 ) && mod(numb1,5)==0, continue; end
        
        %% || mod(grid_size,5)==4 remove because cause lost of channels on 64 contacts grid. Not sure what case it was for. 
        
        ne=ne+1;
        paireeg(ne,:)=[idx(nbip) idx(nbip+1)];
    end
end

Lindex=[I(paireeg(~isnan(paireeg(:,1)),1))' I(paireeg(~isnan(paireeg(:,2)),2))'];

if ne==0,
    disp('Unable to apply a bipolar montage. Unipolar EEGs returned.');
    Feeg=eeg;
    Flabels=labels;
    Blabels=labels;
else
    Feeg=zeros(ne, size(eeg,2));
    for np=ne:-1:1,
        %Feeg(np,:)=diff( eeg( [ I(paireeg(np,1)) I(paireeg(np,2))] ,:), 1, 1);
        if ~isempty(eeg),
            Feeg(np,:)=eeg(I(paireeg(np,1)),:)-eeg(I(paireeg(np,2)) ,:);
        end
        
        Flabels{np}=[strtrim(S{paireeg(np,1)}) '-' strtrim(S{paireeg(np,2)})];
        Blabels{np}={strtrim(S{paireeg(np,1)}); strtrim(S{paireeg(np,2)})};
    end
    
    if ~isempty(DCidx),             % DC channels are added back unpaired
        if ~isempty(eeg),
            Feeg=[Feeg; eeg(DCidx,:)];
        end
        Flabels=[Flabels S{DCidx}];
        Blabels=[Blabels S{DCidx}];
    end

    
end





