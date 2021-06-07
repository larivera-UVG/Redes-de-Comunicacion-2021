function application(S)
% COLLISION DEMO application to illustrate the collision effect in radio transmission

% ***	
% ***	 Copyright 2002, Vanderbilt University. All rights reserved.
% ***
% ***    This program is distributed in the hope that it will be useful,
% ***    but WITHOUT ANY WARRANTY; without even the implied warranty of
% ***    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% ***
% ***

% Written by Gyula Simon, gyula.simon@vanderbilt.edu
% Last modified: Sep 17, 2002  by GYS


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
    memory=struct('signal_strength', signal_strength, 'cnt', 0, 'received_ix', 0);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    Set_Clock(10000)
    if ID==1 | ID==2 % 
      PrintMessage(['Transmitter' num2str(ID)])
    else
        PrintMessage('Receiver')
    end
case 'Packet_Sent'
    
case 'Packet_Received'
    if ID==3 % receiver
        data=data.data;
        sender=data.ID;
        msg_ix=data.cnt;
        memory.received_ix=msg_ix;
        LED('yellow off')
        LED('green on')
        if sender==1
            PrintMessage(['<' num2str(msg_ix) '<']) 
        else
            PrintMessage(['>' num2str(msg_ix) '>']) 
        end
    end
case 'Collided_Packet_Received'
    % this is for debug purposes only
    if ID==3 % receiver
        data=data.data;
        sender=data.ID;
        msg_ix=data.cnt;
        memory.received_ix=msg_ix;
        LED('yellow on')
        LED('green off')
        PrintMessage(['x' num2str(msg_ix) 'x']) 
    end
case 'Clock_Tick'
    cnt=memory.cnt+1;
    memory.cnt=cnt;
    if ID==1 | ID==2 % transmitters
        Send_Packet(radiostream(struct('ID', ID, 'cnt', cnt), memory.signal_strength));
        PrintMessage([ num2str(cnt)]) 
    else % receiver
        if memory.received_ix < cnt-1 % missed messages
            PrintMessage(['---']) 
            LED('yellow off')
            LED('green off')
        end
    end
    Set_Clock((cnt+1)*10000)
case 'GuiInfoRequest'
   disp(sprintf('Memory Dump of mote ID# %d:\n',ID)); disp(memory)
    
    
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
