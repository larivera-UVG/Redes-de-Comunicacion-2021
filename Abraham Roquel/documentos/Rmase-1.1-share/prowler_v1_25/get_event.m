function [t, event, ID, data, sID]=get_event(e);
% helper file for prowler

% ***	
% ***	 Copyright 2002, Vanderbilt University. All rights reserved.
% ***
% ***    This program is distributed in the hope that it will be useful,
% ***    but WITHOUT ANY WARRANTY; without even the implied warranty of
% ***    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% ***
% ***

% Written by Gyula Simon, gyula.simon@vanderbilt.edu
% Last modified: Aug 12, 2002  by GYS


t=e.time;
event=e.event;
ID=e.ID;
data=e.data;
sID=e.sID;

