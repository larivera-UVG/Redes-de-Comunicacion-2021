function [param, i] = hole_set_params(param, i, gId)

%Hole
i=i+1;
param(i).name='HPosX';
param(i).default=0;
param(i).group=gId;    

i=i+1;
param(i).name='HPosY';
param(i).default=0;
param(i).group=gId;   

i=i+1;
param(i).name='HLengthX';
param(i).default=0;
param(i).group=gId;   

i=i+1;
param(i).name='HHeigthY';
param(i).default=0;
param(i).group=gId;   

i=i+1;
param(i).name='HAngle';
param(i).default=0;
param(i).group=gId;    

%border
i=i+1;
param(i).name='HBorder';
param(i).default=0;
param(i).group=gId;   

%RandHoles
i=i+1;
param(i).name='RHNumber';
param(i).default=0;
param(i).group=gId;  

i=i+1;
param(i).name='RHLengthX';
param(i).default=0;
param(i).group=gId;  

i=i+1;
param(i).name='RHLengthXRand';
param(i).default=0;
param(i).group=gId;   

i=i+1;
param(i).name='RHHeigthY';
param(i).default=0;
param(i).group=gId;  

i=i+1;
param(i).name='RHHeigthYRand';
param(i).default=0;
param(i).group=gId;   