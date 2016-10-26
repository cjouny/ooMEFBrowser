function InfoWindow(maf)
%INFOWINDOW Display of the summary info contains in the MAF structure of a MAF file

global lmaf;
lmaf=maf;

mainF=figure('Name',['Detailed infos for ' maf.filename],...
    'MenuBar', 'default',...
    'NumberTitle','off',...
    'Units','normalized',...
    'Position',[0.25 0.25 0.5 0.5]...
    );

% Main Tabs
tabgp = uitabgroup(mainF,'Position',[0 0 1 1], 'TabLocation','top');
tabgeneral = uitab(tabgp,'Title',' General ');
tabstreams = uitab(tabgp,'Title',' Streams ');

% UI Constants
vspace=0.015;
hsize1=0.25;
xleft1=0.025;
hspace=0.025;

% General Tab
nb_gen_elements=20;
vsize=(1-(nb_gen_elements+1)*vspace)/nb_gen_elements;
xleft2=xleft1+hsize1+hspace;
hsize2=1-2*xleft1-hsize1-hspace;

nelem=1;
uicontrol(tabgeneral, 'Style','Edit','Units','Normalized','String','File Location: ', 'Position', [xleft1 1-nelem*vspace-nelem*vsize hsize1 vsize], 'FontName','Verdana', 'Enable','Inactive', 'BackgroundColor', [.75 .75 .75]);
uicontrol(tabgeneral, 'Style','Edit','Units','Normalized','String', maf.filepath,     'Position', [xleft2 1-nelem*vspace-nelem*vsize hsize2 vsize], 'FontName','Verdana', 'Enable','Inactive');
nelem=nelem+1;
uicontrol(tabgeneral, 'Style','Edit','Units','Normalized','String','File Name: ', 'Position', [xleft1 1-nelem*vspace-nelem*vsize hsize1 vsize], 'FontName','Verdana', 'Enable','Inactive', 'BackgroundColor', [.75 .75 .75]);
uicontrol(tabgeneral, 'Style','Edit','Units','Normalized','String', maf.filename,     'Position', [xleft2 1-nelem*vspace-nelem*vsize hsize2 vsize], 'FontName','Verdana', 'Enable','Inactive');
nelem=nelem+1;
uicontrol(tabgeneral, 'Style','Edit','Units','Normalized','String','PYID: ', 'Position', [xleft1 1-nelem*vspace-nelem*vsize hsize1 vsize], 'FontName','Verdana', 'Enable','Inactive', 'BackgroundColor', [.75 .75 .75]);
uicontrol(tabgeneral, 'Style','Edit','Units','Normalized','String', maf.PYID,     'Position', [xleft2 1-nelem*vspace-nelem*vsize hsize2 vsize], 'FontName','Verdana', 'Enable','Inactive');
nelem=nelem+1;
uicontrol(tabgeneral, 'Style','Edit','Units','Normalized','String','Nb. of Episodes: ', 'Position', [xleft1 1-nelem*vspace-nelem*vsize hsize1 vsize], 'FontName','Verdana', 'Enable','Inactive', 'BackgroundColor', [.75 .75 .75]);
uicontrol(tabgeneral, 'Style','Edit','Units','Normalized','String', maf.nb_episodes,     'Position', [xleft2 1-nelem*vspace-nelem*vsize hsize2 vsize], 'FontName','Verdana', 'Enable','Inactive');
nelem=nelem+1;
uicontrol(tabgeneral, 'Style','Edit','Units','Normalized','String','Nb. of Channels: ', 'Position', [xleft1 1-nelem*vspace-nelem*vsize hsize1 vsize], 'FontName','Verdana', 'Enable','Inactive', 'BackgroundColor', [.75 .75 .75]);
uicontrol(tabgeneral, 'Style','Edit','Units','Normalized','String', maf.nb_stream,     'Position', [xleft2 1-nelem*vspace-nelem*vsize hsize2 vsize], 'FontName','Verdana', 'Enable','Inactive');
nelem=nelem+1;
uicontrol(tabgeneral, 'Style','Edit','Units','Normalized','String','Start Time: ', 'Position', [xleft1 1-nelem*vspace-nelem*vsize hsize1 vsize], 'FontName','Verdana', 'Enable','Inactive', 'BackgroundColor', [.75 .75 .75]);
uicontrol(tabgeneral, 'Style','Edit','Units','Normalized','String', usec2date(maf.start_times(1)),     'Position', [xleft2 1-nelem*vspace-nelem*vsize hsize2 vsize], 'FontName','Verdana', 'Enable','Inactive');
nelem=nelem+1;
uicontrol(tabgeneral, 'Style','Edit','Units','Normalized','String','End Time: ', 'Position', [xleft1 1-nelem*vspace-nelem*vsize hsize1 vsize], 'FontName','Verdana', 'Enable','Inactive', 'BackgroundColor', [.75 .75 .75]);
uicontrol(tabgeneral, 'Style','Edit','Units','Normalized','String', usec2date(maf.end_times(end)),     'Position', [xleft2 1-nelem*vspace-nelem*vsize hsize2 vsize], 'FontName','Verdana', 'Enable','Inactive');

% Streams Tab
nb_button_per_row=10;
hbutsize=(1-(nb_button_per_row+1)*hspace)/nb_button_per_row;
nb_button_per_column=ceil(maf.nb_stream/nb_button_per_row);
vbutsize=(1-(nb_button_per_column+1)*vspace)/nb_button_per_column;

    for nch=0:maf.nb_stream-1,
        
        nbx=mod(nch, nb_button_per_row);
        nby=floor(nch/nb_button_per_row);
        uicontrol(tabstreams, 'Style','pushbutton','Units','Normalized','String', maf.mef_streams(nch+1).label, ...
            'Position', [xleft1+nbx*(hbutsize+hspace) 1-(nby+1)*vspace-(nby+1)*vbutsize hbutsize vbutsize], 'FontName','Verdana', 'Enable','On',...
            'CallBack', ['InfoChannel(' int2str(nch+1) ')'] );
        %
    end

end


