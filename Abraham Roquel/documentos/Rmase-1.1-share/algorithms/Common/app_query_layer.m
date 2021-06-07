function status = app_query_layer(N, S)

% generate an application instance

%* Copyright (C) 2003 PARC Inc.  All Rights Reserved.
%*
%* Use, reproduction, preparation of derivative works, and distribution 
%* of this software is permitted, but only for non-commercial research 
%* or educational purposes. Any copy of this software or of any derivative 
%* work must include both the above copyright notice of PARC Incorporated 
%* and this paragraph. Any distribution of this software or derivative 
%* works must comply with all applicable United States export control laws. 
%* This software is made available AS IS, and PARC INCORPORATED DISCLAIMS 
%* ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE 
%* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
%* PURPOSE, AND NOTWITHSTANDING ANY OTHER PROVISION CONTAINED HEREIN, ANY 
%* LIABILITY FOR DAMAGES RESULTING FROM THE SOFTWARE OR ITS USE IS EXPRESSLY 
%* DISCLAIMED, WHETHER ARISING IN CONTRACT, TORT (INCLUDING NEGLIGENCE) 
%* OR STRICT LIABILITY, EVEN IF PARC INCORPORATED IS ADVISED OF THE 
%* POSSIBILITY OF SUCH DAMAGES. This notice applies to all files in this 
%* release (sources, executables, libraries, demos, and documentation).
%*/

% Written by Ying Zhang, yzhang@parc.com
% Last modified: Nov. 22, 2003  by YZ

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
S;      global ATTRIBUTES
S;      status = 1;
S;      pass = 1;
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

global DESTINATIONS

persistent destinationInterval
persistent initTime
persistent traces
persistent bittime

switch event
case 'Init_Application'   
    if (ix==1) %only need to compute it once
        rate = sim_params('get_app', 'DestinationRate');
        if (isempty(rate)) rate = 0.5; end
        bittime = sim_params('get', 'BIT_TIME');
        destinationInterval = 1/bittime/rate;  
        initTime = sim_params('get_app', 'InitTime');
        if (isempty(initTime)) initTime = 0; end
        
        useQueryFile = sim_params('get_app', 'UseQueryFile');
        if (isempty(useQueryFile)) useQueryFile = 0; end
        
        traces = [];             
        if (useQueryFile)
            fileName = sim_params('get_app', 'QueryFileName');
            if (~isempty(fileName))
                try 
                    traces = feval(fileName); %traces(:,1)-> ID, traces(:,2)-> send time (in second)
                    traces(:, 2) = traces(:, 2) - min(traces(:, 2)) + initTime; % allow initTime seconds for the application initialization 
                catch 
                    disp('wrong file name for traces') 
                end
            else 
                disp('no file name for traces')
            end
        end
        %end of query file
    end % end of compute once for all
    
    memory.receivedEvents = [];
    
    if (~isempty(traces)) %use trace file
        memory.myTrace = traces(find(traces(:, 1) == ID), :);
        memory.isDestination = ~isempty(memory.myTrace); 
        DESTINATIONS(ID) = 0;
        if memory.isDestination
            PrintMessage('d');
            DESTINATIONS(ID) = 1;
            memory.totalPackets = length(memory.myTrace);
            memory.packetPtr = 1; 
            Set_Query_Clock(memory.myTrace(memory.packetPtr, 2)/bittime); % schedule the first packet to be sent
        end
    else
        memory.index=0;   
        Set_Query_Clock(destinationInterval*rand+initTime); 
    end
    
case 'Packet_Sent'
    try msgID = data.msgID; catch msgID = 0; end
    if (msgID < 0) pass = 0; end  
case 'Send_Packet'
    try msgID = data.msgID; catch msgID = 0; end
    try forward = data.forward; catch forward = 0; end
    
    if ((msgID >= 0) && (~forward)) %events from any node
        data.x = ATTRIBUTES{ID}.x;
        data.y = ATTRIBUTES{ID}.y;
    end
    
case 'Packet_Received'
    idx = inlist(memory.receivedEvents, data.data);
    if (~isempty(idx)) pass = 0; 
    else
        memory.receivedEvents = [memory.receivedEvents, data.data];
    end
    
case 'Clock_Tick'    
    if (strcmp(data.type, 'query_send')) 
        if (~isempty(traces)) %use trace file
            if (memory.isDestination)
                SendData(memory.index); %myTrace(:, 3): sequence number
                memory.index = memory.index+1;
                memory.packetPtr = memory.packetPtr + 1;
                if memory.packetPtr <= memory.totalPackets
                    % schedule the next packet to be sent, if any
                    Set_Query_Clock(memory.myTrace(memory.packetPtr, 2)/bittime); % schedule the next packet to be sent, if any
                end
            end
        else
            if (DESTINATIONS(ID))           
                Set_Query_Clock(t+destinationInterval);            
                SendQuery(memory.index);
                memory.index = memory.index+1;
            end
        end
        
    end
    
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
S;        try app_data{ix}=memory; catch app_data{ix} = []; end
S;        if (pass) status = common_layer(N, make_event(t, event, ID, data)); end
S; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                           %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%        COMMANDS           %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%                           %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function PrintMessage(msg)
global ID
prowler('TextMessage', ID, msg)

function LED(msg)
global ID
prowler('LED', ID, msg)

%set send rate

function b=Set_Query_Clock(alarm_time);
global ID
clock.type = 'query_send';
prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));


%send query out

function status = SendQuery(varargin);
global ID t Send_Packet_Count
sdata.forward = 0;
sdata.value = varargin{1};
sdata.source = ID;
sdata.msgID = -inf;
if (length(varargin)>1)
    sdata.seqID = varargin{2};
else 
    sdata.seqID = varargin{1};
end

sdata.startTime = t;
PrintMessage(num2str(sdata.value));

window = sim_params('get_app', 'QueryWindow');
if (isempty(window)) window = 1; end
bittime = sim_params('get', 'BIT_TIME');
window = window/bittime;
sdata.window = window;
N = find_layer('app_query');
status = app_query_layer(N, make_event(t, 'Send_Packet', ID, sdata)); 

function idx = inlist(l, e)
idx = [];
for i = 1:length(l)
    if ((l(i).x==e.x) && (l(i).y==e.y) && (l(i).startTime==e.startTime))
        idx = i;
        return;
    end
end
    

