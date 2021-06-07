function status = duty_cycle_layer(N, S)

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
% Last modified: Nov. 22, 2004  by YZ

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

persistent Ta
persistent Ts
persistent initCycles

switch event
case 'Init_Application'
    if (ix==1)
        bittime = sim_params('get', 'BIT_TIME');
        
        cycleTime = sim_params('get_app', 'CycleTime'); 
        if (isempty(cycleTime)) cycleTime = 10; end %ten second
        cycleTime = cycleTime/bittime;
        
        activePeriod = sim_params('get_app', 'ActivePeriod');
        if (isempty(activePeriod)) activePeriod = 0.1; end  % 10% time active
        Ta = cycleTime*activePeriod;
        Ts = cycleTime*(1-activePeriod);
        
        initCycles = sim_params('get_app', 'InitActiveCycles');
        if (isempty(initCycles)) initCycles = 3; end
        
    end
        
    memory.initCycles = initCycles;
    memory.isActive = 1; %initially all nodes are active
    memory.queue = {};
    
    Set_Active_Clock(t);
    
case 'Send_Packet'   
    if (isempty(memory.queue)&&~ATTRIBUTES{ID}.sleep) sendnow=1; else sendnow = 0; end
    %enqueue all packets
    memory = Insert2Q(memory, data);
    if (~sendnow) pass = 0; end
case 'Packet_Sent' 
    %dequeue after packet sent
    Q = memory.queue;
    memory.queue = Q(2:length(Q));
    if (length(memory.queue)>0 && ~ATTRIBUTES{ID}.sleep) status = SendFromQ(N, memory); end
    
case 'Packet_Received'
        
case 'Clock_Tick'
    try type = data.type; catch type = 'none'; end
    
    if (strcmpi(type, 'cycle_active')) % set radio active
      Set_DeActive_Clock(t+Ta); %deactive after Ta
      Set_Node_Wakeup(t);
    end
    
    if (strcmpi(type, 'cycle_deactive')) % time to sleep if no activity
      Set_Active_Clock(t+Ts);
      if (~memory.initCycles && ~memory.isActive) %turn off radio
          Set_Node_Sleep(t);
      end
      if (memory.initCycles) memory.initCycles = memory.initCycles - 1; end
    end
    
    if (strcmpi(type, 'active')) % set radio active
      memory.isActive = 1;
    end
    
    if (strcmpi(type, 'deactive')) % set radio active
      memory.isActive = 0;
    end
    
    if (strcmpi(type, 'node_wakeup')) % a wakeup signal     
      if (length(memory.queue)>0) status = SendFromQ(N, memory); end
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

function b=Set_Active_Clock(alarm_time);
global ID
clock.type = 'cycle_active';
prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));

function b=Set_DeActive_Clock(alarm_time);
global ID
clock.type = 'cycle_deactive';
prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));

function b=Set_Node_Sleep(alarm_time);
global ID
clock.type = 'node_sleep';
prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));

function b=Set_Node_Wakeup(alarm_time);
global ID
clock.type = 'node_wakeup';
prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));

function out = Insert2Q(memory, data)
global ID
Q=memory.queue;
Q{length(Q)+1} = data;
memory.queue = Q;
out = memory;

function out = SendFromQ(N, memory)
global ID t
Q=memory.queue;
data = Q{1};
out = common_layer(N, make_event(t, 'Send_Packet', ID, data));


