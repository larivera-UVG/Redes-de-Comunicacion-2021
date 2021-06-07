function application(S)
% DEMO application to illustrate the capabilities of prowler

% ***	
% ***	 Copyright 2002, Vanderbilt University. All rights reserved.
% ***
% ***    This program is distributed in the hope that it will be useful,
% ***    but WITHOUT ANY WARRANTY; without even the implied warranty of
% ***    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% ***
% ***

% Written by Gyula Simon, gyula.simon@vanderbilt.edu
% Last modified: Jun 17, 2003  by GYS


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

switch event
case 'Init_Application'
    signal_strength=1;
        
    %%%%%%%%%%%%%%   Memory should be initialized here  %%%%%%%%%%%%%%%%%
    memory=struct('Last_ID_Received',0, 'signal_strength', signal_strength);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ID==1 % first node starts sending messages
        Set_Clock(1000)
    end
case 'Packet_Sent'
    if ID>1, PrintMessage(['s ' num2str(memory.Last_ID_Received)]), end

case 'Packet_Received'
    msg=data.data;
    if memory.Last_ID_Received<msg.ID
        if rand<1
            Send_Packet(radiostream(msg, memory.signal_strength));
        end
        memory.Last_ID_Received=msg.ID;
        if ID>1, PrintMessage(['r ' num2str(memory.Last_ID_Received)]), end
    end
case 'Collided_Packet_Received'
    % this is for debug purposes only
    
case 'Clock_Tick'
    % only mote #1 uses the clock !
    memory.Last_ID_Received=memory.Last_ID_Received+1;
    msg.ID=memory.Last_ID_Received;
    Send_Packet(radiostream(msg, memory.signal_strength));
    Set_Clock(t+40000)

    %  place for commercials
    Rand_Msg=rem(memory.Last_ID_Received,14);
    switch Rand_Msg
    case 2
        PrintMessage('This mote is transmitting a message in every second') 
    case 3
        PrintMessage('The other motes retransmit the message (flood)') 
    case 4
        PrintMessage('The received/sent message IDs are shown on the motes') 
    case 5
        PrintMessage('Small red dots indicate motes with pending transmission') 
    case 6
        PrintMessage('Bigger red dots indicate transmitting motes') 
    case 7
        PrintMessage('Small green dots indicate receiving motes') 
    case 8
        PrintMessage('Green LED is toggled when a message is received succesfully') 
    case 9
        PrintMessage('Yellow LED is toggled when a collided message is received') 
    case 10
        PrintMessage('Click on the white area to move me') 
    case 11
        PrintMessage('You can click on the mote''s dot to see memory dump') 
    case 12
        PrintMessage('Try also demo\_opt from the command window') 
    otherwise
        PrintMessage('DEMO application') 
    end           
    
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

function LED(msg)
global ID
prowler('LED', ID, msg)
