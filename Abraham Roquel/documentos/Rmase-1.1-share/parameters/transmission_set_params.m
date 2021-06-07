function [param, i] = transmission_set_params(param, i, gId)

%strength
i=i+1;
param(i).name='Strength';
param(i).default=1;
param(i).group=gId;

%InitPower
i=i+1;
param(i).name='InitPower';
param(i).default=1000;
param(i).group=gId;

%RandPower
i=i+1;
param(i).name='RandPower';
param(i).default=0;
param(i).group=gId;

%FailProb
i=i+1;
param(i).name='FailProb';
param(i).default=0;
param(i).group=gId;
   

%WakeupProb
i=i+1;
param(i).name='WakeupProb';
param(i).default=0;
param(i).group=gId; 

%Duty Cycle
i=i+1;
param(i).name='CycleTime';
param(i).default=10;
param(i).group=gId; 

i=i+1;
param(i).name='ActivePeriod';
param(i).default=0.1;
param(i).group=gId; 

i=i+1;
param(i).name='InitActiveCycles';
param(i).default=0;
param(i).group=gId;