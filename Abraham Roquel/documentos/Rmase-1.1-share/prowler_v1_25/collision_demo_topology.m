function [out_topology, out_mote_IDs]=topology_test(varargin);
% Topology information for application COLLISION_DEMO

% ***	
% ***	 Copyright 2002, Vanderbilt University. All rights reserved.
% ***
% ***    This program is distributed in the hope that it will be useful,
% ***    but WITHOUT ANY WARRANTY; without even the implied warranty of
% ***    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% ***
% ***

% Written by Gyula Simon, gyula.simon@vanderbilt.edu
% Last modified: Aug 13, 2002  by GYS

persistent topology  

if nargin<1, cmd='request';
else
    cmd=varargin{1};
end

mote_IDs=1:3;
if isempty(topology) 
    topology=[1 0; 6 0; 3 0];
end

if strcmpi(cmd, 'refresh')
    position=varargin{2};
    topology(3,:)=position;
end

out_topology=topology;
out_mote_IDs=mote_IDs;