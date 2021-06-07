function application(S)
% Routing experimental skeleton

% ***	
% ***	 Copyright 2002, Vanderbilt University. All rights reserved.
% ***
% ***    This program is distributed in the hope that it will be useful,
% ***    but WITHOUT ANY WARRANTY; without even the implied warranty of
% ***    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% ***
% ***

% Written by Gyula Simon, gyula.simon@vanderbilt.edu
% Last modified: Sept 17, 2003  by GYS


% DO NOT edit simulator code (lines that begin with S;)


S; %%%%%%%%%%%%%%%%%%%   housekeeping  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
S;      persistent app_data 
S;      global ID t
S;      [t, event, ID, data]=get_event(S);
S;      [topology, mote_IDs]=prowler('GetTopologyInfo');
S;      ix=find(mote_IDs==ID);
S;      if ~strcmp(event, 'Init_Application') 
S;         try memory=app_data{ix}; catch memory=[]; end, 
S;      end
S; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                          %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%         APPLICATION STARTS               %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%               HERE                       %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                          %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%

SENDER_ID=sim_params('get_app', 'StartMote'); 
if isempty(SENDER_ID), SENDER_ID=1; end

switch event
case 'Init_Application'
    signal_strength=1;
        
    %%%%%%%%%%%%%%   Memory should be initialized here  %%%%%%%%%%%%%%%%%
    memory=struct('send',1, 'signal_strength', signal_strength);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if ID==SENDER_ID % this node starts flood
        Set_Clock(1000)
    end
    if ID==sim_params('get_app', 'StopMote')
        PrintMessage('D') 
    end
    % PrintMessage('i') 
case 'Packet_Sent'
    memory.send=0;
    PrintMessage('s') 

case 'Packet_Received'
    % data.data            % message
    % data.signal_strength % received signal strength
    msg=data.data;
    last_pos=msg.last_transmitter_pos;
    dest_pos=msg.destination_position;
    my_pos=GetPosition(ID);
    
    msg_angle=atan2(dest_pos(2)-last_pos(2), dest_pos(1)-last_pos(1));
    my_angle= atan2(  my_pos(2)-last_pos(2),   my_pos(1)-last_pos(1));
    
    alpha=sim_params('get_app', 'alpha');
    delta_angle=mod(msg_angle-my_angle, 2*pi);
    if delta_angle<alpha | delta_angle>2*pi-alpha  % can retransmit
        msg_new=msg; 
        msg_new.last_transmitter_pos=GetPosition(ID);
        msg_new.last_transmitter_ID=ID;
        DrawLine('Line', msg.last_transmitter_ID, ID, 'color', [1 1 1]*0.6)
        if memory.send
            p=sim_params('get_app', 'P');
            if isempty(p); p=.3; end
            if rand<p
                Send_Packet(radiostream(msg_new, memory.signal_strength));
            end
            memory.send=0;
            PrintMessage('r') 
        end
        
    end

case 'Collided_Packet_Received'
    % this is for debug purposes only
    
case 'Clock_Tick'
    dest_ID=sim_params('get_app', 'StopMote');
    dest_pos=GetPosition(dest_ID);
    my_pos=GetPosition(ID);
    msg=struct(...
        'sender_ID', ID, ...
        'destination_position', dest_pos, ...
        'last_transmitter_pos', my_pos, ...
        'last_transmitter_ID', ID, ...
        'msg', 'this is the message');
    Send_Packet(radiostream(msg, memory.signal_strength));
   
case 'GuiInfoRequest'
    if ~isempty(memory)
        disp(sprintf('Memory Dump of mote ID# %d:\n',ID)); disp(memory)
    else
        disp(sprintf('No memory dump available for node %d.\n',ID)); 
    end
    
case 'Application_Stopped'
   % this event is called when simulation is stopped/suspended 
   
case 'Application_Finished'
   % this event is called when simulation is finished 
    
otherwise
    error(['Bad event name for application: ' event])
end

%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                          %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%         APPLICATION ENDS                 %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%               HERE                       %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                                          %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
S; %%%%%%%%%%%%%%%%%%%%%% housekeeping %%%%%%%%%%%%%%%%%%%%%%%%%%%
S;        app_data{ix}=memory;
S; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                           %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%        COMMANDS           %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                           %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function b=Send_Packet(data);
global ID t
radio=prowler('GetRadioName');
b=feval(radio, 'Send_Packet', ID, data, t);

function b=Set_Clock(alarm_time);
global ID
prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID));

function PrintMessage(msg)
global ID
prowler('TextMessage', ID, msg)


function DrawLine(command, varargin)
switch lower(command)
case 'line'
    prowler('DrawLine', varargin{:})
case 'arrow'
    prowler('DrawArrow', varargin{:})
case 'delete'
    prowler('DrawDelete', varargin{:})
otherwise
    error('Bad command for DrawLine.')
end


function [pos]=GetPosition(ID)
% return the x-y coordinates of a node
[topology,ids]=route_angle_topology;
ix=find(ID==ids);
pos=topology(ix,:); 
