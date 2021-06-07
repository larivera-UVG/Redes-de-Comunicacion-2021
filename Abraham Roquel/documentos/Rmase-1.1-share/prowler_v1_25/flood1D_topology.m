function [topology,mote_IDs]=topology(varargin);
% Topology information for application FLOOD1D

% ***	
% ***	 Copyright 2002, Vanderbilt University. All rights reserved.
% ***
% ***    This program is distributed in the hope that it will be useful,
% ***    but WITHOUT ANY WARRANTY; without even the implied warranty of
% ***    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% ***
% ***

% Written by Gyula Simon, gyula.simon@vanderbilt.edu
% Last modified: May 06, 2002  by GYS


Nx=10; Ny=1; % number of points on the grid

ix=1;t=[];
distx=1;
disty=5;
X=1:distx:(Nx-1)*distx+1;
Y=1:disty:(Ny-1)*disty+1;
for i=X
    for j=Y
        t=[t; i,j];
    end
end
topology=t;
mote_IDs=1:Nx*Ny;  
