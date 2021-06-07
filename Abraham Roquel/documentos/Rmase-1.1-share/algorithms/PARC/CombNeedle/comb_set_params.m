function [param, i] = comb_set_params(param, i, groupID)

i=i+1;
param(i).name='DuplicationLength';            
param(i).default=1;                
param(i).group=groupID;

i=i+1;
param(i).name='CombSpace';            
param(i).default=3;                
param(i).group=groupID;

i=i+1;
param(i).name='QueryWidth';            
param(i).default=0.5;                
param(i).group=groupID;