function param=params;
% Application parameter definition file

% ***	
% ***	 Copyright 2002, Vanderbilt University. All rights reserved.
% ***
% ***    This program is distributed in the hope that it will be useful,
% ***    but WITHOUT ANY WARRANTY; without even the implied warranty of
% ***    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% ***
% ***

% Written by Gyula Simon, gyula.simon@vanderbilt.edu
% Last modified: Jan 19, 2003  by GYS

%##########################################################################
%## Using Parameters
%## By now there are three different types of User Interface Controls (uicontrols)   
%## implemented: edit | popupmenu | checkbox
%##
%## all parameter using:
%## param(i).name       def. the name which describes the parameter
%##         .group      def. the group index
%##         .groupname  def. the group name
%##         .type       def. the type (text | pop up menu | checkbox)
%##                          default value is text
%##
%## edit:
%##         .default    def. the default value
%## popupmenu:
%##         .default    def. the default value
%##         .data       def. the list of values: {'value1','value2','value3',...}
%## checkbox:
%##         .default    def. if the checkbox is selected (=1) or not (=0)
%##         
%##########################################################################


i=0;

GroupNames={'Layout Parameters', 'Routing Parameters'};


i=i+1;
param(i).name='Layout';                  
param(i).type='popupmenu';
param(i).data=char('Uniform', 'Belt', 'Curve', 'Wicked');
param(i).default='Uniform';
param(i).group=1;


i=i+1;
param(i).name='NumberOfMotes';    
param(i).type='edit';
param(i).default=100;
param(i).group=1;


i=i+1;
param(i).name='StartMote';     
param(i).type='edit';
param(i).default=1;
param(i).group=1;

i=i+1;
param(i).name='StopMote';
param(i).type='edit';
param(i).default=2;
param(i).group=1;

i=i+1;
param(i).name='Max_X_Distance';       
param(i).type='edit';
param(i).default=10;
param(i).group=1;

i=i+1;
param(i).name='Max_Y_Distance';         
param(i).type='edit';
param(i).default=10;
param(i).group=1;

i=i+1;
param(i).name='alpha';            
param(i).type='edit';
param(i).default=pi/4;
param(i).group=2;

i=i+1;
param(i).name='P';    
param(i).type='edit';
param(i).default=0.5;
param(i).group=2;

% assign groupnames
for j=1:i
    param(j).groupname=GroupNames{param(j).group};
end
