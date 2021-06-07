function [out_topology, out_mote_IDs]=topology_test(varargin);
% Topology information for application DEMO

% ***	
% ***	 Copyright 2002, Vanderbilt University. All rights reserved.
% ***
% ***    This program is distributed in the hope that it will be useful,
% ***    but WITHOUT ANY WARRANTY; without even the implied warranty of
% ***    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% ***
% ***

% Written by Gyula Simon, gyula.simon@vanderbilt.edu
% Last modified: May 07, 2002  by GYS

persistent topology  mote_IDs

if nargin<1, cmd='request';
else
    cmd=varargin{1};
end
NUM=20;
if isempty(topology) 
    im_coords=((-1)^(2/NUM)).^[0:NUM-1];
    t=3*[real(im_coords)', imag(im_coords)'; 0.5 0; 0 0.5; -0.5 0; 0 -0.5];
    
    tag=[-10, 2.5]/5;
    topology=[tag;t];
    mote_IDs=[1:NUM+5];  
end
if strcmpi(cmd, 'refresh')
    position=varargin{2};
    topology(1,:)=position;
end

out_topology=topology;
out_mote_IDs=mote_IDs;