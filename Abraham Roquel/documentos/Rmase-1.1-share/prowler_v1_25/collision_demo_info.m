function varargout=info
% FLOOD application information file

% ***	
% ***	 Copyright 2002, Vanderbilt University. All rights reserved.
% ***
% ***    This program is distributed in the hope that it will be useful,
% ***    but WITHOUT ANY WARRANTY; without even the implied warranty of
% ***    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% ***
% ***

% Written by Gyula Simon, gyula.simon@vanderbilt.edu
% Last modified: Sep 19, 2002  by GYS

title1='Application COLLISION_DEMO';
str1={  'Two senders transmit messages periodically. A receiver between';...
        'them receives the messages and displays the received message ';...
        'indices and shows the source.';...
        '';...
        'The receiver can be moved - use the mouse.';...
        '';...
        'Color coding: ';...
        '   green  - successful reception';...
        '   yellow - collided message';...
        '';...
        'Although both of the receivers initiate transmissions at the';...
        'very same time instants, due to the operation of the MAC-layer';...
        'the real transmissions are delayed (see the MAC-layer parameters' ;...
        'in Simulation Parameters)';...
        '';...
        'If the transmitters can hear each other, no collisions occur.';...
        'Otherwise the receiver between them receives collided messages.';...
        '';...
        'Tips: ';...
        'Set the random part of the MAC-layer waiting time to zero.';...
        '   In this case the transmissions happen at the same time, the ';...
        '   messages will always be collided in the middle region. ';...
        'Set the random part of the MAC-layer waiting time to 3000.';...
        '   In this case there is a good chance that the transmissions ';...
        '   do not overlap. There are a lot of successfull receptions ';...
        '   in the middle region. ';...
        ''};
if nargout==0
    helpwin({ title1, str1}, 'Application Info')
else
    varargout={ title1, str1};
end