function AxeShowMP(hObject, ~, ~)
    P=guidata(hObject);
    nplot=get(hObject, 'UserData');
    
    plot=P.eega.eegplots(nplot);
    
    figure('MenuBar','none','Toolbar','none', 'NumberTitle','off', 'Name', ['Matching Pursuit for ' plot.ylabel.String]); drawnow;
    MPinsert(plot.ydata, plot.fs, pow2(floor(log2(2*plot.fs))), pow2(floor(log2(2*plot.fs))-2), 'NRJ', 10, plot.fs/5, plot.ylabel.String);
    
    %P.eega.Redraw(P.eega.xtickenable);
    %guidata(hObject, P);
end
