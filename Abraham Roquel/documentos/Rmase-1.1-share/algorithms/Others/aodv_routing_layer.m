function status = aodv_routing_layer(N, S)

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

% Written by Guoliang Xing, gxing@parc.com
% Last modified: Nov. 22, 2003  by GX
% Last modified: Jan. 7, 2005 by YZ

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

global routeTable rreqCache 
global DESTINATIONS NEIGHBORS LTOTALS 
global INVALID_INDEX AODV_RQCACHE_SIZE AODV_RTABLE_SIZE 
global RREQ_TIMEOUT INVALID_NODE_ID INVALID_MSG_ID RREQ_MSG_ID RREP_MSG_ID RERR_MSG_ID
global CHECK_PERIOD RREP_DELAY RREP_RETRIES RREQ_VALUE RREP_VALUE RREQ_DELAY
global bittime rreqID LINK_RATIO 

switch event
case 'Init_Application'
    if (ix==1) %only executed once
        
        AODV_RQCACHE_SIZE = sim_params('get_app', 'AODV_RQCACHE_SIZE');
        AODV_RTABLE_SIZE = sim_params('get_app', 'AODV_RTABLE_SIZE');
        INVALID_NODE_ID = -1;
        INVALID_MSG_ID = -100;
        RREP_MSG_ID = -1;
        RREQ_MSG_ID = -2;
        RERR_MSG_ID = -3;
        INVALID_INDEX = -1;
        RREQ_VALUE = 10;
        RREP_VALUE = 11;
        RERR_VALUE = 12;
        RREP_RETRIES = sim_params('get_app', 'RREP_RETRIES');
        
        loginit('log/aodv.log', 'aodv', 1);
        
        bittime = sim_params('get', 'BIT_TIME');
        
        RREP_DELAY = sim_params('get_app', 'RREP_DELAY');
        RREQ_TIMEOUT = sim_params('get_app', 'RREQ_TIMEOUT'); %1s to wait for a reply of RREQ
        RREQ_DELAY = sim_params('get_app', 'RREQ_DELAY');
        CHECK_PERIOD = 10/bittime;
        LINK_RATIO = 0.5;
        rreqID=0;
    end
    
    %preallocate the cache and routing table
    aodv_rtable_entry = struct('source',INVALID_NODE_ID,'msgID',INVALID_MSG_ID,'nextHop',INVALID_NODE_ID,'destSeq',0,'numHops',inf);
    routeTable{ID} = repmat(aodv_rtable_entry,1,AODV_RTABLE_SIZE);
    aodv_rcache_entry = struct('source',INVALID_NODE_ID,'msgID',INVALID_MSG_ID,'rreqID',0,'destSeq',0,'nextHops',INVALID_NODE_ID,'rrepSent',0);
    rreqCache{ID} = repmat(aodv_rcache_entry,1,AODV_RQCACHE_SIZE);
    Set_Timeout_Clock(CHECK_PERIOD,'link_check',0);
    
