function [topology,mote_IDs]=topology(varargin);
% Topology information for application FLOOD2D

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

ix=1;t=[];
%dist=1;
% Nx=10; Ny=10; % number of points on the grid
Nx  =sim_params('get_app', 'X_Number'); if isempty(Nx),   Nx=10;  end
Ny  =sim_params('get_app', 'Y_Number'); if isempty(Ny),   Ny=10;  end
dist=sim_params('get_app', 'Distance'); if isempty(dist), dist=1; end

X=1:dist:(Nx-1)*dist+1;
Y=1:dist:(Ny-1)*dist+1;
for i=X
    for j=Y
        t=[t; i,j];
    end
end
topology=t;
mote_IDs=1:Nx*Ny;  
