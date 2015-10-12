function AxeHidePlot(hObject, ~, ~)
    P=guidata(hObject);
    nplot=get(hObject, 'UserData');
    P.eega.eegplots(nplot).HidePlot();
    P.eega.Redraw(P.eega.xtickenable, P.eega.decimate);
    guidata(hObject, P);
end
