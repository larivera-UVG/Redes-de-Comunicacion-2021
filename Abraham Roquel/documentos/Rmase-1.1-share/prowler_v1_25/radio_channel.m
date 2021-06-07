function out=radio_channel(varargin)
% simulation of the radio layer and the propagation in air 
% RADIO_CHANNEL  Radio propagation and MAC-layer simulation
% Used by prowler

% ***	
% ***	 Copyright 2002, Vanderbilt University. All rights reserved.
% ***
% ***    This program is distributed in the hope that it will be useful,
% ***    but WITHOUT ANY WARRANTY; without even the implied warranty of
% ***    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% ***
% ***

% Written by Gyula Simon, gyula.simon@vanderbilt.edu
% Last modified: Oct 1, 2002  by GYS

% MAC-layer parameters: (% all in bit-time units)
min_wait_time    = sim_params('get', 'MAC_MIN_WAITING_TIME');
rand_wait_time   = sim_params('get', 'MAC_RAND_WAITING_TIME'); 

min_backoff_time = sim_params('get', 'MAC_MIN_BACKOFF_TIME');
rand_backoff_time= sim_params('get', 'MAC_RAND_BACKOFF_TIME');

packet_length    = sim_params('get', 'MAC_PACKET_LENGTH');

persistent radio_data topology mote_IDs radiotopology timestamp update_topology
%%%%%%%%%% radio_data:
%%%%%%%%%% struct array of .state            : {idle, transmit, receive, collision}
%%%%%%%%%%                 .data             : radiostream
%%%%%%%%%%                 .transmit_pending : boolean
%%%%%%%%%% 
%%%%%%%%%% topology, moteIDs                 : topological info
%%%%%%%%%% 
%%%%%%%%%% radiotopology, timestamp          : TX/RX topology based on topology, 
%%%%%%%%%%                                   :       updated when TX initiated
%%%%%%%%%% update_topology                   : topology info update needed flag

radio_ID=-1;
if ischar(varargin{1}) 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%                                       %%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%              COMMANDS                 %%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%                                       %%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    command=varargin{1};
    switch command
    case 'Send_Packet' 
        ID=varargin{2};
        data=varargin{3};
        t=varargin{4};
        ix=find(mote_IDs==ID);
        % check if previous packet already sent
        if radio_data(ix).transmit_pending;
            out=0;
        else
            out=1;
            prowler('InsertEvents2Q', make_event(t, 'Channel_Request', ID, data));
        end
    case 'Prowler!RefreshTopology'
        update_topology=1;
    case 'GetRadioVersion'
        out='radio_model_1';
    case 'PropagationPlot'
        PropagationPlot(varargin{2:end})
    otherwise
        error(['Bad command name for radio: ' command])
    end
    
