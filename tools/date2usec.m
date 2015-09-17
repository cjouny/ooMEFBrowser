% DATE2USEC : Convert date from string to time in microseconds from 01/01/1970 (uUTC)
%
% CC Jouny - Johns Hopkins University - 2012-2013 (c) 
  

function utime=date2usec(date)

D0=719529; %datenum('01/01/1970 00:00:00')

try
    utime=round((datenum(date)-D0)*86400)*1e6;
catch
    disp('Unable to recognize a date format');
    utime=NaN;
end

