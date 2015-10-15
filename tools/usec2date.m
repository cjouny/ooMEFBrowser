% USEC2DATE: Convert time in microseconds from 01/01/1970 (uUTC) to readable date
%
% Use formatstr='u' to get the milli and microseconds.
%
% CC Jouny - Johns Hopkins University - 2012-2013 (c)  


function dateconvert=usec2date(timenum, formatstr)

if nargin==1,
    formatstr=0;
end

if isempty(timenum),
    dateconvert={};
    return;
end

if length(timenum)>1,
    for ni=length(timenum):-1:1,
        dateconvert{ni}=usec2date(timenum(ni), formatstr); 
    end
    return;
end

D0=719529; %datenum('01/01/1970 00:00:00')

timenum=double(timenum);

timesec=floor(timenum/1e6);         % full seconds
lowsec=floor(timenum-timesec*1e6);  % remaining usec < 1s

microsec=0;
if ischar(formatstr),
    if strcmp(formatstr, 'u'),
        formatstr=0;
        microsec=1;
    end
end

try
    dateconvert=datestr(floor(timenum/1e6)/86400+D0, formatstr);
    if microsec,
        msec=floor(lowsec/1000);    % milliseconds
        usec=mod(lowsec,1000);      % remainer = microseconds
        dateconvert=sprintf('%s %3dms %3dus', dateconvert, msec, usec);
    end
catch
    disp('Unable to convert to a date');
    dateconvert=NaN;
end

