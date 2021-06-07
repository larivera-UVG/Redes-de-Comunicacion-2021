function [param, i] = topology_set_params(param, i, gId)

%size

i=i+1;
param(i).name='Xsize';
param(i).default=7;
param(i).group=gId;    

i=i+1;
param(i).name='Ysize';
param(i).default=7;
param(i).group=gId;    

%distance
i=i+1;
param(i).name='Xdist';
param(i).default=1;
param(i).group=gId;    

i=i+1;
param(i).name='Ydist';
param(i).default=1;
param(i).group=gId;    

%offset
i=i+1;
param(i).name='Xoffset';
param(i).default=0;
param(i).group=gId;    

i=i+1;
param(i).name='Yoffset';
param(i).default=0;
param(i).group=gId;    

%density
i=i+1;
param(i).name='Xdensity';
param(i).default=1;
param(i).group=gId;    

i=i+1;
param(i).name='Ydensity';
param(i).default=1;
param(i).group=gId;   

%shift
i=i+1;
param(i).name='Xshift';
param(i).default=0;
param(i).group=gId;    

i=i+1;
param(i).name='Yshift';
param(i).default=0;
param(i).group=gId;    

i=i+1;
param(i).name='wraparound';
param(i).default=0;
param(i).group=gId;
param(i).type='checkbox';

%AliveProb
i=i+1;
param(i).name='AliveProb';
param(i).default=1;
param(i).group=gId;    

%use any topology file
i=i+1;
param(i).name='UseTopologyFile';
param(i).default=0;
param(i).group=gId;
param(i).type='checkbox';

i=i+1;
param(i).name='TopologyFileName';
param(i).default='none';
param(i).group=gId;