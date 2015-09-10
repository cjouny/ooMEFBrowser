% SZDB: List of seizures and channels to exclude per patient 
%
% CC Jouny - Johns Hopkins University - 2015 (c)
function [sztime, exclusion, grid_list, grid_size]=SZDB_CJ(PYID, nsz)

grid_list={};
grid_size={};

switch PYID,
     
    otherwise,
        exclusion={};
        sztime={};

end

if nargin>1,
   sztime=sztime{nsz};
end
    