else 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%                                       %%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%                EVENTS                 %%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%                                       %%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    event_struct=varargin{1};
    [t, event, ID, data]=get_event(event_struct);

    % update topology info if necessary
    if update_topology  % update request can come from user interrupt
        update_topology=0;
        [topology, radiotopology, timestamp]=update_local_data(topology, radiotopology, timestamp);    
    end

    switch event
    case 'Init_Radio'
        radio_data=[]; 
        [topology, mote_IDs, timestamp]=prowler('GetTopologyInfo');
        radiotopology=radio_topology(topology, [], []); 
        for mote_id=mote_IDs
            radio_data=[radio_data, struct('ID', mote_id, 'state', 'idle', 'transmit_pending', 0)];
        end
    case 'Channel_Request'
        ix=find(mote_IDs==ID);
        wait_time = gen_rand_wait(min_wait_time, rand_wait_time);
        prowler('InsertEvents2Q', make_event(wait_time+t, 'Channel_Idle_Check', ID, data));
        radio_data(ix).transmit_pending=1;
    case 'Channel_Idle_Check'
        [new_topology, mote_IDs, newtimestamp]=prowler('GetTopologyInfo');
        %[newtimestamp, timestamp]
        if newtimestamp>timestamp
            radiotopology=radio_topology(new_topology, topology, radiotopology);
            topology=new_topology;
            timestamp=newtimestamp;
        end

        is_idle=1;
        ix=find(mote_IDs==ID);
        if strcmp(radio_data(ix).state, 'receive')|strcmp(radio_data(ix).state, 'transmit')
            % receiving message, channel busy 
            % NOTE: in MAC-layer presently it merely checks channel idle state, may provide idle :-(
            is_idle=0;
        else
            % check if channel is sensed idle
            is_idle=idle_check(ix, radiotopology, radio_data);
        end
        if is_idle
            prowler('InsertEvents2Q', make_event(t, 'Packet_Transmit_Start', ID, data));
            [receiver_ix, streng]=who_can_hear_me(ix, radiotopology, data);
            % distribute message to these motes:
            for rec_ix=receiver_ix(:)'
                if rec_ix~=ix
                    data.signal_strength=streng(rec_ix);
                    prowler('InsertEvents2Q', make_event(t+1, 'Packet_Receive_Start', mote_IDs(rec_ix), data));
                end
            end
        else
            backoff_time = gen_rand_wait(min_backoff_time, rand_backoff_time);
            if backoff_time
                prowler('InsertEvents2Q', make_event(backoff_time+t, 'Channel_Idle_Check', ID, data));
            else
                % drop this message
                radio_data(ix).state='idle';
                radio_data(ix).data=[];
                radio_data(ix).transmit_pending=0;
            end
        end
    
    case 'Packet_Receive_Start'
        ix=find(mote_IDs==ID);
        if strcmp(radio_data(ix).state, 'idle')
            radio_data(ix).state='receive';
            prowler('InsertEvents2Q', make_event(packet_length+t, 'Packet_Receive_End', ID, data));
        elseif strcmp(radio_data(ix).state, 'receive')
            radio_data(ix).state='collision';
        end
            
    case 'Packet_Receive_End'  % now 'check CRC'
        ix=find(mote_IDs==ID);
        if strcmp(radio_data(ix).state, 'receive')
            % model transmission errors:
            TR_ERROR_PROB=sim_params('get', 'TR_ERROR_PROB');
            if rand>TR_ERROR_PROB; TR_succes=1; else TR_succes=0; end
            if TR_succes
                % succesful reception; notify application
                prowler('InsertEvents2Q', make_event(t, 'Packet_Received', ID, data));
            else
                % transmission error
                prowler('InsertEvents2Q', make_event(t, 'Collided_Packet_Received', ID, data));
           end
        elseif strcmp(radio_data(ix).state, 'collision') 
            prowler('InsertEvents2Q', make_event(t, 'Collided_Packet_Received', ID, data));
        end
        radio_data(ix).state='idle';
        radio_data(ix).data=[];
   
    case 'Packet_Transmit_Start'
        ix=find(mote_IDs==ID);
        radio_data(ix).state='transmit';
        radio_data(ix).data=data;
        prowler('InsertEvents2Q', make_event(packet_length+t, 'Packet_Transmit_End', ID, data));
        
    case 'Packet_Transmit_End'
        ix=find(mote_IDs==ID);
        radio_data(ix).state='idle';
        radio_data(ix).data=[];
        radio_data(ix).transmit_pending=0;
        prowler('InsertEvents2Q', make_event(t, 'Packet_Sent', ID, data));
    otherwise
        error(['Bad event name for radio: ' event])
    end
end





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function y=gen_rand_wait(min, var);
y=floor(min+var*rand);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function is_idle=idle_check(mote_ix, radiotopology, radio_data);
is_idle=1;
for i=1:length(radio_data);
    if i==mote_ix; continue, end
    if strcmp(radio_data(i).state, 'transmit')
        strength=radio_data(i).data.signal_strength;
        y=received_signal_strength(radiotopology(i,mote_ix),strength);
        if any(can_be_heard(y))
            is_idle=0; return
        end
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ixs, streng]=who_can_hear_me(mote_ix, radiotopology, data);
strength=data.signal_strength;
d=radiotopology(mote_ix,:);
y=received_signal_strength(d, strength);
ixs=find(can_be_heard(y));
streng=y;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function b=can_be_heard(strength);
% primitive model: can be heard if received signal strength is >= LIMIT
LIMIT=sim_params('get', 'RECEPTION_LIMIT');
b=(strength>=LIMIT);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function d=distance(p1, p2)
x_d=p1(:,1)-p2(:,1);
y_d=p1(:,2)-p2(:,2);
TOROID=0; % test only 
if TOROID
    MX=10; MY=10;
    ix = find(abs(x_d)>MX/2); x_d(ix) =MX-abs(x_d(ix));
    iy = find(abs(y_d)>MY/2); y_d(iy) =MY-abs(y_d(iy));
