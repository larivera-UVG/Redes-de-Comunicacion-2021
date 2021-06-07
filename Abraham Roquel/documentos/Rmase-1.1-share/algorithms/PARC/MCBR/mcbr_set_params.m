function [param, i] = mcbr_set_params(param, i, groupID)

i=i+1;
param(i).name='LearningRate';              
param(i).default=1;              
param(i).group=groupID;

i=i+1;
param(i).name='ReSend';                    
param(i).default=1;                
param(i).group=groupID;

i=i+1;
param(i).name='ForwardDelta';                    
param(i).default=Inf;                
param(i).group=groupID;

% i=i+1;
% param(i).name='DelayScale';            
% param(i).default=1000;                
% param(i).group=groupID;

i=i+1;
param(i).name='MaxDelay';            
param(i).default=4000;                
param(i).group=groupID;

i=i+1;
param(i).name='FloodTemp';            
param(i).default=5;                
param(i).group=groupID;