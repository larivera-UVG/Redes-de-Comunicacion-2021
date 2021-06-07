function out=radio_channel(varargin)
% simulation of the radio layer and the propagation in air 
% RADIO_CHANNEL  Radio propagation and MAC-layer simulation
% Used by prowler

%
% Heavily modified by Octav Chipara to support PRR and ARQ
%

% Modified by YZ yzhang@parc.com

% MAC-layer parameters: (% all in bit-time units)
min_wait_time    = sim_params('get', 'MAC_MIN_WAITING_TIME');
rand_wait_time   = sim_params('get', 'MAC_RAND_WAITING_TIME'); 

min_backoff_time = sim_params('get', 'MAC_MIN_BACKOFF_TIME');
rand_backoff_time= sim_params('get', 'MAC_RAND_BACKOFF_TIME');

%let's set the length from the packet -- Guoliang
%packet_length    = sim_params('get', 'MAC_PACKET_LENGTH');
default_pkt_length    = sim_params('get', 'MAC_PACKET_LENGTH');

%original persistent, moved to global for easily obtaining statistics in
%routing, not recommend to use them though
global radiotopology
global radio_data

persistent topology mote_IDs  timestamp update_topology

%radio power for this model
power_instances = sim_params('get_radio', 'POWER_RNG_INSTANCES') ;  
prr_threshold = sim_params('get_radio', 'MAC_PRR_THRESHOLD');

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

% radiotopology has on ox (rows) the senders and oy (columns) the
% receivers. 
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
            %logevent(ID,t,'pending',data.data,'MAC');
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
            is_idle=idle_check(ix, radiotopology, radio_data, power_instances, prr_threshold);
        end
        if is_idle
            %logevent(ID,t,'Is_Idle',data.data,'MAC');
            prowler('InsertEvents2Q', make_event(t, 'Packet_Transmit_Start', ID, data));
            [receiver_ix]=who_can_hear_me(ix, radiotopology, data, power_instances, prr_threshold);
            
            % distribute message to these motes:
            for rec_ix=receiver_ix(:)'
               if rec_ix~=ix
                    %data.signal_strength=streng(rec_ix);
                    %received strength is not available for this model
                    
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
            %extended for arbitrary length packets
            try packet_length = data.length; catch packet_length = default_pkt_length; end
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
        %extended for arbitrary length packets
        try packet_length = data.length; catch packet_length = default_pkt_length; end
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

%special for this model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function is_idle=idle_check(mote_ix, radiotopology, radio_data, power_instances, prr_threshold);
is_idle=1;
for i=1:length(radio_data);
    if i==mote_ix; continue, end
    % one neighbor may be transmitting
    % that neighbor would be the source of the message
    % i'm not idle if its prr is higher than the threshold
    if strcmp(radio_data(i).state, 'transmit')
        strength=radio_data(i).data.signal_strength;
        index = 1 + round(rand*(power_instances-1));
        if (radiotopology(i, mote_ix, strength, index) >= prr_threshold) 
            is_idle=0; return
        end
    end
end

%special for this model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ixs]=who_can_hear_me(mote_ix, radiotopology, data, power_instances, prr_threshold);
% anybody with a prr > threshold can hear me
% the sender is on oxv
index = 1 + round(rand*(power_instances-1));
ixs = find(radiotopology(mote_ix,:,data.signal_strength, index) >= prr_threshold);


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

%not used for this model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function y=received_signal_strength(fx_value, transmit_signal_strength)
% 
% % randomize
% RADIO_VAR_RAND=sim_params('get', 'RADIO_SS_VAR_RAND');
% r_vect=1+RADIO_VAR_RAND*randn(size(fx_value));
% r_vect(r_vect<0)=r_vect(r_vect<0)*0;
% 
% y=transmit_signal_strength.*fx_value.*r_vect;  

%special for this model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function new_radiotopology=radio_topology(new_topology, old_topology, old_radiotopology);
% 
%  The radio topology has the following format:
%  <src, dst , Pt, instance> -- the prr of transmitting from src to
%  destination at power level pt. Here we have multiple instances because
%  it allows us to precompute the entire table so we would have pretty good
%  performance
%
powers = sim_params('get_radio', 'POWER_RNG'); %transmission power in db 
power_instances = sim_params('get_radio', 'POWER_RNG_INSTANCES') ;   %how many different reception probabilities for each power level we have

%total number of nodes
N=size(new_topology,1);
%number of power levels
P=length(powers);
if ~all(size(old_topology)==size(new_topology))  % change of topology size or init
    old_radiotopology=zeros(N,N,P,power_instances);
    old_topology=new_topology+1;                 % so old is different from the new
    new_radiotopology=zeros(N,N,P,power_instances);
else
    new_radiotopology=old_radiotopology;
end

for x=1:N
    % compare row wise
    if ~all(old_topology(x,:)==new_topology(x,:))  % update radio topology info
        %get the positon of the rows
        pos=new_topology(x,:); 
        %compute the distance vector
        d=distance(pos, new_topology);
        for y=1:N
            for z=1:power_instances
                if (d(y) == 0) 
                    prr_val=ones(1, P);
                else 
                    prr_val = prr_fast(d(y), 'Pout', powers, 'mod', 3, 'enc', 1, 'frame', 50);
                end
                new_radiotopology(x,y,:,z) = prr_val;
            end
        end
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
powers = sim_params('get_radio', 'POWER_RNG'); %transmission power in db -10:1:20
prr_threshold = sim_params('get_radio', 'MAC_PRR_THRESHOLD');

% the axis is set to hold before calling this fcn
% the ideal propagation fcn is already plotted in green
topology_ex=[x(:), ones(length(x),1)];

param_save=sim_params('get'); % temporarily store parameters
tmp_pars=prowparams('getparams_from_gui'); % get GUI params
sim_params('set_from_gui',tmp_pars); % set parameters temporarily from GUI
radiotopology_ex=radio_topology(topology_ex, [], []); % calculate radiotopology with the parameters in GUI

sim_params('set_from_gui',param_save); % restore parameters

y = radiotopology_ex(1, :, 1, 1);
y2 = radiotopology_ex(1, :, length(powers), 1);
y3 = prr_threshold*ones(size(x));
plot(x, y, 'b', x, y2, 'r', x, y3, 'y', 'parent', h);
legend(h, 'P_{rec\_id}', 'min power', 'max power', 'prr threshold');
