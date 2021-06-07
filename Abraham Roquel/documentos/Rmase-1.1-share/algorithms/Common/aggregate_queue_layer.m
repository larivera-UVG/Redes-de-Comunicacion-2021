function status = aggregate_queue_layer(N, S)

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

persistent aggregate_packets
persistent aggregate_timeout
persistent sending

switch event
case 'Init_Application'
    if (ix==1)
        aggregate_packets = sim_params('get_app', 'AggregatePackets');
        if (isempty(aggregate_packets)) aggregate_packets = 4; end %4 packets
        aggregate_timeout = sim_params('get_app', 'AggregateTimeout');
        if (isempty(aggregate_timeout)) aggregate_timeout = 10000; end %0.25 sec
    end
    memory.queue = {};
    sending = 0;
    Set_Timeout_Clock(aggregate_timeout*rand);
case 'Send_Packet'
    try msgID = data.msgID; catch msgID = 0; end
    if (msgID>=0)
        memory = Insert2Q(memory, data);
        if ((length(memory.queue) >= aggregate_packets) && ~sending)
            memory = SendFromQ(N, memory, aggregate_packets);
            sending = 1;
        else pass = 0; 
        end
    end
case 'Packet_Sent'
    try msgID = data.data.msgID; catch msgID = 0; end
    if (msgID == Inf)
        sending = 0;
        if (length(memory.queue) >= aggregate_packets) 
            memory = SendFromQ(N, memory, aggregate_packets); 
        end
        packets = data.data.packets;
        for i=1:length(packets)
            packet = packets{i};
            rdata.data = packet;
            rdata.signal_strength = data.signal_strength;
            common_layer(N, make_event(t, event, ID, rdata));
        end
        pass = 0;
    end
case 'Packet_Received'
    try msgID = data.data.msgID; catch msgID = 0; end
    if (msgID == Inf)
        packets = data.data.packets;
        for i=1:length(packets)
            packet = packets{i};
            rdata.data = packet;
            rdata.signal_strength = data.signal_strength;
            common_layer(N, make_event(t, event, ID, rdata));
        end
        pass = 0;
    end
case 'Clock_Tick'
    try type = data.type; catch type = 'none'; end
    if (strcmpi(type, 'aggregate_timeout')) % a send signal
        if ((length(memory.queue)>0) && (~sending))
            memory = SendFromQ(N, memory, min(length(memory.queue), aggregate_packets));
        end
        Set_Timeout_Clock(t+aggregate_timeout);
        pass = 0;
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

function out = Insert2Q(memory, data)
Q=memory.queue;
Q{length(Q)+1} = data;
memory.queue = Q;
out = memory;

function out = SendFromQ(N, memory, nOfPackets)
global ID t
Q=memory.queue;
data.packets = Q(1:nOfPackets);
data.msgID = Inf;
common_layer(N, make_event(t, 'Send_Packet', ID, data));
Q = Q(nOfPackets+1:length(Q));
memory.queue = Q;
out = memory;

function b=Set_Timeout_Clock(alarm_time);
global ID
clock.type = 'aggregate_timeout';
prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));


