function [param, i] = aodv_set_params(param, i, groupID)

i=i+1;
param(i).name='RREP_DELAY';                    
param(i).default=1.5*40000;  %1.5s
param(i).group=groupID;


i=i+1;
param(i).name='RREQ_TIMEOUT';                    
param(i).default=10*40000;                
param(i).group=groupID;

i=i+1;
param(i).name='RREQ_DELAY';                    
param(i).default=0.1*40000;                
param(i).group=groupID;

i=i+1;
param(i).name='AODV_RQCACHE_SIZE';                    
param(i).default=10;                
param(i).group=groupID;

i=i+1;
param(i).name='AODV_RTABLE_SIZE';                    
param(i).default=10;                
param(i).group=groupID;

i=i+1;
param(i).name='RREP_RETRIES';
param(i).default=3;                
param(i).group=groupID;
