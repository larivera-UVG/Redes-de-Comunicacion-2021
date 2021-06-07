function status = mcbr_flood_layer(N, S)

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
global NEIGHBORS

persistent NQValues
persistent alpha

persistent temperature
% persistent delay_scale
persistent max_delay
persistent k

switch event
case 'Init_Application'
    ATTRIBUTES{ID}.QValue = 0;
    NQValues{ID} = [];
    if (ix==1)
        alpha = sim_params('get_app', 'LearningRate');
        if (isempty(alpha)) alpha = 1; end
        %temperature for passing the data, can be set with the data, the higher,
        %the more chance
        temperature = sim_params('get_app', 'FloodTemp');
        if (isempty(temperature)) temperature = 0; end
        
        max_delay = sim_params('get_app', 'MaxDelay');
        if (isempty(max_delay)) max_delay = 4000; end %used to set maximum delay time
%         delay_scale = sim_params('get_app', 'DelayScale');
%         if (isempty(delay_scale)) delay_scale = 1000; end %used to calulate transmit delay
        loginit('log/mcbr.log');
        k = temperature;
    end
    ATTRIBUTES{ID}.temp = temperature;
    Set_Init_Clock(1000);
    
case 'Send_Packet'
    
    try msgID = data.msgID; catch msgID = 0; end
    if (msgID>=0) 
    
        %try myT = data.temperature; catch myT=ATTRIBUTES{ID}.temp; end
        try forward = data.forward; catch forward = 0; end
        
        if (forward)
            %delta=data.QValue-ATTRIBUTES{ID}.QValue+myT;
            %data.delayTime = max_delay-delta*delay_scale;
                        
            delta=data.QValue-ATTRIBUTES{ID}.QValue;
            data.delayTime = max_delay/exp(delta);
            if (data.delayTime<1) data.delayTime=1; end
            logevent(['delay:',num2str(data.delayTime)]);
            logevent(['off:',num2str(delta)]);
        else 
            maxhops = sim_params('get_app', 'MaxHops');
            if (~isempty(maxhops))
                data.maxhops = maxhops;
            end
        end
    
    end
    data.QValue = ATTRIBUTES{ID}.QValue;
    
case 'Packet_Received'
    try duplicated = data.duplicated; catch duplicated = 0; end
    try msgID = data.data.msgID; catch msgID = 0; end
    data.data.forward = 1;
    
    if (DESTINATIONS(ID))
        ATTRIBUTES{ID}.QValue = 0;
        if ((msgID >= 0)&&(~duplicated))  %real data, broadcast
            PrintMessage('b');
            bdata.QValue = 0;
            bdata.temperature = 0; %control propagation
            status = common_layer(N, make_event(t, 'Send_Packet', ID, bdata));
        end
    else
      
      nID = find(NEIGHBORS{ID}==data.data.from);
      if (~isempty(nID))
            NQValues{ID}(nID) = data.data.QValue;
            ATTRIBUTES{ID}.QValue = (1-alpha)*ATTRIBUTES{ID}.QValue+alpha*(min(NQValues{ID})+mcbr_cost);
            
                %calculate alpha
      end
      try T=data.data.temperature; catch T = ATTRIBUTES{ID}.temp; end
      
      delta = ATTRIBUTES{ID}.QValue - data.data.QValue;
      logevent(['delta:',num2str(delta)]);
      if (~duplicated &&  (msgID >= 0))
           if (T-delta>0) %(rand < exp(5*(T-delta))) %
               PrintMessage('f');
               logevent(['temp:',num2str(T)]);
               status = mcbr_flood_layer(N, make_event(t, 'Send_Packet', ID, data.data)); 
           end
      end
    end
    
    %adjust delay scale
    if (msgID>=0)
        
        %ATTRIBUTES{ID}.temp = (k*ATTRIBUTES{ID}.temp-1)/(k+1);
	
	    ATTRIBUTES{ID}.temp = k*ATTRIBUTES{ID}.temp/(k+1);
        
    end
        
    if (duplicated || (~DESTINATIONS(ID) & (msgID >=0)))
        pass = 0;
    end
    
case 'Clock_Tick'
    try type = data.type; catch type = 'none'; end
    
    if (strcmp(type, 'flood_init'))
        ATTRIBUTES{ID}.QValue = mcbr_dest;
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

function b=Set_Init_Clock(alarm_time);
global ID
clock.type = 'flood_init';
prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));
