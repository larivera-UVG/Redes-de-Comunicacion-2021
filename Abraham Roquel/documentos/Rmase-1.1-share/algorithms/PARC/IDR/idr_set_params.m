function [param, i] = idr_set_params(param, i, gId)

i = i+1;
param(i).name='IDRType';
param(i).default='learning';
param(i).group=gId;
param(i).type='popupmenu';
param(i).data=char('greedy', 'learning', 'probabilistic');

i = i+1;
param(i).name='MinInfoGain';
param(i).default=0;
param(i).group=gId;

i = i+1;
param(i).name='IDRMaxHops';
param(i).default=Inf;
param(i).group=gId;

i = i+1;
param(i).name='HopDelta';
param(i).default=1;
param(i).group=gId;

i = i+1;
param(i).name='KnownLocation';
param(i).default=0;
param(i).group=gId;
param(i).type='checkbox';

i = i+1;
param(i).name='HopDistance';
param(i).default=2;
param(i).group=gId;

i = i+1;
param(i).name='MinTargetValue';
param(i).default=1;
param(i).group=gId;

i = i+1;
param(i).name='MinUtilValue';
param(i).default=0.5;
param(i).group=gId;