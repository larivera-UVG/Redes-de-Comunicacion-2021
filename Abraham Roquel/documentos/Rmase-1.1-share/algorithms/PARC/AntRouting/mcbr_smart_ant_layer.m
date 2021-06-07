function status = mcbr_smart_ant_layer(N, S)

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

% Written by Ying Zhang, yzhang@parc.com, modified from Lukas Kuhn's code
% Last modified: Feb. 17, 2004  by YZ

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
global SOURCES

persistent antInterval
persistent antStart
persistent probability
persistent windowSize
persistent eta
persistent c1 c2
persistent z
persistent rewardScale
persistent dataGain
persistent probGain

persistent backDelayMin
persistent backDelayRand

switch event
case 'Init_Application'
    if (ix==1)
        antStart = sim_params('get_app', 'AntStart');
        if (isempty(antStart)) antStart = 120000; end % 3 sec
        antRatio = sim_params('get_app', 'AntRatio');
        if (isempty(antRatio)) antRatio = 2; end % 1:2 control packets
        sourceRate = sim_params('get_app', 'SourceRate');
        if (isempty(sourceRate)) sourceRate = 0.1; end %10 sec 1 msg
        antInterval = antRatio*40000/sourceRate; 
        windowSize = sim_params('get_app', 'WindowSize');
        if (isempty(windowSize)) windowSize = 10; end
        eta = min(5/windowSize, 1);
        c1 = sim_params('get_app', 'C1');
        if (isempty(c1)) c1 = 0.7; end
        c2 = 1-c1;
        z = sim_params('get_app', 'Z');
        if (isempty(z)) z = 1; end
        rewardScale = sim_params('get_app', 'RewardScale');
        if (isempty(rewardScale)) rewardScale = 0.3; end
        dataGain = sim_params('get_app', 'DataGain');
        if (isempty(dataGain)) dataGain = 1.2; end
        probGain = sim_params('get_app', 'ProbGain');
        if (isempty(probGain)) probGain = 1.2; end
        
        backDelayMin = sim_params('get_app', 'BackDelayMin');
        if (isempty(backDelayMin)) backDelayMin = 40000; end %1 sec
        backDelayRand = sim_params('get_app', 'BackDelayRand');
        if (isempty(backDelayRand)) backDelayRand = 20000; end %0.5 sec
        
    end
    probability{ID} = [];
    memory = struct('average', 0, 'variance', 0, 'window', [],  'potentials', [], 'interval', antInterval);
    Set_Start_Clock(antStart); %start forward ant 
