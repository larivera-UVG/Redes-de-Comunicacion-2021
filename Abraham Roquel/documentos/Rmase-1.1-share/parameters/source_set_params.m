function [param, i] = source_set_params(param, i, gId)

%Application Source
i=i+1;
param(i).name='SourceType';
param(i).default='static';
param(i).group=gId;
param(i).type='popupmenu';
param(i).data=char('static', 'dynamic', 'mobile');

i=i+1;
param(i).name='SourceCenterType';
param(i).default='random';
param(i).group=gId;
param(i).type='popupmenu';
param(i).data=char('random', 'fixed');

i=i+1;
param(i).name='SourceCenterX';
param(i).default=0;
param(i).group=gId;    

i=i+1;
param(i).name='SourceCenterY';
param(i).default=0;
param(i).group=gId;   

i=i+1;
param(i).name='SourceRadius';
param(i).default=1;
param(i).group=gId;   

i=i+1;
param(i).name='SourcePercentage';
param(i).default=1;
param(i).group=gId;    

i=i+1;
param(i).name='SourceUnique';
param(i).default=1;
param(i).group=gId;
param(i).type='checkbox';

i=i+1;
param(i).name='SourceSpeedX';
param(i).default=-0.2;
param(i).group=gId;   

i=i+1;
param(i).name='SourceSpeedY';
param(i).default=-0.2;
param(i).group=gId;

i=i+1;
param(i).name='RandSourceSpeed';       
param(i).default=0.1;              
param(i).group=gId;