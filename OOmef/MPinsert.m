% Direct signal to MP plot analysis for MEFBrowser
%
% CC Jouny - Johns Hopkins University - 2012-2015 (c) 
%
function gad = MPinsert(y, Fs, wl, ws, mode, threshold, ylimmax, label)

%preset
epsilon=1e-6;
powermax=8;
xeps=sqrt(-log(epsilon)/pi);
fontsizeS=6;
fontsizeL=8;
fontsizeM=7;
reduc=3;

y=y(:);
np=length(y);

%% GABOR ANALYSIS
parfor ni=1:1+floor((np-wl)/ws),
    idx=(1+(ni-1)*ws):(wl+(ni-1)*ws);
    X=y(idx);   
    books{ni}=mexGaborVS(X, mode, threshold);
    gad(ni)=2*length(books{ni})/wl;
end


%% Rebuild TF map from books
th=sqrt(threshold);
octlimit=[1 log2(wl)];
frlimit=[0 Fs/2];

winlen=wl/Fs;
winshift=ws/Fs;
cx=2.^reduc;

% determine size final matrix
ss=ceil(winlen*Fs);
np2=nextpow2(ss);
ssx=ss/cx;
ws=round(winshift*Fs/cx);
if ws~=winshift*Fs/cx,
	disp('Non-integer ws will cause mis-alignement !');
end
ssa=ssx+(length(books)-1)*ws;

% Create main Matrice and atom and gad vector
nrj=zeros(ssa, ss/2+1);
d=zeros(1, length(books));

for nbook=1:length(books),

    % Test for "empty" book (has 1 element)
    if numel(books{nbook})==1,
        continue;
    end
    
    for ib = 1:size(books{nbook},2), %Loop on atoms
        
        shift=books{nbook}(3,ib);
        oct=books{nbook}(1,ib);
        freq=books{nbook}(2,ib);
        mod=books{nbook}(4,ib);
        mod2=mod*mod;
    
        % frequency selection
        if freq<ss*frlimit(1)/Fs || freq >ss*frlimit(2)/Fs,
          continue;
        end   
	
    	%Reject 60Hz and harmonics
        if freq>=ss*59/Fs && freq <=ss*61/Fs && oct>4, 
            continue;
        end
        if freq>=ss*119/Fs && freq <=ss*121/Fs && oct>4, 
            continue;
        end
        if freq>=ss*179/Fs && freq <=ss*181/Fs && oct>4, 
            continue;
        end

        if reduc>0,
            shift = floor(shift/(2^reduc));
            freq  = floor(freq);
        end
        
        % octave selection
        if oct<octlimit(1) || oct >octlimit(2),
            continue;
        end        
    
        % criterion Threshold
        if (th<0 && mod>abs(th)) || (th>0 && mod<th),
            continue;
        end
                
        d(nbook)=d(nbook)+1;
        
        if oct == 0,                                                                                % DIRAC
            nrj(shift+1, :)=nrj(shift+1, :)+mod2; 
        elseif oct == np2,                                                                          % FOURIER
            xbook=(1:ssx)+(nbook-1)*ws;
            nrj( xbook , freq+1)=nrj( xbook , freq+1)+mod2; 
        else                                                                                        % GABOR
            scalet=2^(oct-reduc);
            scalef=ss/(2^oct);

            ranget=ceil(xeps*scalet);
            rangef=ceil(xeps*scalef);

            t=(-ranget:ranget)';
            f=-rangef:rangef;
            
            ts=t+shift+(nbook-1)*ws+1;
            fs=f+freq+1;

            its=find(ts>0 & ts <=ssa);
            nts=ts(its);
            ifs=find(fs>0 & fs<=ss/2);
            nfs=fs(ifs);

            nrj(nts, nfs) =  mod2 * exp(-pi*(t(its)/scalet).^2)*exp(-pi*(f(ifs)/scalef).^2)+nrj(nts, nfs);
        end
    end
end
% End on book loop

xt=((1:size(nrj,1))-1)/ssx*(ss/Fs);
yf=((1:size(nrj,2))-1)*Fs/ss;
nrj=nrj';
gad=2*d/ss;

%scale energy in Bel
nrj=log10(nrj);

set(gcf, 'color','w');

%drawing TF map
axes('units','norm', 'fontname','Verdana'); %, 'fontSize', fontsizeS);
imagesc(xt, yf, nrj);
axMP=gca; 
set(axMP, 'ydir','norm'); colormap(jet)
xlabel('Time (sec)');
ylabel('Frequency (Hz)');
set(axMP, 'clim', [0 powermax]);
set(axMP, 'ylim', [0 ylimmax], 'box','off', 'tickdir','out');
set(axMP,'units','norm', 'fontname','Verdana', 'fontSize', fontsizeM);
title(axMP, label, 'fontname','Verdana','FontSize', fontsizeM);

