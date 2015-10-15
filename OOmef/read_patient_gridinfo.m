function [ grid_name, grid_size ] = read_patient_gridinfo( data_path, PYID )
%READGRIDINFO Return the size of the grid/strip implants if available

filename=fullfile(data_path, [PYID '.dat']);

grid_name={};
grid_size=[];

if exist(filename, 'file'),
    M=readtable(filename, 'delimiter', '\t','ReadVariableNames',false);
    [nbrows, ~]=size(M);
    if nbrows~=0,
        grid_name=cell(nbrows,1);
        grid_size=zeros(nbrows,2);
        for ne=1:nbrows,
            grid_name{ne}=M{ne,1}{1};
            grid_size(ne,:)=[M{ne,2}(1) M{ne,3}(1)];
        end
    end
end


end