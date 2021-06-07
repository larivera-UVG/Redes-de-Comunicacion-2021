function status = mac_layer(N, S)

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

persistent promiscuous;
persistent initPower;
persistent randPower;

used = 0;

switch event
case 'Init_Application'
    if (ix==1)
        initPower = sim_params('get_app', 'InitPower'); 
        if (isempty(initPower)) initPower = 1000; end
        randPower = sim_params('get_app', 'RandPower');
        if (isempty(randPower)) randPower = 0; end    
        promiscuous = sim_params('get_app', 'Promiscuous');
        if (isempty(promiscuous)) promiscuous = 0; end
    end
    
    if (length(initPower)==1)
        ATTRIBUTES{ID}.power = initPower*(1+randPower*2*(rand-0.5));
    else ATTRIBUTES{ID}.power = initPower(ID);
    end
    ATTRIBUTES{ID}.usedPower = 0;
    ATTRIBUTES{ID}.sleep = 0; %not in sleep mode
    memory.isSending = 0;
    memory.eventTime = t;
    
case 'Send_Packet'   
    if (ATTRIBUTES{ID}.sleep || (ATTRIBUTES{ID}.power<=0) || memory.isSending)       
        pass = 0; status = 0;
    else
        memory.isSending = 1;
    end
case 'Packet_Sent'
    memory.isSending = 0;
    used = energyModel('sent', data, t-memory.eventTime);
    memory.eventTime = t;
case 'Packet_Received'
    if (ATTRIBUTES{ID}.sleep || (ATTRIBUTES{ID}.power<=0))       
        pass = 0; status = 0;
    else
        data.data.forward = 1;
        try address = data.data.address; catch address = 0; end
        try from = data.data.from; catch from = 0; end
        try width = data.data.width; catch width = 0; end
        if ((from ~= 0) && (address == ID))
            if (width)
                DrawLine('Arrow', from, ID, 'color', [1 1 0], 'LineWidth', width);
            else
                DrawLine('Arrow', from, ID, 'color', [1 1 0]);
            end
        end
        %test connectivity
	%       if (from ~= 0)
	%           DrawLine('Arrow', from, ID, 'color', [1 0 0]);
	%       end
        if (~promiscuous)
			if ((address ~= ID) && (address ~= 0)) %filtered out
                pass = 0;
			end
        end
        used = energyModel('received', data, t-memory.eventTime);
        memory.eventTime = t;
    end
case 'Collided_Packet_Received'
    if (ATTRIBUTES{ID}.sleep || (ATTRIBUTES{ID}.power<=0))       
        pass = 0; status = 0;
    else
        used = energyModel('received', data, t-memory.eventTime);
        memory.eventTime = t;
    end
case 'Clock_Tick'
    try type = data.type; catch type = 'none'; end
    
    if (~ATTRIBUTES{ID}.sleep)
        used = energyModel('idle', data, t-memory.eventTime);
    else
        used = energyModel('sleep', data, t-memory.eventTime);        
    end
    memory.eventTime = t;
    
    if (strcmpi(type, 'node_sleep')) % a sleep signal
      pass = 0;
      if (~ATTRIBUTES{ID}.sleep)
          pass = 1;
          ATTRIBUTES{ID}.sleep = 1;
          LED('yellow on');
      end
    end
    if (strcmpi(type, 'node_wakeup')) % a wakeup signal
      pass = 0;
      if (ATTRIBUTES{ID}.sleep)
          pass = 1;
          ATTRIBUTES{ID}.sleep = 0;
          LED('yellow off');
      end
    end
end

ATTRIBUTES{ID}.power = ATTRIBUTES{ID}.power - used;
ATTRIBUTES{ID}.usedPower = ATTRIBUTES{ID}.usedPower + used;
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

function LED(msg)
global ID
prowler('LED', ID, msg)
