function [param, i] = ant_set_params(param, i, groupID)

i=i+1;
param(i).name='AntStart';            
param(i).default=120000;                
param(i).group=groupID;

i=i+1;
param(i).name='AntRatio';            
param(i).default=2;                
param(i).group=groupID;

i=i+1;
param(i).name='WindowSize';            
param(i).default=10;                
param(i).group=groupID;

i=i+1;
param(i).name='C1';            
param(i).default=0.7;                
param(i).group=groupID;

i=i+1;
param(i).name='Z';            
param(i).default=1;                
param(i).group=groupID;

i=i+1;
param(i).name='RewardScale';            
param(i).default=0.3;                
param(i).group=groupID;

i=i+1;
param(i).name='DataGain';            
param(i).default=1.2;                
param(i).group=groupID;