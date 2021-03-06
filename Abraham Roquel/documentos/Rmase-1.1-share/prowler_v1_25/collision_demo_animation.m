function x=animation_data
% Animation definition for application COLLISION_DEMO

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


small=5; medium=20; large=50;

%                Event_name    Animated   Color/{on/off/toggle}    Size   
anim_def={...
        {'Init_Application',          0,        [0 0 0 ],         small}, ...
        {'Packet_Sent',               1,        [0 1 0 ],         small}, ...
        {'Packet_Received',           1,        [0 1 0 ],         small}, ...
        {'Collided_Packet_Received',  1,        [1 .6 0 ],        small}, ...
        {'Clock_Tick',                0,        [0 0 0 ],         small}, ...
        {'Channel_Request',           0,        [0 0 0 ],         small}, ...
        {'Channel_Idle_Check',        1,        [1 0 0 ],         small}, ...
        {'Packet_Receive_Start',      0,        [0 1 0 ],         small}, ...
        {'Packet_Receive_End',        0,        [0 0 0 ],         small}, ...
        {'Packet_Transmit_Start',     1,        [1 0 0 ],         medium}, ...
        {'Packet_Transmit_End',       0,        [0 1 0 ],         small}};


for i=1:length(anim_def)
    a=anim_def{i};
    x(i)=struct('event', a{1}, 'animated', a{2}, 'color', a{3}, 'size', a{4});
end