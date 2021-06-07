function status = ack_retransmit_layer(N, S)

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

% Written by Guoliang Xing, xing@wustl.edu
% Last modified: By YZ, Jan. 4, 2005
% this layer will ack a packet using proper power level and retransmit a
% packet if ack is not received

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

persistent fixTimeout randTimeout retries ack_strength
persistent bittime ACK_LENGTH

global ACK_MSGID

switch event
case 'Init_Application'
    memory.transmitting = [];
    if (ix==1)
        bittime = sim_params('get','BIT_TIME');        
        
        retries = sim_params('get_app', 'Retries');
        if(isempty(retries)) retries = 8; end  
        
        fixTimeout = sim_params('get_app', 'AckTimeout');
        if (isempty(fixTimeout)) fixTimeout = 0.15; end
        randTimeout = sim_params('get_app', 'RandAckTimeout');
        if (isempty(randTimeout)) randTimeout = 0.1; end
        
        ACK_LENGTH = sim_params('get_app', 'AckSize');
        if (isempty(ACK_LENGTH)) ACK_LENGTH = 96; end
        
        ACK_MSGID = -100;
        
        pxLevels = sim_params('get_radio', 'POWER_RNG'); %transmission power level in db 
        if (isempty(pxLevels)) 
            ack_strength = sim_params('get_app', 'Strength');
            if (isempty(ack_strength)) ack_strength = 1; end
        else
            ack_strength = length(pxLevels); %max for acknowledge
        end
    end
case 'Send_Packet'  
    try address = data.address; catch address = 0; end
    try msgID = data.msgID; catch msgID = 0; end
    data.from = ID;
    if (address && (msgID>=0))
        [memory.transmitting found] = UpdateTransmitting(memory.transmitting, address, data, 0);
        if(~found) 
            data.retries = retries; 
        end
        timeout = (fixTimeout + rand*randTimeout)/bittime;
        Set_Timeout_Clock(timeout, data);       
    end
   
case 'Packet_Received'
    rdata = data.data;
    
    try address = rdata.address; catch address = 0; end
    try msgID = rdata.msgID; catch msgID = 0; end
    from = rdata.from;
    
    if ((address==ID) && (msgID>=0))
        %send ACK
        ack.source=rdata.source;
        ack.from = ID;
        ack.address = from;
        ack.subMsgID = msgID;
        ack.msgID=ACK_MSGID;
        ack.seqID = rdata.seqID;
        ack.length = ACK_LENGTH;
        ack.strength = ack_strength;
        status = ack_retransmit_layer(N, make_event(t, 'Send_Packet', ID, ack));
    elseif (msgID == ACK_MSGID)
        memory.transmitting = UpdateTransmitting(memory.transmitting, from, rdata, 1);
    end
case 'Clock_Tick'
    try type = data.type; catch type = 'none'; end
    if (strcmp(type, 'ack_timeout')) 
        pass = 0;
        rdata = data.data;
        try address = rdata.address; catch address = 0; end
        rdata.retries = rdata.retries - 1;
        if (address && rdata.retries>=0)
            [memory.transmitting, found] = UpdateTransmitting(memory.transmitting, address, rdata, 0);
            if(found) 
                %retrying
                status = ack_retransmit_layer(N, make_event(t, 'Send_Packet', ID, rdata));
            end
        elseif(rdata.retries<0)
            %has retried enough times, let's return it to upper layers
            memory.transmitting = UpdateTransmitting(memory.transmitting, address, rdata, 1);
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

function [new_q, found]=UpdateTransmitting(queue, address, data, remove)
global ID ACK_MSGID

if(data.msgID==ACK_MSGID) 
    msgID=data.subMsgID;
else
    msgID=data.msgID;
end

try seqID = data.seqID; catch seqID = 0; end
try source = data.source; catch source = ID; end

n = size(queue,1);
found = 0;
for i=1:n
    if (queue(i,:)==[address, source, msgID, seqID])
        found = 1;
        if(remove)
            queue = [queue(1:i-1, :); queue(i+1:n, :)];
        end
        break;
    end
end
if(~found)
    queue = [queue; [address, source, msgID, seqID]];
end
new_q = queue;

function Set_Timeout_Clock(timeout, data)
global ID t
clock.type = 'ack_timeout';
clock.data = data;
prowler('InsertEvents2Q', make_event(t+timeout, 'Clock_Tick', ID, clock));


