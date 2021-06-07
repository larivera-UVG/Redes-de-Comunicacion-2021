function [param, i] = sim_set_params(param, i, gId)

%Application Simulation
i=i+1;
param(i).name='SourceRate';
param(i).default=4;
param(i).group=gId; 

i=i+1;
param(i).name='RandSourceRate';
param(i).default=0;
param(i).group=gId;

i=i+1;
param(i).name='DestinationRate';
param(i).default=0.5;
param(i).group=gId;

i=i+1;
param(i).name='RandDestinationRate';
param(i).default=0;
param(i).group=gId;

i=i+1;
param(i).name='QueryWindow';
param(i).default=1;
param(i).group=gId;

i=i+1;
param(i).name='InitTime';
param(i).default=1;
param(i).group=gId;

i=i+1;
param(i).name='LogInterval';
param(i).default=1;
param(i).group=gId;

i=i+1;
param(i).name='SourceNofPackets';
param(i).default=Inf;
param(i).group=gId; 

i=i+1;
param(i).name='CheckSourceDest';
param(i).default=1;
param(i).group=gId;
param(i).type='popupmenu';
param(i).data=[0, 1];

i=i+1;
param(i).name='PairNorminalDist';
param(i).default=0.5;
param(i).group=gId;

i=i+1;
param(i).name='PairRandDist';
param(i).default=0.1;
param(i).group=gId;

%use any trace file
i=i+1;
param(i).name='UseTraceFile';
param(i).default=0;
param(i).group=gId;
param(i).type='checkbox';

i=i+1;
param(i).name='TraceFileName';
param(i).default='none';
param(i).group=gId;