function AxeShowPlot(hObject, ~, ~)
    P=guidata(hObject);
    nplot=get(hObject, 'UserData');
    P.eega.eegplots(nplot).ShowPlot();
    P.eega.Redraw(P.eega.xtickenable);
    guidata(hObject, P);
end
