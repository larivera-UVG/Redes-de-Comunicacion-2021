function [param, i] = dest_set_params(param, i, gId)

%Application Destination
i=i+1;
param(i).name='DestinationType';
param(i).default='static';
param(i).group=gId;
param(i).type='popupmenu';
param(i).data=char('static', 'dynamic', 'mobile');

i=i+1;
param(i).name='DestinationCenterType';
param(i).default='random';
param(i).group=gId;
param(i).type='popupmenu';
param(i).data=char('random', 'fixed');

i=i+1;
param(i).name='DestinationCenterX';
param(i).default=0;
param(i).group=gId;  

i=i+1;
param(i).name='DestinationCenterY';
param(i).default=0;
param(i).group=gId;  

i=i+1;
param(i).name='DestinationRadius';
param(i).default=1;
param(i).group=gId;  

i=i+1;
param(i).name='DestinationPercentage';
param(i).default=1;
param(i).group=gId;  

i=i+1;
param(i).name='DestinationUnique';
param(i).default=1;
param(i).group=gId;
param(i).type='checkbox';

i=i+1;
param(i).name='DestinationSpeedX';
param(i).default=-0.2;
param(i).group=gId;   

i=i+1;
param(i).name='DestinationSpeedY';
param(i).default=-0.2;
param(i).group=gId;

i=i+1;
param(i).name='RandDestinationSpeed';       
param(i).default=0.1;              
param(i).group=gId;
