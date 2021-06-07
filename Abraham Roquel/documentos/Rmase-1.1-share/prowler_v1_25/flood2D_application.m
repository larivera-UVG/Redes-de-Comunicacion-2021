function application(S)
% FLOOD2_APPLICATION  Flood application with probabilistic retransmission

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

SENDER_ID=sim_params('get_app', 'Start_Mote'); 
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
    PrintMessage('i') 
case 'Packet_Sent'
    memory.send=0;
    PrintMessage('s') 

case 'Packet_Received'
    % data.data            % message
    % data.signal_strength % received signal strength
    if memory.send
        p=sim_params('get_app', 'P');
        if isempty(p); p=.3; end
        % p=0.3;  % p is forced to 0.3 / Comment this line if you want to use it for optimization
        if rand<p
            Send_Packet(radiostream(data.data, memory.signal_strength));
        end
        memory.send=0;
        PrintMessage('r') 
    end

case 'Collided_Packet_Received'
    % this is for debug purposes only
    
case 'Clock_Tick'
    Send_Packet(radiostream('this is the message', memory.signal_strength));
   
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