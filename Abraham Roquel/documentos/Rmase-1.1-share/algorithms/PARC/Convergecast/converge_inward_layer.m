function status = converge_inward_layer(N, S)

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

persistent K dim

switch event
case 'Init_Application'
    ATTRIBUTES{ID}.hopcount = inf;
 
    if (ix==1)
        K = sim_params('get_app', 'DelayScale');
        if (isempty(K)) K = 1000; end %used to calulate transmit delay
        K = K/7; %inward has small delay constants comparing to outward for the same success rate
        dim=sim_params('get_app', 'Dimension');
        if (isempty(dim)) dim = 2; end
    end  
    
case 'Send_Packet'
    
    if (DESTINATIONS(ID)) ATTRIBUTES{ID}.hopcount = 0; end
    data.hopcount = ATTRIBUTES{ID}.hopcount;
    try msgID = data.msgID; catch msgID = 0; end
    if (msgID>=0) 
%         try forward = data.forward; catch forward = 0; end
%         
%         if (~forward) %add  delay to sending
            ns = length(NEIGHBORS{ID});
            %data.delayTime = K*((1+ATTRIBUTES{ID}.hopcount)/2-1+rand)*ATTRIBUTES{ID}.hopcount*ns;
            %data.delayTime = K*((1+ATTRIBUTES{ID}.hopcount)/2-1+rand/4)*ATTRIBUTES{ID}.hopcount*ns;
            h=ATTRIBUTES{ID}.hopcount;
            H = maxhops; %assume the system knows the maximum hops
            if (dim==2)
                data.delayTime = K*((H+h+1)*(H-h)*ns/2 + h*ns*rand);
            elseif (dim==1)
                %data.delayTime = K*((H+h+1)*(H-h)/2+rand);
                data.delayTime = K*(H-h);
            end
%         else
%             data.delayTime = 0;
%         end
           
    end
    
    %adjust delay scale
case 'Packet_Received'
    try duplicated = data.duplicated; catch duplicated = 0; end
    try msgID = data.data.msgID; catch msgID = 0; end
    data.data.forward = 1;
    
    if (DESTINATIONS(ID))
        ATTRIBUTES{ID}.hopcount = 0;
%         if (msgID >= 0)  %real data, broadcast
%             PrintMessage('b');
%             bdata.hopcount = 0;
%             status = common_layer(N, make_event(t, 'Send_Packet', ID, bdata));
%         end
    else
      if (msgID<0)
          ATTRIBUTES{ID}.hopcount = min(ATTRIBUTES{ID}.hopcount, data.data.hopcount+1);
      end
      if (~duplicated && ((ATTRIBUTES{ID}.hopcount <= data.data.hopcount) && (msgID >= 0)||...
              ((ATTRIBUTES{ID}.hopcount >= data.data.hopcount) && (msgID < 0))))
           %move towards destination or away from destination
           PrintMessage('f');
           status = converge_inward_layer(N, make_event(t, 'Send_Packet', ID, data.data)); 
      end
    end
        
    if (duplicated)
        pass = 0;
    end
    
case 'Clock_Tick'
    
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

function H = maxhops
global ATTRIBUTES
hops = [];
for i=1:length(ATTRIBUTES)
    if (~isempty(ATTRIBUTES{i}))
        hops = [hops, ATTRIBUTES{i}.hopcount];
    end
end
H = max(hops);

