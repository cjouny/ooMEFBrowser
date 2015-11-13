classdef EEG_axes < handle
%
% Class for MEF Browser axe
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
% CC Jouny - Johns Hopkins University - 2014 (c) 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
        h                                   % Axe handle
        parentfigure                        % Parent Figure (for uicontext)
        axisfontsize=8;                     % Axis Font Size
        mainfont='Arial Rounded MT';        % Axis Font
        backgroundcolor=[0.98 0.98 0.92];   % Background
        eegplots=EEG_plot.empty(256,0);     % Array of plot handles
        visibleplots;                       % List of plots to show/hide
        decimate;                           % Flag for decimation
        nplot=0;                            % Number of plots
        xspan                               % Span on X axis
        xtick=1e6;                          % Space between X lines - default 1s = 1e6 us
        xtickenable=0;
        hXtick                              % handles for xtick lines
        hXlabel                             % handles for time labels
        scale=0.0025;                       % Overall scaling factor
    end
    
    methods
        function EEGAxe=EEG_axes(parent, position)
            EEGAxe.parentfigure=parent;
            EEGAxe.h=axes('Parent', parent, 'Position', position, 'FontSize', EEGAxe.axisfontsize, 'FontName',EEGAxe.mainfont, 'Units','normalized');
            set(EEGAxe.h, 'Color', EEGAxe.backgroundcolor, 'Box', 'on');
            set(EEGAxe.h, 'TickLength',[0.005 0]);
            set(EEGAxe.h, 'XTick', []);
            set(EEGAxe.h, 'YLim', [-150 150], 'YDir','Reverse');
            set(EEGAxe.h, 'YTick', [-100 0 100], 'YTickLabel','');
            set(EEGAxe.h, 'NextPlot','Add');
        end
        
        function EEGAxe=plotXtick(EEGAxe, enable)
            X0=get(EEGAxe.h, 'XLim');
            Y0=get(EEGAxe.h, 'YLim');
            try
                delete(EEGAxe.hXtick);
                delete(EEGAxe.hXlabel);
            catch
                % no tick to delete
            end
            ntick=0;
            if enable,
                for tick=X0(1):EEGAxe.xtick:X0(2),
                    ntick=ntick+1;
                    EEGAxe.hXtick(ntick)=plot(tick*[1 1], [Y0(1) Y0(2)], '--', 'Color', [0.7 0.9 0.7], 'Parent', EEGAxe.h);
                end
            end
        end
        
        function EEGAxe=AddPlot(EEGAxe, nplot, label)
            EEGAxe.eegplots(nplot)=EEG_plot(EEGAxe.h, label, nplot);
            EEGAxe.eegplots(nplot).position=nplot;
            EEGAxe.visibleplots(nplot)=1;
            %EEGAxe.eegplots(nplot).plot_handle=plot(EEGAxe.h, 0,0);
            EEGAxe.eegplots(nplot).scale=EEGAxe.scale;
            EEGAxe.nplot=nplot;
            set(EEGAxe.h, 'YLim', [-0.01*EEGAxe.nplot 1.05*EEGAxe.nplot]);
            
            EEGPlotUImenu = uicontextmenu('Parent', EEGAxe.parentfigure);
            uimenu(EEGPlotUImenu, 'Label',['Hide ' label], 'UserData', nplot, 'Callback', @AxeHidePlot);
            uimenu(EEGPlotUImenu, 'Label',['Show ' label], 'UserData', nplot, 'Callback', @AxeShowPlot);
            uimenu(EEGPlotUImenu, 'Label','Calculate MP', 'UserData', nplot, 'Callback', @AxeShowMP, 'Separator','on');
            set(EEGAxe.eegplots(nplot).plot_handle,'uicontextmenu',EEGPlotUImenu);
            set(EEGAxe.eegplots(nplot).ylabel,'uicontextmenu',EEGPlotUImenu);
        end
        
        function EEGAxe=Scale(EEGAxe, factor)
            EEGAxe.scale=EEGAxe.scale*factor;
            for ns=1:EEGAxe.nplot,
                EEGAxe.eegplots(ns).scale=EEGAxe.scale;
            end
            EEGAxe.Redraw(EEGAxe.xtickenable, EEGAxe.decimate);
        end
        
        function EEGAxe=Redraw(EEGAxe, enablextick, dtoggle)
            EEGAxe.xtickenable=enablextick;
            EEGAxe.decimate=dtoggle;
            for ns=EEGAxe.nplot:-1:1,
                EEGAxe.eegplots(ns).Draw(EEGAxe.decimate); % Redraw individual plots
                xmini(ns)=min(EEGAxe.eegplots(ns).xdata);
                xmaxi(ns)=max(EEGAxe.eegplots(ns).xdata);
            end
            EEGAxe.plotXtick(enablextick);
            set(EEGAxe.h, 'xlim', [min(xmini) max(xmaxi)]);
        end
        
        function EEGAxe=ClearAllPlots(EEGAxe)
            for ns=EEGAxe.nplot:-1:1,
                EEGAxe.eegplots(ns).RemovePlot();
                delete(EEGAxe.eegplots(ns));
            end
            EEGAxe.eegplots=EEG_plot.empty(256,0);
            EEGAxe.nplot=0;
        end
        
    end
    
end

