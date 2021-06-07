function [topology,mote_IDs]=topology(varargin);
% Topology information for application SPANTREE

% ***	
% ***	 Copyright 2002, Vanderbilt University. All rights reserved.
% ***
% ***    This program is distributed in the hope that it will be useful,
% ***    but WITHOUT ANY WARRANTY; without even the implied warranty of
% ***    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% ***
% ***

% Written by Gyula Simon, gyula.simon@vanderbilt.edu
% Last modified: Aug 01, 2002  by GYS


persistent local_topology local_mote_IDs

if nargin>0
    command=varargin{1};
else
    command='request';
end


switch lower(command)
case 'init'
    NumberOfMotes =  sim_params('get_app', 'NumberOfMotes');
    Distr =          sim_params('get_app', 'Layout'); 
    Max_X_Distance = sim_params('get_app', 'Max_X_Distance');
    Max_Y_Distance = sim_params('get_app', 'Max_Y_Distance');
    Start =          sim_params('get_app', 'StartMote');
    Stop =           sim_params('get_app', 'StopMote');
 
    local_mote_IDs=1:NumberOfMotes;

    xx=Max_X_Distance*rand(NumberOfMotes,1);
    yy=Max_Y_Distance*rand(NumberOfMotes,1);
    switch Distr
    case 'Uniform'
        local_topology=[xx, yy];
        local_topology(Start,:)=[Max_X_Distance,Max_Y_Distance]/6; 
        local_topology(Stop ,:)=[Max_X_Distance,Max_Y_Distance]*5/6;  
       
    case 'Belt'
        angle=xx/Max_X_Distance*2*pi;
        R=.33*yy+0.66*Max_X_Distance;
        z=R.*(exp(j*angle));
        local_topology=[real(z), imag(z)];
        local_topology(Start,:)=[-Max_X_Distance,0]; 
        local_topology(Stop ,:)=[ Max_X_Distance,0]; 
       
    case 'Curve'
        angle=xx/Max_X_Distance*pi;
        R=.33*yy+0.66*Max_X_Distance;
        z=R.*(exp(j*angle));
        local_topology=[real(z), imag(z)];
        local_topology(Start,:)=[-Max_X_Distance,0]; 
        local_topology(Stop ,:)=[ Max_X_Distance,0]; 
    case 'Wicked'
        xx=rand(NumberOfMotes,1);
        yy=rand(NumberOfMotes,1);

        ix1=find(xx<1/4);
        ix2=find(xx>=1/4 & xx<1/2);
        ix3=find(xx>=1/2);
        local_topology=[Max_X_Distance*[yy(ix1)/4; xx(ix2)*2-1/4; 1-yy(ix3)/4], Max_Y_Distance*[1/2+xx(ix1)*2; 1-yy(ix2)/4; 2-2*xx(ix3)]];
        local_topology(Start,:)=[Max_X_Distance/8,Max_Y_Distance/2]; 
        local_topology(Stop,:)=[Max_X_Distance*7/8,0]; 
        
    end
case 'refresh'
    % do nothing, return old topology
case 'request'
    % do nothing, return old topology
end

topology=local_topology;
mote_IDs=local_mote_IDs;