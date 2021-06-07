function varargout=simstats
% SIMSTATS Simulation statistics using the last simulation results
% [sys_stat, node_stat]=simstats

% ***	
% ***	 Copyright 2002, Vanderbilt University. All rights reserved.
% ***
% ***    This program is distributed in the hope that it will be useful,
% ***    but WITHOUT ANY WARRANTY; without even the implied warranty of
% ***    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% ***
% ***

% Written by Gyula Simon, gyula.simon@vanderbilt.edu
% Last modified: Sep 24, 2002  by GYS

global global_event_Q
   
[topology, mote_IDs, void]=prowler('GetTopologyInfo');
N=length(mote_IDs);

for i=1:N
    node_stat(i)=struct(...
        'Sent_Messages',              0,  ...
        'Received_Messages',          0,  ...
        'Received_Collided_Messages', 0,  ...
        'Send_Times',                 [], ...
        'Receive_Times',              [], ...
        'Collide_Times',              []); 
end

L=length(global_event_Q);

for i=1:L
    t=global_event_Q(i).time;
    e=global_event_Q(i).event;
    id=global_event_Q(i).ID;
    
    ix=find(mote_IDs==id);
    switch e
    case 'Packet_Transmit_Start'
        node_stat(ix).Sent_Messages=node_stat(ix).Sent_Messages+1;
        node_stat(ix).Send_Times=[node_stat(ix).Send_Times, t];
        
    case 'Packet_Received'
        node_stat(ix).Received_Messages=node_stat(ix).Received_Messages+1;
        node_stat(ix).Receive_Times=[node_stat(ix).Receive_Times, t];
    case 'Collided_Packet_Received'
        node_stat(ix).Received_Collided_Messages=node_stat(ix).Received_Collided_Messages+1;
        node_stat(ix).Collide_Times=[node_stat(ix).Collide_Times, t];
    otherwise
        % not handled; can be extended
    end
end

sys_stat=struct(...
        'Sent_Messages',              0,   ...
        'Received_Messages',          0,   ...
        'Received_Collided_Messages', 0,   ...
        'First_Send_Time',            inf, ...
        'First_Receive_Time',         inf, ...
        'Last_Sent_Time',            -inf, ...
        'Last_Receive_Time',         -inf, ...
        'Sending_Nodes',              0,   ...
        'Receiving_Nodes',            0);
    
for i=1:N
    sys_stat.Sent_Messages              = ...
        sys_stat.Sent_Messages              + node_stat(i).Sent_Messages;
    sys_stat.Received_Messages          = ...
        sys_stat.Received_Messages          + node_stat(i).Received_Messages;
    sys_stat.Received_Collided_Messages = ...
        sys_stat.Received_Collided_Messages + node_stat(i).Received_Collided_Messages;
    
    sys_stat.First_Send_Time = ...
        min([sys_stat.First_Send_Time,     node_stat(i).Send_Times]);
    sys_stat.First_Receive_Time = ...
        min([sys_stat.First_Receive_Time,  node_stat(i).Receive_Times]);
        
    sys_stat.Last_Sent_Time = ...
        max([sys_stat.Last_Sent_Time,      node_stat(i).Send_Times]);
    sys_stat.Last_Receive_Time = ...
        max([sys_stat.Last_Receive_Time,   node_stat(i).Receive_Times]);
    
    sys_stat.Sending_Nodes = ...
        sys_stat.Sending_Nodes   + (node_stat(i).Sent_Messages     > 0);
    sys_stat.Receiving_Nodes = ...
        sys_stat.Receiving_Nodes + (node_stat(i).Received_Messages > 0);
end

if nargout==0
    disp(sys_stat)
else
    varargout={sys_stat, node_stat};
end