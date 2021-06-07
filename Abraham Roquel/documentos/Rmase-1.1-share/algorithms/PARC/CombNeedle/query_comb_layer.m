function status = query_comb_layer(N, S)

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

%this code implements Comb_Needle query model given by Xin and Qingfeng

persistent duplicationLength
persistent queryWidth
persistent minY maxY

global DESTINATIONS

switch event
case 'Init_Application'   
    if (ix==1) %only need to compute it once
        duplicationLength = sim_params('get_app', 'DuplicationLength');
        if (isempty(duplicationLength)) duplicationLength = 1; end 
        queryWidth = sim_params('get_app', 'QueryWidth');
        if (isempty(queryWidth)) queryWidth = 0.5; end
        [topology, mote_IDs] = prowler('GetTopologyInfo');
        minY = min(topology(:,2));
        maxY = max(topology(:,2));
    end % end of compute once for all
    
    memory = struct('events', [], 'returns', []);
    
case 'Send_Packet'
    try msgID = data.msgID; catch msgID = 0; end
    try forward = data.forward; catch forward = 0; end
    
    if ((msgID == -inf) && (~forward)) %query from query node      
        data.x = ATTRIBUTES{ID}.x;
        data.y = ATTRIBUTES{ID}.y;
        combSpace = sim_params('get_app', 'CombSpace');
        if (isempty(combSpace)) combSpace = 3; end 
        data.s = combSpace;       
    elseif (msgID == -1)  %return events at this node
        %do nothing
    else %log its data into memory
        if (~forward)
            data.x = ATTRIBUTES{ID}.x;
            data.y = ATTRIBUTES{ID}.y;
            memory.events = [memory.events, data];
        end
    end
               
case 'Packet_Received'
    try duplicated = data.duplicated; catch duplicated = 0; end
    try msgID = data.data.msgID; catch msgID = 0; end
    data.data.forward = 1;
    
    pass = 0;
    if (msgID == -inf) %query
         
        if (atComb(data.data, queryWidth, minY, maxY) && (~duplicated)) %first arrive at comb branch
            query_comb_layer(N, make_event(t, 'Send_Packet', ID, data.data)); %pass again
            events = getEvents(memory.events, data.data);
            if (~isempty(events)) 
                returnQuery(N, events, data.data);  
            end
        end
    elseif (msgID == -1) %return query
        if (DESTINATIONS(ID)) %arrive destination
            if (~duplicated)
                for i=1:length(data.data.events)
                    event = data.data.events(i);
                    idx = findIndex(memory.returns, event);
                    if (isempty(idx))
                        memory.returns = [memory.returns, event];
                        dispatch.data = event;
                        dispatch.signal_strength = data.signal_strength;
                        common_layer(N, make_event(t, 'Packet_Received', ID, dispatch));
                    end
                end
            end
        elseif (inPath(data.data, queryWidth) && (~duplicated))
            query_comb_layer(N, make_event(t, 'Send_Packet', ID, data.data)); %pass again
        end
    else %events
        if (atNeedle(data.data, duplicationLength+queryWidth, queryWidth) && (~duplicated)) %first arrive at needle
            memory.events = [memory.events, data.data];
            query_comb_layer(N, make_event(t, 'Send_Packet', ID, data.data)); %pass again
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

function out = atNeedle(data, L, W)
global ID
global ATTRIBUTES

out = ((abs(ATTRIBUTES{ID}.x-data.x) < W) && ...
    (abs(ATTRIBUTES{ID}.y-data.y)<=L));

function out = atComb(data, L, minY, maxY)
global ID
global ATTRIBUTES

dis = mod(abs(ATTRIBUTES{ID}.y-data.y), data.s);
out = ((abs(ATTRIBUTES{ID}.x-data.x) < L) || ...
    (min(dis, data.s-dis) < L) || ...
    ATTRIBUTES{ID}.y < minY + L || ... %boundary conditions
    ATTRIBUTES{ID}.y > maxY - L);

function out = inPath(data, L)
global ID
global ATTRIBUTES

out = (abs(ATTRIBUTES{ID}.y-data.y) < L) && ...
    ((ATTRIBUTES{ID}.x-data.sx) * (data.x-ATTRIBUTES{ID}.x) >= 0) || ...
    (abs(ATTRIBUTES{ID}.x-data.sx) < L) && ...
    ((ATTRIBUTES{ID}.y-data.sy) * (data.y-ATTRIBUTES{ID}.y) >= 0);
    
function out = getEvents(events, data)
out = [];
for i=1:length(events)
    event = events(i);
    if ((event.startTime < data.startTime+data.window) && ...
        (event.startTime > data.startTime-data.window))
        out = [out, event];
    end
end

function status = returnQuery(N, events, qdata)
global ID t
global ATTRIBUTES

data.events = events;
data.msgID = -1;
data.forward = 0;
data.source = ID;
data.x = ATTRIBUTES{ID}.x;
data.y = ATTRIBUTES{ID}.y;
data.sx = qdata.x;
data.sy = qdata.y;

query_comb_layer(N, make_event(t+8000, 'Send_Packet', ID, data)); 

function idx = findIndex(returns, event)
idx = [];

for i=1:length(returns)
    if (isequal(returns(i), event))
        idx = i;
        return;
    end
end
