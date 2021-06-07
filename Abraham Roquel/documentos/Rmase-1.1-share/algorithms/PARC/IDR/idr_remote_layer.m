function status = idr_remote_layer(N, S)

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
% Last modified: Aug. 16, 2004  by YZ

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

global NEIGHBORS
global DESTINATIONS
global distanceThreshold

persistent NQValues
persistent NTValues
persistent MinInfoGain
persistent IDRMaxHops
persistent IDRType
persistent alpha
persistent delta
persistent MinTargetValue

persistent knownLocation
persistent posExit
persistent hopDistance
persistent dist

persistent percentDOA  %DOA sensor percentage

switch event
case 'Init_Application'
    if (ix==1) %only need to compute it once
        sim_params('set_app', 'Promiscuous', 1); %broadcast only
        MinInfoGain = sim_params('get_app', 'MinInfoGain');
        if (isempty(MinInfoGain)) MinInfoGain = 0; end
        IDRMaxHops = sim_params('get_app', 'IDRMaxHops');
        if (isempty(IDRMaxHops)) IDRMaxHops = Inf; end
        IDRType = sim_params('get_app', 'IDRType'); %greedy, learning and probabilistic
        if (isempty(IDRType)) IDRType = 'learning'; end;
        alpha = sim_params('get_app', 'LearningRate');
        if (isempty(alpha)) alpha = 1; end
        delta = sim_params('get_app', 'HopDelta');
        if (isempty(delta)) delta = 1; end
        if (isempty(MinTargetValue)) MinTargetValue = 1; end
        MinUtilValue = sim_params('get_app', 'MinUtilValue');
        knownLocation = sim_params('get_app', 'KnownLocation');
        if (isempty(knownLocation)) knownLocation = 1; end
        hopDistance = sim_params('get_app', 'HopDistance');
        if (isempty(hopDistance)) hopDistance = 2; end
        xDist = sim_params('get_app', 'Xdist');
        yDist = sim_params('get_app', 'Ydist');
        dist = min(xDist, yDist);
        percentDOA = sim_params('get_app', 'DOASensorProb'); %percentage of DOA type
        if (isempty(percentDOA)) percentDOA = 0.3; end
    end
    Set_Init_Clock(1000);
    NQValues{ID} = [];
    NTValues{ID} = [];
    ATTRIBUTES{ID}.QValue = 0;
    ATTRIBUTES{ID}.TValue = 0;
    
    
    
case 'Send_Packet'
    try msgID = data.msgID; catch msgID = 0; end
    data.QValue = ATTRIBUTES{ID}.QValue;
    data.TValue = ATTRIBUTES{ID}.TValue;
    
    if (msgID >= 0)
        if (~data.forward) data.hops = 0; data.targetFound = 0; prowler('DrawDelete', inf, inf); end
        nsensors = list_all(ATTRIBUTES{ID}.nsensors);
        hopsleft = IDRMaxHops-data.hops;
        if (knownLocation)
            utilities = -0.1*ComputeUtility(posExit, hopsleft*hopDistance, ATTRIBUTES{ID}.belief, nsensors, dist, percentDOA);
        else
            utilities = -ComputeMutualInfo(ATTRIBUTES{ID}.belief, nsensors, distanceThreshold);
            utilities = utilities';
        end
        if (data.targetFound)
            overall = NQValues{ID}(1:length(utilities));
        else
            overall = NTValues{ID}(1:length(utilities));
        end
        if (hopsleft > (ATTRIBUTES{ID}.QValue+delta)) %use overall evaluation
            overall = MinInfoGain*overall + utilities;  
            if (strcmp(IDRType, 'learning'))
               [value, index]=min(overall);
            else  %rand choices according to utilities
               eoverall = exp(-overall);
               eoverall = eoverall/sum(eoverall);
               [evalue, index] = prob_choice(eoverall);
            end
        else
            [value, index]=min(NQValues{ID}(1:length(utilities)));
            disp('Use shortest path');
        end    
        data.address = NEIGHBORS{ID}(index);
    end
       
case 'Packet_Received'
    try msgID = data.data.msgID; catch msgID = 0; end
    data.data.forward = 1;
    
    if (ATTRIBUTES{ID}.r > MinTargetValue)
       ATTRIBUTES{ID}.TValue = 0; 
       if (data.data.address==ID)
           data.data.targetFound = 1;
       end
    else 
               
        nID = find(NEIGHBORS{ID}==data.data.from);
        
        if (~isempty(nID))
             NTValues{ID}(nID) = data.data.TValue;
             nsensors = list_all(ATTRIBUTES{ID}.nsensors);
             len = min(length(nsensors), length(NTValues{ID}));
             ATTRIBUTES{ID}.TValue = (1-alpha)*ATTRIBUTES{ID}.TValue+...
                 alpha*(min(NTValues{ID}(1:len))+mcbr_cost);      
        end
        
    end
    
    if (DESTINATIONS(ID))
        ATTRIBUTES{ID}.QValue = 0; 
    else 
               
        nID = find(NEIGHBORS{ID}==data.data.from);
        
        if (~isempty(nID))
             NQValues{ID}(nID) = data.data.QValue;
             ATTRIBUTES{ID}.QValue = (1-alpha)*ATTRIBUTES{ID}.QValue+alpha*...
                 (min(NQValues{ID}(1:length(ATTRIBUTES{ID}.nsensors)))+mcbr_cost);      
        end
        
        if ((msgID >= 0) && (data.data.address==ID)) %real data address to me
              data.data.hops = data.data.hops + 1; 
              PrintMessage('f');
              status = idr_remote_layer(N, make_event(t, 'Send_Packet', ID, data.data));
        end
        
    end
    
    
    
    if ((msgID>=0) && (data.data.address == ID) && DESTINATIONS(ID))
        DisplayBelief;
    elseif (msgID>=0)
        pass = 0;
    end
    
case 'Clock_Tick'
    try type = data.type; catch type = 'none'; end
    
    if (strcmp(type, 'idr_init'))
        ATTRIBUTES{ID}.QValue = mcbr_dest;
        pass = 0;
        
        if (DESTINATIONS(ID))
            posExit(1) = ATTRIBUTES{ID}.x;
            posExit(2) = ATTRIBUTES{ID}.y;
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

function b=Set_Init_Clock(alarm_time);
global ID
clock.type = 'idr_init';
prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));

function list = list_all(carray)

list = [];
for i=1:length(carray)
    list = [list, carray{i}];
end

function [util, index] = prob_choice(utilities)

index = 0;
value = rand;
sum = 0;
for i=1:length(utilities)
    if (value >= sum) 
        sum = sum+utilities(i);
        index = index+1;
    end
end
util = utilities(index);

function utilities = ComputeUtility(PosExit, distance, belief, nsensors, dist, percentDOA)

for i = 1:length(nsensors)
    utilities(i) = UtilityEllipseSampled(nsensors(i).pos,nsensors(i).kind,PosExit,distance,belief,dist,percentDOA);
end