case 'Send_Packet'
    data.from = ID;
    if (data.source == ID && data.msgID>=0)
        %we are the source, send the data packet if we have a routing table entry for it,
        %otherwise send a RREQ (if hasn't been sent) and ignore the data. 
        routePacket(data);
        pass=0;
    end
    
 case 'Packet_Received'
    %ignore the packet not addressed to us
    try address = data.data.address; catch address = 0; end
    if address && address ~= ID
        status = 0;
        return;
    end
    pass = 0;
    try msgType = data.data.msgType; catch msgType = ''; end
    logevent('Recved',data.data);
    switch msgType
        case 'RREQ'
            recvRREQ(data.data);
        case 'RREP'
            if address
                recvRREP(data.data);
            end
        case 'RERR'
            if address
                sendRouteErr(data.data,1);
            end
        otherwise
            countPacket(data.data,'Recved');
            routePacket(data.data);
            try dup = data.duplicated; catch dup = 0; end
            if DESTINATIONS(ID) && (dup==0) && data.data.msgID>=0
                pass = 1;
            end
    end

case 'Collided_Packet_Received'
    logevent('Collided',data.data);
    
case 'Clock_Tick'
    try type = data.type; catch type = 'none'; end
    switch type
        case 'link_check'
            for i=1:size(routeTable{ID},2)
                try recved = routeTable{ID}(i).recved; catch recved=0; end
                try lost = routeTable{ID}(i).lost; catch lost=0; end
                if isempty(recved) recved = 0; end
                if isempty(lost) lost = 0; end

                if recved || lost
                    x=0;
                end
                if (recved && (lost/(lost+recved)>LINK_RATIO))
                    rdata.aodv_src = routeTable{ID}(i).source;
                    rdata.msgID = routeTable{ID}(i).msgID;
                    % need optimization to avoid too many talbe lookups
                    sendRouteErr(rdata,0);
                    logevent('dump_rtable',0);
                    %new route discovery will get rid of broken link from
                    %the routing table
                    %removeRtable(rdata.aodv_src,rdata.msgID,0);                    
                end
                routeTable{ID}(i).recved = 0;
                routeTable{ID}(i).lost = 0;
            end
            Set_Timeout_Clock(CHECK_PERIOD,'link_check',0);
                
        case 'confirm_timeout'
            rdata = data.data;
            try address = rdata.address; catch address = 0; end
            try source = rdata.aodv_src; catch source = rdata.source; end
            try recved = routeTable{ID}(index).recved; catch recved=-1; end
            
            index = getRtableIndex(source,rdata.msgID);
            if isempty(recved) recved = -1; end
            if index~=INVALID_INDEX && recved>0
                %recved packet already, path has been set up
                return;
            end
                
            try type = rdata.msgType; catch type = 'DAT'; end
            if (~address) return; end %ignore broadcast
            switch type
                case 'DAT'
                    countPacket(rdata,'Lost');
                    logevent('dump_rtable',0,'data lost');
                case 'RREP'
                    index = find(NEIGHBORS{ID}==address);
                    if ~isempty(index) 
                        LTOTALS{ID}(index) = LTOTALS{ID}(index)+1;
                    end
                    %retrying
                    try retry = rdata.rrep_retry; 
                    catch rdata.rrep_retry = RREP_RETRIES; 
                    end
                    rdata.rrep_retry = rdata.rrep_retry-1;
                    if rdata.rrep_retry>=0
                        rdata.address = getReverseRoute(rdata);
                        if rdata.address~=INVALID_NODE_ID
                            aodv_routing_layer(N, make_event(t, 'Send_Packet', ID, rdata));  
                            logevent('Resent',rdata,strcat('retrying ',num2str(RREP_RETRIES-rdata.rrep_retry)));
                        end
                    end                    
                    logevent('dump_rcache',0);
                    logevent('dump_rtable',0);
            end
        case 'rreq_timeout'
            %stop waiting for the rrep and remove the 'waiting' entry in routing table
            removeRtable(data.data.aodv_src,data.data.msgSubID,1);
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

function countPacket(pkt,event)
global DESTINATIONS routeTable INVALID_INDEX routeTable ID 
if DESTINATIONS(ID)
    return;
end

i=getRtableIndex(pkt.source,pkt.msgID);
if  i~=INVALID_INDEX 
    if strcmp(event,'Recved')
        try recved = routeTable{ID}(i).recved; catch recved = 0; end
        routeTable{ID}(i).recved = recved+1;
    else
        try lost = routeTable{ID}(i).lost; catch lost = 0; end
        routeTable{ID}(i).lost = lost+1;
    end
end

function recvRREQ(rreq)
global NEIGHBORS DESTINATIONS RREP_DELAY rreqCache ID t RREQ_DELAY RREQ_VALUE RREP_VALUE AODV_RQCACHE_SIZE INVALID_INDEX AODV_RTABLE_SIZE INVALID_NODE_ID INVALID_MSG_ID RREQ_MSG_ID RREP_MSG_ID RERR_MSG_ID

logevent('dump_rcache',0);
logevent('dump_rtable',0);
%update the cache 
new = updateCache(rreq);
if ~new return; end
if DESTINATIONS(ID)
    %send the reply to rreq
    rrep_msg.address = getReverseRoute(rreq);
    if rrep_msg.address == INVALID_NODE_ID
        rrep_msg.address
    end
        
    rrep_msg.msgID = RREP_MSG_ID;
    rrep_msg.msgSubID = rreq.msgSubID;
    rrep_msg.source = ID;
    rrep_msg.aodv_src = rreq.aodv_src;
	rrep_msg.destSeq = rreq.destSeq;
    rrep_msg.msgType = 'RREP';
    %destination is 0 hops away
	rrep_msg.numHops = 0; 
    rrep_msg.value = RREP_VALUE;
    aodv_routing_layer(find_layer('aodv_routing'), make_event(t+RREP_DELAY, 'Send_Packet', ID, rrep_msg));
    
elseif rreq.aodv_src ~= ID 
    %broadcast the rreq msg
    rreq.numHops = rreq.numHops+1;
    rreq.address = 0;
    %forward the pkt, 'forward' is used by delay layer to add random delay
    rreq.forward = 1;
    %rebroadcast the rreq with a random delay
    aodv_routing_layer(find_layer('aodv_routing'), make_event(t+rand*RREQ_DELAY, 'Send_Packet', ID, rreq));
    
end
logevent('dump_rcache',0);
logevent('dump_rtable',0);

function recvRREP(rrep)
global routeTable ID t RREQ_VALUE RREP_VALUE INVALID_NODE_ID RREP_RETRIES

logevent('dump_rcache',0);
logevent('dump_rtable',0);
%remember the nexthop
ret = addRtableEntry(rrep);
if rrep.aodv_src == ID %aodv_src
    rrep.address = 0;
    rrep.forward = 1;
    %source also forward the RREP, to annouce the succefull receiving
    aodv_routing_layer(find_layer('aodv_routing'), make_event(t, 'Send_Packet', ID, rrep));
    
elseif ret
    %added to rtable successfully, forward the rrep
    rrep.numHops = rrep.numHops+1;    
    rrep.rrep_retry = RREP_RETRIES;
    % get the previous hop
    rrep.address = getReverseRoute(rrep);
    rrep.forward = 1;
    if rrep.address~=INVALID_NODE_ID
        aodv_routing_layer(find_layer('aodv_routing'), make_event(t, 'Send_Packet', ID, rrep));  
        
    end
end
logevent('dump_rcache',0);
logevent('dump_rtable',0);

function lvalue = getLvalue(hops,id)
global ID NEIGHBORS LTOTALS
index = find(NEIGHBORS{ID} == id);
if isempty(index) 
    lvalue = inf;
    return; 
end
lvalue = hops + exp(LTOTALS{ID}(index))-1;

function updateLvalues(index)
global ID NEIGHBORS LTOTALS rreqCache
i=0;
for id = [rreqCache{ID}(index).nextHops.id]
    i = i+1;
    rreqCache{ID}(index).nextHops(i).lvalue = getLvalue(rreqCache{ID}(index).nextHops(i).numHops,id);
end

%get the nexthop on the reverse route with the min failure counts and hop
%counts
function r=getReverseRoute(pkt)
global ID NEIGHBORS rreqCache AODV_RQCACHE_SIZE INVALID_NODE_ID INVALID_MSG_ID 
try msgID = pkt.msgSubID; catch msgID = pkt.msgID; end
r = INVALID_NODE_ID;
index = 1;
found = 0;
for index=1:size(rreqCache{ID},2)
    if [rreqCache{ID}(index).source rreqCache{ID}(index).msgID] == [pkt.aodv_src msgID]
        found = 1;
        break;
    end
end
if ~found return; end

%find the neighbors with the minimal failure cnt
updateLvalues(index);
[X i] = min([rreqCache{ID}(index).nextHops.lvalue]);
if isempty(i) return; end
r = rreqCache{ID}(index).nextHops(i(1)).id;

function ret=updateCache(rreq)
global rreqCache AODV_RQCACHE_SIZE INVALID_NODE_ID INVALID_MSG_ID ID
replaceIndex = -1;
endIndex = -1;
i=1;
ret = 0;
for i=1:AODV_RQCACHE_SIZE
    if rreqCache{ID}(i).msgID == INVALID_MSG_ID || rreqCache{ID}(i).source == INVALID_NODE_ID
        break;
    end
    if(rreqCache{ID}(i).source == rreq.aodv_src && rreqCache{ID}(i).msgID == rreq.msgSubID)
        if rreq.rreqID<rreqCache{ID}(i).rreqID
            return;
        end
		break;
    end
end
% we should be at the right place now
rreqCache{ID}(i).msgID = rreq.msgSubID;
rreqCache{ID}(i).source = rreq.aodv_src;
rreqCache{ID}(i).destSeq = rreq.destSeq;
if rreqCache{ID}(i).rreqID < rreq.rreqID
    %expire the old entry
    rreqCache{ID}(i).rreqID = rreq.rreqID;
    rreqCache{ID}(i).nextHops = struct('id',rreq.from,'numHops',rreq.numHops,'lvalue',getLvalue(rreq.numHops,rreq.from));
    ret = 1;
    return;    
else
    %the same rreqID, rebroadcast only if the numHops is smaller than the
    %min numHops in the cache
    neighbors = rreqCache{ID}(i).nextHops;
    if rreq.numHops < min([neighbors.numHops])
        ret = 1;
    end
    index = find([neighbors.id] == rreq.from);
    if isempty(index)
        neighbors =[neighbors struct('id',rreq.from,'numHops',rreq.numHops,'lvalue',getLvalue(rreq.numHops,rreq.from))];
    elseif neighbors(index).numHops>rreq.numHops
        neighbors(index).numHops = rreq.numHops;
    end
    rreqCache{ID}(i).nextHops = neighbors;    
end

function index=getCacheIndex(src, msgid)
global rreqCache INVALID_INDEX ID
for i=1:size(rreqCache{ID},2)
    if (rreqCache{ID}(i).source == src) && (rreqCache{ID}(i).msgID == msgid)
        index = i;
        return;
    end
end
index=INVALID_INDEX;   

function index=getRtableIndex(src, msgid)
global routeTable INVALID_NODE_ID INVALID_INDEX ID
found=0;
index = INVALID_INDEX;
i=0;
for i=1:size(routeTable{ID},2)
    if (routeTable{ID}(i).source == src) && (routeTable{ID}(i).msgID == msgid)
        found=1;
        break;
    end
    if routeTable{ID}(i).source == INVALID_NODE_ID 
        found=1;
        break;
    end
end

if found
    index = i;
end

function nextHop = lookupRtable(source,msgID)
global routeTable ID AODV_RTABLE_SIZE INVALID_NODE_ID INVALID_MSG_ID 
nextHop = INVALID_NODE_ID;
i=getRtableIndex(source,msgID);
if(i~=INVALID_NODE_ID)
    nextHop = routeTable{ID}(i).nextHop;
end

function ret=addRtableEntry(rrep)
global ID DESTINATIONS routeTable AODV_RQCACHE_SIZE AODV_RTABLE_SIZE INVALID_INDEX INVALID_NODE_ID INVALID_MSG_ID RREQ_MSG_ID RREP_MSG_ID RERR_MSG_ID
if DESTINATIONS(ID)
    %we are dest, don't need to remember the route
    ret = 1; 
    return;
end
%find a match entry or create a new one
i=getRtableIndex(rrep.aodv_src,rrep.msgSubID);
if  i~=INVALID_INDEX && (routeTable{ID}(i).msgID == INVALID_MSG_ID || routeTable{ID}(i).destSeq < rrep.destSeq) || (routeTable{ID}(i).destSeq == rrep.destSeq && routeTable{ID}(i).numHops > rrep.numHops)
    routeTable{ID}(i).source = rrep.aodv_src; %aodv_src
    routeTable{ID}(i).msgID = rrep.msgSubID;
    routeTable{ID}(i).destSeq = rrep.destSeq;
    routeTable{ID}(i).nextHop = rrep.from;
    routeTable{ID}(i).numHops = rrep.numHops;
    ret = 1;     
    return;
end
if  routeTable{ID}(i).destSeq == rrep.destSeq && routeTable{ID}(i).numHops == rrep.numHops
    %entry already exists
    ret = 1;
    return;
end
ret = 0;

function sendRreq(dat)
global RREQ_MSG_ID RREP_MSG_ID RERR_MSG_ID ID t RREQ_VALUE rreqID 
rreqID = rreqID+1;
%we need to remember msgID in the packet since (source,msgID) identifies
%the destination
rreq_msg.msgSubID = dat.msgID;
rreq_msg.msgID = RREQ_MSG_ID;
rreq_msg.source  = dat.source;
rreq_msg.aodv_src  = dat.source;
rreq_msg.rreqID = rreqID;
rreq_msg.srcSeq = 0;
rreq_msg.destSeq = 0;   
rreq_msg.numHops = 0;
rreq_msg.msgType = 'RREQ';
%broadcast rreq
rreq_msg.address = 0;
rreq_msg.from = ID;
rreq_msg.value = RREQ_VALUE;
aodv_routing_layer(find_layer('aodv_routing'), make_event(t, 'Send_Packet', ID, rreq_msg));


function removeRtable(source,msgid,waiting)
global routeTable ID INVALID_INDEX AODV_RTABLE_SIZE
index = getRtableIndex(source,msgid);
if index~=INVALID_INDEX && ((routeTable{ID}(index).nextHop==-2 && waiting) || (routeTable{ID}(index).nextHop~=-2 && ~waiting))
    for i=index:AODV_RTABLE_SIZE-1
        routeTable{ID}(i)=routeTable{ID}(i+1);
    end
end

function sendRouteErr(dat,fwd)
global routeTable ID t INVALID_INDEX INVALID_NODE_ID RERR_VALUE RREQ_MSG_ID RREP_MSG_ID RERR_MSG_ID
%dat can be a DAT or control packet
rerr_msg=0;
try source = dat.aodv_src; catch source = dat.source; end
if source == ID return; end
if ~fwd 
    %send a new rerr message 
    index = getRtableIndex(dat.aodv_src,dat.msgID);
    if index == INVALID_INDEX  return; end    
    nextHop = getReverseRoute(dat);
    if nextHop == INVALID_NODE_ID return; end
    rerr_msg.msgSubID = dat.msgID;
    rerr_msg.msgID = RERR_MSG_ID;
    rerr_msg.aodv_src  = source; %aodv_src
    rerr_msg.source  = source;
    rerr_msg.destSeq = routeTable{ID}(index).destSeq;   
    rerr_msg.msgType = 'RERR';
    rerr_msg.address = nextHop;
    rerr_msg.from = ID;
    rerr_msg.value = RERR_VALUE;
    %rerr_msg.source = ID;
else
    %forward the rerr msg
    rerr_msg = dat;
    rerr_msg.forward = 1;
end
aodv_routing_layer(find_layer('aodv_routing'), make_event(t, 'Send_Packet', ID, rerr_msg));


function routePacket(pkt)
global t ID INVALID_NODE_ID DESTINATIONS RREQ_TIMEOUT
try address = pkt.address;  catch address = 0; end
%if we are not the src and pkt is a broadcast (which occurs 
%when the application layer sends a fresh packet), ignore it
if address == 0 && pkt.source~=ID
    return;
end
nextHop = lookupRtable(pkt.source,pkt.msgID);    
if nextHop>0
    %rtable has a entry, fill in the next hop and send the data
    pkt.address = nextHop;
    pkt.from = ID;
    if pkt.source ~= ID
        pkt.forward = 1;
    end
    common_layer(find_layer('aodv_routing'), make_event(t, 'Send_Packet', ID, pkt));        
    logevent('Sent',pkt);
elseif pkt.source == ID && nextHop == INVALID_NODE_ID
    % a RREQ has not been sent, send the RREQ and ignore (or buffer?) the data packet
    rrep.from = -2;
    rrep.aodv_src = pkt.source; %aodv_src
    rrep.source = ID;
    rrep.msgSubID = pkt.msgID;
    rrep.destSeq = -100;
    rrep.numHops = inf;
    %don't need to fill other info, since no one will match us
    addRtableEntry(rrep);
    %send a rreq
    sendRreq(pkt);
    %set the waiting time for the reply of rreq
    Set_Timeout_Clock(RREQ_TIMEOUT, 'rreq_timeout',rrep);
elseif DESTINATIONS(ID)
    % send the pkt to announce the receiving
    pkt.address = 0;
    common_layer(find_layer('aodv_routing'), make_event(t, 'Send_Packet', ID, pkt));
    logevent('Sent',pkt);
end

function Set_Timeout_Clock(timeout, type, data)
global ID t
clock.type = type;
clock.data = data;
prowler('InsertEvents2Q', make_event(t+timeout, 'Clock_Tick', ID, clock));
     
    
            
            
            