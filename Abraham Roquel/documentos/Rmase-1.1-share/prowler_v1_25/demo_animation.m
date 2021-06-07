function x=animation_data
% Animation definition for application DEMO

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


%              Anim:                                        Color:
%              0: no animation for the event
%              1: main dot representing the mote            color in RGB      
%              2: red LED                                   on/off/toggle
%              3: green LED                                 on/off/toggle
%              4: yellow LED                                on/off/toggle
%                 on/off/toggle for the LEDs: [1 0 0]  on
%                                             [0 1 0]  off
%                                             [0 0 1]  toggle

small=5; medium=20; large=50;

%                Event_name        Anim   Color/{on/off/toggle}    Size   
anim_def={...
        {'Init_Application',          1,        [0 0 0 ],         small}, ...
        {'Packet_Sent',               0,        [1 0 0 ],         small}, ...
        {'Packet_Received',           3,        [0 0 1 ],         small}, ...
        {'Collided_Packet_Received',  4,        [0 0 1 ],         small}, ...
        {'Clock_Tick',                0,        [0 0 0 ],         small}, ...
        {'Channel_Request',           0,        [0 0 0 ],         small}, ...
        {'Channel_Idle_Check',        1,        [1 0 0 ],         small}, ...
        {'Packet_Receive_Start',      1,        [0 1 0 ],         small}, ...
        {'Packet_Receive_End',        1,        [0 0 0 ],         small}, ...
        {'Packet_Transmit_Start',     1,        [1 0 0 ],         medium}, ...
        {'Packet_Transmit_End',       1,        [0 0 0 ],         small}};


for i=1:length(anim_def)
    a=anim_def{i};
    x(i)=struct('event', a{1}, 'animated', a{2}, 'color', a{3}, 'size', a{4});
end