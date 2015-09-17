classdef EEG_plot < handle
%
% Plot EEG in the EEG_Axe class
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
% CC Jouny - Johns Hopkins University - 2014 (c) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

properties (SetAccess=public)
    plot_handle                     % Handle
    position                        % Y position
    eegid
    xdata
    ydata
    fs
    linecolor=[0 0 0];
    linewidth=1;
    scale                           % display scale
    visible=1;
    scalefactor=1;                  % factor to apply to axe scale
    ylabel
    fontsize=7;
    analysis=0;                       % display of analysis results overlap
    hbox;
end

    methods
        % Initialize the plot with label
        function EEGPlot=EEG_plot(handle_axe, label, position)
            EEGPlot.plot_handle=plot(0,0, 'Parent', handle_axe);
            EEGPlot.ylabel=text(0, position, [label '  '], 'HorizontalAlignment','Right', ...
                'FontWeight', 'normal',...
                'FontName','Arial Rounded MT',...
                'Margin', 5,...
                'FontSize', EEGPlot.fontsize,...
                'Parent', handle_axe);
            EEGPlot.hbox=patch('XData', [0 100 100 0], ...
                'YData', [position-0.25 position-0.25 position+0.25 position+0.25], ...
                'EdgeColor','none', 'FaceColor',[0.6 0.8 0.6], 'FaceAlpha', 0.5,...
                'Parent', handle_axe);
        end

        % Set X and Y data (plotting)
        function Draw(EEGPlot)
            set(EEGPlot.plot_handle,...
                        'XData', EEGPlot.xdata,...
                        'YData', EEGPlot.position+EEGPlot.scale*EEGPlot.scalefactor*EEGPlot.ydata,...
                        'Color', EEGPlot.linecolor,...
                        'LineWidth', EEGPlot.linewidth);
            %refreshdata(EEGPlot.plot_handle);
            if EEGPlot.analysis,
                dd=log10(sum(EEGPlot.ydata.^2))/100;
                %dd=(linelength(EEGPlot.ydata, length(EEGPlot.ydata), length(EEGPlot.ydata)));
                %[dd, p]=HFDS(EEGPlot.ydata, EEGPlot.fs);
                %if p<0.05,
                EEGPlot.hbox.XData=[EEGPlot.xdata(1) abs(dd)*EEGPlot.xdata(end) abs(dd)*EEGPlot.xdata(end) EEGPlot.xdata(1)];
                %if dd<0, EEGPlot.hbox.FaceColor=[0.9 0.6 0.8];
                %else  EEGPlot.hbox.FaceColor=[0.6 0.9 0.8];
                %end
                %else
                %    EEGPlot.hbox.XData=[1 1 1 1]*EEGPlot.xdata(1);
                %end
            end
        end

        % Actions
        function ShowPlot(EEGPlot)
            set(EEGPlot.ylabel, 'Color', [0 0 0]);
            set(EEGPlot.hbox, 'Visible','on');
            set(EEGPlot.plot_handle, 'Visible','on');
        end
        function HidePlot(EEGPlot)
            set(EEGPlot.ylabel, 'Color', [0.75 0.75 0.75]);
            set(EEGPlot.hbox, 'Visible','off');
            set(EEGPlot.plot_handle, 'Visible','off');
        end
        function RemovePlot(EEGPlot)
            delete(EEGPlot.hbox);
            delete(EEGPlot.ylabel);
            delete(EEGPlot.plot_handle);
        end


    end

end

