function e=make_event(t, event_name, ID, data, sID);
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



if nargin<4, data=[]; end
if nargin<5, sID=[];  end
e=struct('time', t, 'event', event_name, 'ID', ID, 'sID', sID);
e.data=data;

