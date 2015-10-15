function P=OOupdatemefplot(P)
%
% function to plot MEF data in EEGAxe class 
%
% CC Jouny - Johns Hopkins University - 2012-2015 (c) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Constants
%interval=1; %removed constant - channel space always 1
ne=1;
shade=0.2;
light=0.7;
i2b='NY';
codechoice=[shade shade shade;shade shade light;light shade shade;shade light shade; light shade light];
cbitchoice=[codechoice; codechoice; codechoice; codechoice; codechoice; codechoice; codechoice; codechoice; codechoice; codechoice; codechoice; codechoice; codechoice; codechoice; codechoice; codechoice; codechoice; codechoice; codechoice; codechoice; codechoice; codechoice; codechoice; codechoice; codechoice; codechoice; codechoice; ];


% Downsampling (moved to EEGPlot)
%if P.dtoggle,
%    P.FsD=floor(P.Fs/10); % downsample to 1/10 of original Fs
%    reeg=[P.xeeg(:)-P.xeeg(1) P.eeg'];  % downsample x and y
%    reeg=downsample(reeg, 10);
%    Dxeeg=reeg(:,1)';
%    Deeg=double(reeg(:,2:end)');
%else
    P.FsD=P.Fs;
    Dxeeg=P.xeeg(:)-P.xeeg(1);
    Deeg=double(P.eeg);
%end

% mode mono vs bipolar
if strcmp(P.mode,'bipolar'),
    [Feeg, Flabels, ~]=applymtgmef(Deeg, P.labels, P.GL, P.GS);
else
    Feeg=Deeg;
    Flabels=P.labels;
end

Feeg(isnan(Feeg))=0;

if any(isnan(Feeg(:))),
    disp('Cannot appply filter on NaN data');
    P.ftoggle=1;
    feeg=Feeg;
else
    %% Filtering
    filt=P.ftoggle;
    if filt>2, 
        fnorm = [P.filters(filt,1) P.filters(filt,2)]/(P.FsD/2); % for bandpass, here are the lower and upper cutoff respectively (80-400Hz)
        %[b1,a1] = butter(3 ,fnorm); % here the order of the filter is 10
        %feeg = filtfilt(b1,a1,Feeg')'; % band pass filter
        HGFilt = fir1(1000,fnorm);
        feeg=filtfilt(HGFilt, 1, Feeg')';
    elseif filt==2,
        h=fdesign.highpass('N,F3dB',3, P.filters(filt,1)/(P.FsD/2));
        d1=design(h, 'butter');
        feeg = filtfilt(d1.sosMatrix,d1.ScaleValues,Feeg')'; % high pass filter
    else
        feeg=Feeg;
    end
    
    % 60Hz filter in place
    if P.filter60,
        d = designfilt('bandstopiir','FilterOrder',20, ...
                   'HalfPowerFrequency1',59,'HalfPowerFrequency2',61, ...
                   'DesignMethod','butter','SampleRate',P.FsD);
        feeg = filtfilt(d,feeg')';
    end    
    
end
offset=length(Flabels);
nsplot=0;
[S, G, I]=channel_group(Flabels);
Gcode=unique(G);

if length(S)~=length(P.eega.eegplots),
    P.eega.ClearAllPlots();
end

% Loop on grid
for ngrid=1:length(Gcode), 

    idx=find(G==Gcode(ngrid));  % index of channels in this grid
    cl=cbitchoice(ngrid,:);     % Color for this grid

    for nbip=1:length(idx),     % Loop on channels in each grid

        nsplot=nsplot+1;
        if nsplot>length(P.eega.eegplots),
            P.eega.AddPlot(nsplot, S{nsplot});
        else
            set(P.eega.eegplots(nsplot).ylabel, 'String', [S{nsplot} '  ']);
        end
        P.eega.eegplots(nsplot).linecolor=cl;
        P.eega.eegplots(nsplot).fs=P.FsD;
        
        %% ZScore
        if P.zscore,
            P.eega.eegplots(nsplot).ydata=double(zscore(feeg(I(idx(nbip)),:)));
        else
            P.eega.eegplots(nsplot).ydata=double(feeg(I(idx(nbip)),:));
        end
        P.eega.eegplots(nsplot).eegid=I(idx(nbip));
        P.eega.eegplots(nsplot).xdata=Dxeeg; 
        

        offset=offset-1;
        ne=ne+1;
    end
    
end

%% Plot HFOs
set(P.eega.h, 'NextPlot','Add');
if P.hfotoggle,
    %% Calculate HFO on unfiltered signal
    [HFOO, HFOD]=HFO_mef(Feeg(I(idx(nbip)),:),   [80  200 10 4 0.1 5], P.FsD, 1);  % Ripples
    [HFOOf, HFODf]=HFO_mef(Feeg(I(idx(nbip)),:), [200 400 6  3 0.1 5], P.FsD, 1);% Fast Ripples
    
    for nx=1:length(HFOO),
        plotEvent(  P.eega.h, Dxeeg(HFOO(nx)), ...
                    Dxeeg(HFOO(nx)+HFOD(nx)), ...
                    offset+8*1/20, ...
                    offset-8*1/20, 'Lhfo');
    end
    for nx=1:length(HFOOf),
        plotEvent(  P.eega.h, Dxeeg(HFOOf(nx)), ...
                    Dxeeg(HFOOf(nx)+HFODf(nx)), ...
                    offset+10*1/20, ...
                    offset-10*1/20, 'Rhfo');
    end
end

% Plot Events
delete(findobj(P.eega.h, 'Tag', 'SZ'));
W0=P.windowsize;
YL=get(P.eega.h, 'YLim');
if ~isempty(P.events_time),
    SZtime=P.events_time;
    idxevt=find(SZtime>=P.xeeg(1) & SZtime<P.xeeg(end));
    if ~isempty(idxevt),
       for ne=1:length(idxevt),
           T0=SZtime(idxevt(ne))-P.xeeg(1);
           plotEvent(P.eega.h, T0, W0*1e6, YL(2), SZtime(idxevt(ne)), 'SZ', P.events_name{idxevt(ne)});
       end
    end
    
end



try %#ok<TRYNC> % because stand alone plot do not have those elements. Could be fixed !!
    str=sprintf('Downsampled: %c - Filter: %s - Zscored: %c - Page:%d s', i2b(P.dtoggle+1), P.filtername{P.ftoggle}, i2b(P.zscore+1), P.windowsize);
    set(P.statustext, 'String', str, 'HorizontalAlign', 'right', 'FontWeight','normal');
    str=sprintf('Time: %s', usec2date(P.windowstart,'u'));
    set(P.timetext, 'String', str, 'HorizontalAlign', 'left');
    set(P.timemarker, 'XData', [P.windowstart*[1 1] (P.windowstart+P.windowsize*1e6)*[1 1]]);
end

P.eega.Redraw(P.xtick, P.dtoggle);

guidata(P.mainoomeffigure, P);

%%%%%
end

function plotEvent(parent, x1, x2, y1, y2, type, event_string)

    switch type,
        case 'Lhfo',
            hp=patch([x1 x2 x2 x1],[y1 y1 y2 y2], [-1 -1 -1 -1], 'g', 'EdgeColor','none', 'Parent', parent);
            set(hp, 'FaceColor',[0.6 1 0.6]);
        case 'Rhfo',
            hp=patch([x1 x2 x2 x1],[y1 y1 y2 y2], [-1 -1 -1 -1], 'r', 'EdgeColor','none', 'Parent', parent);
            set(hp, 'FaceColor',[1 0.6 0.6]);
        case 'SZ',
            %disp([x1 x2]);
            %disp([y1 y2]);
            hp=patch([x1 x1+x2/400 x1+x2/400 x1],[y1 y1 -2 -2], [0 0 0 0], 'b', 'EdgeColor','none', 'Tag', type, 'Parent', parent);
            set(hp, 'FaceColor',[0.8 0.8 1], 'FaceAlpha', 0.5);
            hp=patch([x1 x1+x2/10 x1+x2/10 x1],[y1 y1 y1-y1/40 y1-y1/40], [0 0 0 0], 'b', 'EdgeColor','none', 'Tag', type, 'Parent', parent);
            set(hp, 'FaceColor',[0.8 0.8 1], 'FaceAlpha', 0.5);
            text(x1+x2/20, y1-y1/80, {event_string; usec2date(y2)}, 'Tag', type, 'HorizontalAlignment', 'Center', 'VerticalAlignment', 'Middle', 'FontWeight','Normal', 'FontSize', 7, 'Parent', parent);
    end
end


