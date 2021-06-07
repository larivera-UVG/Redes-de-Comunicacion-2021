function status = converge_tree_layer(N, S)

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
% Last modified: Jun 17, 2004  by YZ

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

persistent K
persistent resend

switch event
case 'Init_Application'
    
 
    if (ix == 1) 
        K = sim_params('get_app', 'DelayScale');
        if (isempty(K)) K = 1000; end %used to calulate transmit delay
        sim_params('set_app', 'Promiscuous', 1);
        resend = sim_params('get_app', 'ReSend');
        if (isempty(resend)) resend = 0; end
    end
    
    ATTRIBUTES{ID}.hopcount = inf;
    %%%%%%%%%%%%%%   Memory should be initialized here  %%%%%%%%%%%%%%%%%
    memory=struct('parent', -inf, 'cost', inf, 'nhops', []);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
case 'Send_Packet'
    
    if (DESTINATIONS(ID)) ATTRIBUTES{ID}.hopcount = 0; end
    data.hopcount = ATTRIBUTES{ID}.hopcount;
    try msgID = data.msgID; catch msgID = 0; end
    if (msgID<0) data.address = 0;
    else 
        pass = 0;
        if (memory.parent >= 0)
           ns = length(NEIGHBORS{ID});
           delayTime = K*((1+ATTRIBUTES{ID}.hopcount)/2-1+rand)*ATTRIBUTES{ID}.hopcount*ns;
           data.address = memory.parent;
           common_layer(N, make_event(t+delayTime, 'Send_Packet', ID, data));
        end       
    end
    
case 'Packet_Received'
    try duplicated = data.duplicated; catch duplicated = 0; end
    try msgID = data.data.msgID; catch msgID = 0; end
    data.data.forward = 1;
    if (resend>0) data.data.resend = resend; end
    if (DESTINATIONS(ID))
        memory.parent = 0;
        memory.cost = 0;
        ATTRIBUTES{ID}.hopcount = 0;
        if (msgID >= 0) %real data received, confirm to neighbors
            PrintMessage('b');
            status = converge_tree_layer(N, make_event(t, 'Send_Packet', ID, data.data));
        end  
    else
      nID = find(NEIGHBORS{ID}==data.data.from);
      if (~isempty(nID))
          memory.nhops(nID) = data.data.hopcount;
          if (msgID<0) %tree build
              
              ATTRIBUTES{ID}.hopcount = min(ATTRIBUTES{ID}.hopcount, data.data.hopcount+1);
              if (memory.cost > ATTRIBUTES{ID}.hopcount) %change parent
                  if (memory.parent > 0)
                      DrawLine('delete', memory.parent, ID);
                  end
                  memory.parent = data.data.from;
                  DrawLine('Arrow', memory.parent, ID, 'color', [1 0 0]);
                  memory.cost = ATTRIBUTES{ID}.hopcount;
              end
          end
      end
      if ((msgID >= 0) && (data.data.address==ID)) %real data address to me
                PrintMessage('f');
                status = converge_tree_layer(N, make_event(t, 'Send_Packet', ID, data.data));
       end
             
    end
        
    if (duplicated)
        pass = 0;
    end
    
case 'Clock_Tick'
  try type = data.type; catch type = 'none'; end
  
  if (strcmp(type, 'confirm_timeout')) 
        rdata = data.data;
        address = rdata.address;
        
        nID = find(NEIGHBORS{ID}==address);       
             
        memory.nhops(nID) = inf;
        
        memory.cost = min(memory.nhops);
        id = find(memory.nhops==memory.cost);
        if (memory.parent>0)
            DrawLine('delete', memory.parent, ID);
        end
        memory.parent = NEIGHBORS{ID}(id(1));
        DrawLine('Arrow', memory.parent, ID, 'color', [1 0 0]);
        
        ATTRIBUTES{ID}.hopcount = 1 + memory.cost;
        try 
            if (data.data.resend>0)
                data.data.forward = 1;
                data.data.resend = data.data.resend - 1;
                data.data.address = memory.parent;
                if (memory.parent > 0)
                    common_layer(N, make_event(t, 'Send_Packet', ID, data.data));
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

function PrintMessage(msg)
global ID
prowler('TextMessage', ID, msg)

function b=Set_Root_Clock(alarm_time);
global ID
clock.type = 'tree_root';
prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));

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