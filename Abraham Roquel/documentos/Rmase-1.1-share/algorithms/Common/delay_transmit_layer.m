function status = delay_transmit_layer(N, S)

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

persistent randOff
persistent minDelay
persistent pfunc

switch event
case 'Init_Application'
    if (ix==1)
        randOff = sim_params('get_app', 'RandOff');
        if (isempty(randOff)) randOff = 1000; end
        minDelay = sim_params('get_app', 'MinDelay'); 
        if (isempty(minDelay)) minDelay = 1000; end
        pfunc = sim_params('get_app', 'Probfunc');
        if (isempty(pfunc)) pfunc = '1/c'; end
    end
    memory = struct('msgID', [], 'seqID', [], 'counts', [], 'received', []);
    
case 'Send_Packet'  
    try delayTime = data.delayTime; catch delayTime = minDelay; end
    if (delayTime>0) delayTime = delayTime+randOff*rand; end %add random offset
    try forward = data.forward; catch forward = 0; end
    try address = data.address; catch address = 0; end
    
    if (~forward)
        try msgID = data.msgID; catch msgID = 0; end
        idx = find(memory.msgID==msgID);
        if (isempty(idx)) 
            seqID = 0; 
            memory.msgID = [msgID, memory.msgID]; 
            memory.seqID = [0, memory.seqID];
        else 
            seqID = memory.seqID(idx)+1;
            memory.seqID(idx) = seqID;
        end
        data.seqID = seqID;
        data.msgID = msgID;
        data.source = ID;
    end
    if ((delayTime>0) && (address == 0)) %used for broadcast only
        clock.type = 'delay_send';
        clock.data = data;
        prowler('InsertEvents2Q', make_event(t+delayTime, 'Clock_Tick', ID, clock));
        pass = 0;
    end
case 'Packet_Received'
    rdata = data.data;
    try address = rdata.address; catch address = 0; end
    if (rdata.source==ID) data.duplicated = 1; 
    else
        msgs = memory.received;
        counts = memory.counts;
        n=size(msgs);
        n = n(1);
        data.duplicated = 0;
        for i=1:n, 
            if (msgs(i,:)==[rdata.source, rdata.msgID, rdata.seqID])
            counts(i) = counts(i)+1;
            memory.counts = counts;
            data.duplicated = 1;
            end
        end
        if (~data.duplicated) 
            msgs(n+1,:) = [rdata.source, rdata.msgID, rdata.seqID];
            counts(n+1) = 1;
            memory.received = msgs;
            memory.counts = counts;
        end        
    end
case 'Clock_Tick'
    try type = data.type; catch type = 'none'; end
    if (strcmpi(type, 'delay_send')) % a send signal
        data = data.data;
        if (data.source == ID) 
            status = common_layer(N, make_event(t, 'Send_Packet', ID, data));
        else
            msgs = memory.received;
            counts = memory.counts;
            n=size(msgs); 
            n=n(1);
            for i=1:n, 
                if (msgs(i,:)==[data.source, data.msgID, data.seqID])
                    c = counts(i);
                    sendprob = eval(pfunc);
                    if (rand<sendprob) 
                        status = common_layer(N, make_event(t, 'Send_Packet', ID, data));
                    end
                end
            end
        end
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

