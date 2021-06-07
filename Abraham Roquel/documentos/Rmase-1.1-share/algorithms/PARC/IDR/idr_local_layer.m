function status = idr_local_layer(N, S)

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
global distanceThreshold

persistent NQValues
persistent alpha

persistent IDRType
persistent MinInfoGain
persistent IDRMaxHops
persistent MinTargetValue
persistent MinUtilValue

switch event
case 'Init_Application'
    if (ix==1) %only need to compute it once
        IDRType = sim_params('get_app', 'IDRType'); %greedy, learning and probabilistic
        if (isempty(IDRType)) IDRType = 'learning'; end;
        MinInfoGain = sim_params('get_app', 'MinInfoGain');
        if (isempty(MinInfoGain)) MinInfoGain = 0; end
        IDRMaxHops = sim_params('get_app', 'IDRMaxHops');
        if (isempty(IDRMaxHops)) IDRMaxHops = Inf; end
        sim_params('set_app', 'Promiscuous', 1); %overhear to learn
        alpha = sim_params('get_app', 'LearningRate');
        if (isempty(alpha)) alpha = 1; end
        MinTargetValue = sim_params('get_app', 'MinTargetValue');
        if (isempty(MinTargetValue)) MinTargetValue = 1; end
        MinUtilValue = sim_params('get_app', 'MinUtilValue');
        if (isempty(MinUtilValue)) MinUtilValue = 0.5; end
    end
    Set_Init_Clock(1000);
    NQValues{ID} = [];
    ATTRIBUTES{ID}.QValue = 0;
    memory.count = 0;
    
case 'Send_Packet'
    try msgID = data.msgID; catch msgID = 0; end
    data.QValue = ATTRIBUTES{ID}.QValue;
    
    if (msgID >= 0)
        nsensors = list_all(ATTRIBUTES{ID}.nsensors);
        if (isempty(nsensors))
            pass = 0;
        else
            utilities = -ComputeMutualInfo(ATTRIBUTES{ID}.belief, nsensors, distanceThreshold);
            utilities = utilities';
            
            if (~data.forward) data.hops = 0; prowler('DrawDelete', inf, inf); end    
            if (strcmp(IDRType, 'greedy')) %greedy
                [util, index] = min(utilities);
            else
                if (~isempty(NQValues{ID}))
                    len = min(length(nsensors), length(NQValues{ID}));
                    overall = NQValues{ID}(1:len);   
                    if (ATTRIBUTES{ID}.r > MinUtilValue)
                        overall = MinInfoGain*overall + utilities(1:len); 
                    end
                else 
                    overall = utilities;
                end
                
                if (strcmp(IDRType, 'learning') && ~isempty(NQValues{ID}))
                    [util, index] = min(overall);
                else  %rand choices according to utilities
                    eoverall = exp(-overall);
                    eoverall = eoverall/sum(eoverall);
                    [eutil, index] = prob_choice(eoverall);
                end
            end
        
            if (~index || index>length(nsensors)) 
                pass = 0;
            elseif ((max(-utilities)<MinInfoGain) && (ATTRIBUTES{ID}.r > MinTargetValue) && data.forward)
                pass = 0;
                common_layer(N, make_event(t, 'Packet_Received', ID, radiostream(data, 0)));
                DisplayBelief;
            else
                data.address = NEIGHBORS{ID}(index);
            end
        end
    end
       
case 'Packet_Received'
    try msgID = data.data.msgID; catch msgID = 0; end
    data.data.forward = 1;
    try duplicated = data.duplicated; catch duplicated = 0; end
    
    if (ATTRIBUTES{ID}.r > MinTargetValue)
        ATTRIBUTES{ID}.QValue = 0; 
    else 
               
        nID = find(NEIGHBORS{ID}==data.data.from);
        
        if (~isempty(nID))
             NQValues{ID}(nID) = data.data.QValue;
             nsensors = list_all(ATTRIBUTES{ID}.nsensors);
             len = min(length(nsensors), length(NQValues{ID}));
             ATTRIBUTES{ID}.QValue = (1-alpha)*ATTRIBUTES{ID}.QValue+...
                 alpha*(min(NQValues{ID}(1:len))+mcbr_cost);      
        end
    end
        
    if ((msgID >= 0) && (data.data.address==ID)) %real data address to me
          data.data.hops = data.data.hops + 1;
          if (data.data.hops < IDRMaxHops)
              PrintMessage('f');
              status = idr_local_layer(N, make_event(t, 'Send_Packet', ID, data.data));
          end
    end
        
    
    
    if (msgID>=0) 
       if ((data.data.address == ID) && (data.data.hops >= IDRMaxHops))
           DisplayBelief;
       else
           pass = 0;
       end
    end
    
    
case 'Clock_Tick'
    try type = data.type; catch type = 'none'; end
    
    if (strcmp(type, 'idr_init'))
        ATTRIBUTES{ID}.QValue = mcbr_dest;
        pass = 0;
    end
    
    if (strcmp(data.type, 'sensor_reading'))
        pass = 0;
        if (ATTRIBUTES{ID}.r > MinTargetValue)
            ATTRIBUTES{ID}.QValue = 0;
            memory.count = memory.count + 1;
            if (~mod(memory.count, 10))
                PrintMessage('b');
                sdata.address = 0;
                sdata.QValue = 0;
                sdata.msgID = -1;  
                status = common_layer(N, make_event(t, 'Send_Packet', ID, sdata));
            end
        else
            memory.count = 0;
        end
    end  
    
case {'Application_Stopped','Application_Finished'}
    %DisplayBelief;
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
    