case 'Send_Packet'
    
    try msgID = data.msgID; catch msgID = 0; end   
    try list = data.list; catch list = [];  end
    
    if (msgID == -inf) %init packet
        if (isempty(memory.potentials)|| DESTINATIONS(ID))
            data.cost = mcbr_dest;
        else
            data.cost = mcbr_cost + min(memory.potentials);
        end
    end
           
    if (msgID == -2) %backward ant
        try
            data.address = list(1);
            data.list = list(2:length(list));
            PrintMessage(['<-', num2str(data.address')]);
        catch
            pass = 0;
        end
    elseif (msgID == -1)  %forward ant
        data.list = [ID, list];
        data.address = 0; %broadcast       
    elseif (msgID >= 0) % data packet
       try
           total = 0;
           for ndx = 1:length(NEIGHBORS{ID})
               total = total + probability{ID}(ndx)^dataGain;
           end
           %total can be < 1 since power is applied
           if (total==0)
               probability{ID} = ones(1, length(probability{ID}))/length(probability{ID});
               total = 1;
           end
           prob = rand*total;
           for ndx = 1:length(NEIGHBORS{ID})
               if (prob>0)
                   prob = prob - probability{ID}(ndx)^dataGain;
                   if(prob <=0)
                      data.address = NEIGHBORS{ID}(ndx);
                      data.width = 5*probability{ID}(ndx);
                      PrintMessage(['f', num2str(data.address')]);
                   end
               end
           end
       catch
           pass = 0;
       end
    end
        
case 'Packet_Received'
    rdata = data.data;
    try duplicated = data.duplicated; catch duplicated = 0; end
    try msgID = rdata.msgID; catch msgID = 0; end
    try list = rdata.list; catch list = []; end
    nID = find(NEIGHBORS{ID}==rdata.from);
    
    data.data.forward = 1;
    
    pass=0;
        
    if (msgID ~= -inf)
        try prob = probability{ID}(nID);
        catch probability{ID}(nID) = 0;
        end
    else
        memory.potentials(nID) = rdata.cost;
    end   
    
    if (msgID == -1) %forward ant
        if( DESTINATIONS(ID))
            antBackward.msgID = -2;
            antBackward.list = rdata.list;          
            antBackward.cost = memory.average;
            
            %delay for some time to avoid collison at the destination
            status = mcbr_smart_ant_layer(N, make_event(t+backDelayMin+backDelayRand*rand, 'Send_Packet', ID, antBackward));
        elseif (~duplicated && (probability{ID}(nID) < 1/length(probability{ID}))) %forward only if ant from weak link
            status = mcbr_smart_ant_layer(N, make_event(t, 'Send_Packet', ID, data.data));
        end
    end
           
    if ((msgID == -2) && (~duplicated)) %backward ant
        data.data.cost = rdata.cost + mcbr_cost;
        if (isempty(memory.window))
            memory.average = data.data.cost;
            memory.window = [data.data.cost];
        else
            memory.average = memory.average + eta*(data.data.cost - memory.average);
            memory.variance = memory.variance +eta*((data.data.cost - memory.average)^2-memory.variance);
            memory.window = [data.data.cost, memory.window];
            memory.window = memory.window(1:min(windowSize, length(memory.window)));
        end
        
        Iinf = min(memory.window);
        Isup = memory.average + z*sqrt(memory.variance/windowSize);
        r = c1*Iinf/data.data.cost;
        tmp = (Isup-Iinf) + (data.data.cost-Iinf);
        if (tmp>0)
            r = r + c2*(Isup-Iinf)/tmp;
        end
        if (data.data.address==ID) %I am in the path, reinforce it
            probability{ID} = Set_New_Prob(probability{ID}, nID, rewardScale*r);
            if (~SOURCES(ID))          
                status = mcbr_smart_ant_layer(N, make_event(t, 'Send_Packet', ID, data.data));
            else
                memory.interval = memory.interval*exp(r-0.5);
            end
        else %I am not in path, but maybe good to go through that node too
            probability{ID} = Set_New_Prob(probability{ID}, nID, rewardScale*r/2);
        end
    end
    
    if (msgID >= 0) %data packet
        if (DESTINATIONS(ID))
            antBackward.msgID = -2;     
            antBackward.cost = 0;
            
            status = mcbr_smart_ant_layer(N, make_event(t, 'Send_Packet', ID, antBackward));
        end
            
        if(~DESTINATIONS(ID) && (data.data.address == ID)) %forward if is for me
            status = mcbr_smart_ant_layer(N, make_event(t, 'Send_Packet', ID, data.data));
        end
    end
    
    if ((DESTINATIONS(ID) && msgID >= 0 && (~duplicated)) || (msgID == -inf))
        pass =1;
    end
    
case 'Clock_Tick'
    try type = data.type; catch type = 'none'; end
    if (strcmp(type, 'ant_start'))
        if (isempty(probability{ID}))
            if (DESTINATIONS(ID))
                cost = 0;
            else
                cost = mcbr_cost + min(memory.potentials);
            end
            values = exp((cost - memory.potentials)*probGain);           
            probability{ID} = values/sum(values);
        end
        if(SOURCES(ID))
            antForward.msgID = -1;
            status = mcbr_smart_ant_layer(N, make_event(t+4000, 'Send_Packet', ID, antForward));
        else
            memory.interval = memory.interval*probGain;
        end
        Set_Start_Clock(t+memory.interval);
        pass =0;
    end
    if (strcmp(type, 'confirm_timeout')) %if confirm_transmit_layer is included
        rdata = data.data;
        address = rdata.address;
        nID = find(NEIGHBORS{ID}==address);
        %reduce probablity of that link at least
        probability{ID} = Set_New_Prob(probability{ID}, nID, -rewardScale/2);
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

function PrintMessage(msg)
global ID
prowler('TextMessage', ID, msg)

function DrawLine(command, varargin)
switch lower(command)
case 'line'
    prowler('DrawLine', varargin{:})
case 'arrow'
    prowler('DrawArrow', varargin{:})
case 'delete'
    prowler('DrawDelete', varargin{:})
otherwise
    error('Bad command for DrawLine.')
end

function b=Set_Start_Clock(alarm_time);
global ID
clock.type = 'ant_start';
prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));

function new = Set_New_Prob(old, idx, r)

if (sum(old)==0)
    old = ones(1,length(old))/length(old);
end

if (r>0)
	for i=1:length(old)
        if (i==idx)
            new(i) = old(i) + r*(1-old(i));
        else
            new(i) = old(i) - r*old(i);
        end
	end
else
    for i=1:length(old)
        if (i==idx)
            new(i) = old(i) + r*old(i);
        else
            new(i) = old(i) - r*(1-old(i));
        end
	end
end

%another function to try
function new = Set_New_Prob1(old, idx, r)

if (sum(old)==0)
    old = ones(1,length(old))/length(old);
end

if (r>0)
	for i=1:length(old)
        if (i==idx)
            new(i) = (old(i) + r)/(1+r);
        else
            new(i) = old(i)/(1+r);
        end
	end
else
    for i=1:length(old)
        if (i==idx)
            new(i) = old(i)/(1-r);
        else
            new(i) = (old(i) - r)/(1-r);
        end
	end
end