end
d=sqrt(x_d.^2+y_d.^2);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function y=received_signal_strength(fx_value, transmit_signal_strength)

% randomize
RADIO_VAR_RAND=sim_params('get', 'RADIO_SS_VAR_RAND');
r_vect=1+RADIO_VAR_RAND*randn(size(fx_value));
r_vect(r_vect<0)=r_vect(r_vect<0)*0;

y=transmit_signal_strength.*fx_value.*r_vect;  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function new_radiotopology=radio_topology(new_topology, old_topology, old_radiotopology);
N=size(new_topology,1);
if ~all(size(old_topology)==size(new_topology))  % change of topology size or init
    old_radiotopology=zeros(N,N);
    old_topology=new_topology+1;                 % so old is different from the new
    new_radiotopology=zeros(N,N);
else
    new_radiotopology=old_radiotopology;
end
RADIO_VAR_CONST=sim_params('get', 'RADIO_SS_VAR_CONST');
for i=1:N
    if ~all(old_topology(i,:)==new_topology(i,:))  % update radio topology info
        pos=new_topology(i,:); d=distance(pos, new_topology);
        
        % Calculate fx
        fn=sim_params('get', 'SIGNAL_FCN');
        x=d; fx_values=eval(fn);

        % update row
        r_vect=1+RADIO_VAR_CONST*randn(size(d'));
        r_vect(r_vect<0)=r_vect(r_vect<0)*0;
        %r_vect(r_vect>1)=r_vect(r_vect>1)*0+1;  % prevent increase of signal strength
        new_radiotopology(i,:)=fx_values'.*r_vect;  
        % update column
        r_vect=1+RADIO_VAR_CONST*randn(size(d));
        r_vect(r_vect<0)=r_vect(r_vect<0)*0;
        %r_vect(r_vect>1)=r_vect(r_vect>1)*0+1; % prevent increase of signal strength
        new_radiotopology(:,i)=fx_values.*r_vect;  
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function updates the radio simulator's internal data structure to represent changes in the topology 
% or the transmission state of any of the motes
function [topology, radiotopology, timestamp]=update_local_data(topology, radiotopology, timestamp)
[new_topology, mote_IDs, newtimestamp]=prowler('GetTopologyInfo');
if newtimestamp>timestamp % physical topology changed 
    [radiotopology]=radio_topology(new_topology, topology, radiotopology);
    topology=new_topology;
    timestamp=newtimestamp;
end


function PropagationPlot(h,x)
% the axis is set to hold before calling this fcn
% the ideal propagation fcn is already plotted in green
topology_ex=[x(:), ones(length(x),1)];

param_save=sim_params('get'); % temporarily store parameters
tmp_pars=prowparams('getparams_from_gui'); % get GUI params
sim_params('set_from_gui',tmp_pars); % set parameters temporarily from GUI
radiotopology_ex=radio_topology(topology_ex, [], []); % calculate radiotopology with the parameters in GUI
s_beta=sim_params('get', 'RADIO_SS_VAR_RAND');
limit=sim_params('get', 'RECEPTION_LIMIT');
sim_params('set_from_gui',param_save); % restore parameters
y=radiotopology_ex(1,:);
y2=y.*(1+s_beta*randn(size(y)));
y3=limit*ones(size(x));
plot(x, y, 'b', x, y2, 'r', x, y3, 'y', 'parent', h)
legend(h, 'P_{rec\_id}', 'P_{rec} (s_\beta=0)', 'P_{rec}', 'limit')