%% Group Channel by Grid based on Name Root
%%
%%
%% CC Jouny - Johns Hopkins University - 2012-2013 (c) 
%%

function [S, Group, I, GroupLabel]=channel_group(labels)

for ni=1:length(labels),
    labels(ni)=strtrim(labels(ni)); %trim white
    FHlabels(ni)=strtok( labels(ni) ,'-'); %#ok<AGROW> %only sort on first part of bipolar
end

Group=zeros(1, length(FHlabels));
[S, I]=sort_nat(labels);
SFH=FHlabels(I);

for ne=1:length(S),
    S{ne}(abs(S{ne})==0)=[]; % Remove char(0)
    rootidx= isstrprop(SFH{ne}, 'alpha');
    root=SFH{ne}(rootidx);
    Rlabels{ne}=root;                                       %#ok<AGROW>
    
    if Group(1)==0,
        Group(1)=1;
        GroupLabel{1}=root;
    else
        if ~strcmp(root, Rlabels{ne-1}), % new grid start
            Group(ne)=Group(ne-1)+1;
            GroupLabel{Group(ne)}=root; %#ok<AGROW>
        else
            Group(ne)=Group(ne-1); % same grid
        end
    end
end

