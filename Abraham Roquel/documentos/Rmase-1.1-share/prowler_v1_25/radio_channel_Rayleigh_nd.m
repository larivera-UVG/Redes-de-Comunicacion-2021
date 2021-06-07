function out=radio_channel_Rayleigh_nd(varargin)
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

% This version incorporates Martin Haenggi's (Univ. Notre Dame) propagation
% model with Rayleigh fading simulation

% Written by Gyula Simon, gyula.simon@vanderbilt.edu
% Last modified: Dec 5, 2003  by GYS


% NOTES ON GENERATING NEW RADIO CHANNEL DESCRIPTION FILES
% this file can be used as a template
% new UICs can be added to paramgui
% the radio specific UICs' decriptions must be modified in paramgui


% MAC-layer parameters: (% all in bit-time units)
min_wait_time    = sim_params('get', 'MAC_MIN_WAITING_TIME');
rand_wait_time   = sim_params('get', 'MAC_RAND_WAITING_TIME'); 

min_backoff_time = sim_params('get', 'MAC_MIN_BACKOFF_TIME');
rand_backoff_time= sim_params('get', 'MAC_RAND_BACKOFF_TIME');

packet_length    = sim_params('get', 'MAC_PACKET_LENGTH');

persistent radio_data topology mote_IDs radiotopology timestamp update_topology
persistent transmit_power total_rec_power receive_power receive_ID  last_fading_update
%%%%%%%%%% radio_data:
%%%%%%%%%% struct array of .state            : {idle, transmit, receive, collision}
%%%%%%%%%%                 .data             : radiostream
%%%%%%%%%%                 .transmit_pending : boolean
%%%%%%%%%% 
%%%%%%%%%% update_topology                   : topology info update needed flag
%%%%%%%%%% 
%%%%%%%%%% topology, moteIDs                 : topological info
%%%%%%%%%% 
%%%%%%%%%% radiotopology,                    : TX/RX topology (f(x) values) based on topology, 
%%%%%%%%%%      timestamp                    : with update timestamp   
%%%%%%%%%% transmit_power                    : current transmit power of each node (0 if not transmitting)
%%%%%%%%%% total_rec_power                   : current total (summed) received power for each node
%%%%%%%%%% receive_power                     : current received signal's power for each node (0 if not in reception mode)
%%%%%%%%%% receive_ID                        : current received signal's sender id for each node (NaN if not in reception mode)




radio_ID=-1;
if ischar(varargin{1}) 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%                                       %%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%              COMMANDS                 %%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%                                       %%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    command=varargin{1};
    switch command
    case 'test'
        GenerateHelp(1);
        
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
        out='radio_model_3';
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
    [t, event, ID, data, sID]=get_event(event_struct);

    % update topology info if necessary
    if update_topology  % update request can come from user interrupt
        update_topology=0;
        [topology, radiotopology, timestamp, total_rec_power]=update_local_data(...
            topology, radiotopology, timestamp, transmit_power, total_rec_power, 0);    
    end
    
    switch event
    case 'Init_Radio'
        [topology, mote_IDs, timestamp]=prowler('GetTopologyInfo');
        M=length(mote_IDs);
        transmit_power=zeros(1,M);
        total_rec_power=zeros(1,M);
        receive_power=zeros(1,M);
        radio_data=[]; 
        radiotopology=radio_topology(topology, [], [], transmit_power); 
        for mote_id=mote_IDs
            radio_data=[radio_data, struct(...
                    'ID', mote_id, 'state', 'idle', 'transmit_pending', 0, ...
                    'transmit_power', 0, 'receive_power', 0, 'total_rec_power', 0, 'receive_ID', NaN)];
        end
        last_fading_update = zeros(1, length(mote_IDs));
    case 'Channel_Request'
        ix=find(mote_IDs==ID);
        wait_time = gen_rand_wait(min_wait_time, rand_wait_time);
        prowler('InsertEvents2Q', make_event(wait_time+t, 'Channel_Idle_Check', ID, data));
        radio_data(ix).transmit_pending=1;
        
        % periodic fading update is performed here
        
        elapsed_time_in_sec=(t-last_fading_update(ix))/40000;
        if elapsed_time_in_sec >= sim_params('get', 'RADIO_RAYLEIGH_COH')
            last_fading_update(ix)=t;
            [new_radiotopology]=radio_topology(topology, radiotopology, ix); 
        end 
        
    case 'Channel_Idle_Check'
        is_idle=1;
        ix=find(mote_IDs==ID);
        if strcmp(radio_data(ix).state, 'receive')|strcmp(radio_data(ix).state, 'transmit')
            % receiving message, channel busy 
            % NOTE: in MAC-layer presently merely checks channel idle state, it may provide idle in this case :-(
            is_idle=0;
        else
            % check if channel is sensed idle
            IDLE_LIMIT=sim_params('get', 'IDLE_LIMIT');
            REC_NOISE_VAR=sim_params('get', 'REC_NOISE_VAR');
            is_idle=total_rec_power(ix)<IDLE_LIMIT*REC_NOISE_VAR;
        end
        if is_idle % can transmit
            prowler('InsertEvents2Q', make_event(t, 'Packet_Transmit_Start', ID, data));

            % Now decide which are the potential receivers
            % NOTE: The transmit_power value is not updated yet (all Channel_Idle_Check events are processed first)
            %       transmit_power will be updated when Packet_Transmit_Start event is processed
            
            total_rec_power=transmit_power*radiotopology; % update the receivers' total received power properties
            P_ij=data.signal_strength*radiotopology(ix,:); % this transmitter's received signal strength
            sigma2_z=sim_params('get', 'REC_NOISE_VAR');
            theta=sim_params('get', 'RECEPTION_SINR');
            for rec_ix=1:length(mote_IDs)
                if rec_ix~=ix
                    sigma2_ij=total_rec_power(rec_ix);
                    if strcmp(radio_data(rec_ix).state, 'idle')
                        if P_ij(rec_ix)/(sigma2_z+sigma2_ij)>=theta  % SINR good enough to receive
                            receive_power(rec_ix)=P_ij(rec_ix);
                            receive_ID(rec_ix)=ID;
                            data.signal_strength=P_ij(rec_ix);  % received signal strength
                            prowler('InsertEvents2Q', make_event(t+1, 'Packet_Receive_Start', mote_IDs(rec_ix), data, ID));
                            %[ID, rec_ix]
                        else 
                            % this mote will not receive this message, SINR too low
                        end
                    elseif strcmp(radio_data(rec_ix).state, 'receive')  
                        % check if currently received message is disturbed by this new transmission
                        if receive_power(rec_ix)/(sigma2_z+total_rec_power(rec_ix)+P_ij(rec_ix)-receive_power(rec_ix))>theta
                            % reception is not disturbed by this message
                        else % this message caused a collision
                            radio_data(rec_ix).state='collision';
                        end    
                    end
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
            TxID=receive_ID(ix);
            if TxID~=sID  
                % this message was 'overwriten' by another more powerful message sent at the very same time
            else 
                % check if simultanious messages not caused collision
                trans_ix=find(mote_IDs==TxID);
                sigma2_z=sim_params('get', 'REC_NOISE_VAR');
                theta=sim_params('get', 'RECEPTION_SINR');
                sigma_i=total_rec_power(ix);
                P_ij=receive_power(ix);
                if P_ij/(total_rec_power(ix)+sigma2_z-P_ij) >= theta  % message still OK
                    radio_data(ix).state='receive';
                    prowler('InsertEvents2Q', make_event(packet_length+t, 'Packet_Receive_End', ID, data, sID));
                else % collision caused by a simultanious message (sync sequence is OK, body destroyed)
                    radio_data(ix).state='collision';              
                    prowler('InsertEvents2Q', make_event(packet_length+t, 'Packet_Receive_End', ID, data, sID));
                end
            end
        else
            % another message supressed this message before it could have been received
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
        receive_power(ix)=0;
        receive_ID(ix)=NaN;                        
   
    case 'Packet_Transmit_Start'
        ix=find(mote_IDs==ID);
        radio_data(ix).state='transmit';
        radio_data(ix).data=data;

        prowler('InsertEvents2Q', make_event(packet_length+t, 'Packet_Transmit_End', ID, data));

        transmit_power(ix)=data.signal_strength;  % store local transmit power
        total_rec_power=transmit_power*radiotopology; % update the receivers' total received power properties

    case 'Packet_Transmit_End'
        ix=find(mote_IDs==ID);
        radio_data(ix).state='idle';
        radio_data(ix).data=[];
        radio_data(ix).transmit_pending=0;
        transmit_power(ix)=0;  % clear local transmit power
        total_rec_power=transmit_power*radiotopology; % update the receivers' total received power properties
        prowler('InsertEvents2Q', make_event(t, 'Packet_Sent', ID, data));

    otherwise
        error(['Bad event name for radio: ' event])
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function y=gen_rand_wait(min, var);
y=floor(min+var*rand);



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
function [new_radiotopology, total_rec_power_update]=radio_topology(varargin);
%% This function can be called with full or short input arg set 
%% Full call:
%%  [new_radiotopology, total_rec_power_update]=radio_topology(new_topology, old_topology, old_radiotopology, transmit_power);
%%  -> radio_topology is updated for motes with new position. 
%% Short call:
%%  new_radiotopology=radio_topology(topology, radiotopology, update_ix);
%%  -> radio_topology is updated for mote with index update_ix


if nargin > 3  % long call
    long_mode=1;
    
    new_topology=varargin{1};
    old_topology=varargin{2};
    old_radiotopology=varargin{3};
    transmit_power=varargin{4};
    
else % short call
    long_mode=0;
    new_topology=varargin{1};
    old_radiotopology=varargin{2};
    update_ix=varargin{3};
end

if long_mode
    N=size(new_topology,1);
    scan_ix=1:N;
    if ~all(size(old_topology)==size(new_topology))  % change of topology size or init
        old_radiotopology=zeros(N,N);
        old_topology=new_topology+1;                 % so old is different from the new
        new_radiotopology=zeros(N,N);
    else
        new_radiotopology=old_radiotopology;
    end
else
    new_radiotopology=old_radiotopology;
    scan_ix=update_ix;
end  

RADIO_RAYLEIGH_COH=sim_params('get', 'RADIO_RAYLEIGH_COH');
total_rec_power_update=0;
fn=sim_params('get', 'SIGNAL_FCN');
for i=scan_ix
    if long_mode == 0 | ~all(old_topology(i,:)==new_topology(i,:))  % update radio topology info
        pos=new_topology(i,:); d=distance(pos, new_topology);
        
        % Calculate fx
        x=d; fx_values=eval(fn);

        % update row
        r_vect=randexp(size(d'));
        new_radiotopology(i,:)=fx_values'.*r_vect;  
        % update column
        r_vect=randexp(size(d));
        new_radiotopology(:,i)=fx_values.*r_vect;  

        new_radiotopology(i,i)=0; % prevent inf or nan values
        if long_mode 
            if transmit_power(i) >  0
                total_rec_power_update=1;
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function updates the radio simulator's internal data structure to represent changes in the topology 
% or the transmission state of any of the motes
function [topology, radiotopology, timestamp, total_rec_power]=update_local_data(topology, radiotopology, timestamp, transmit_power, total_rec_power, force_rec_power_update)
[new_topology, mote_IDs, newtimestamp]=prowler('GetTopologyInfo');
rec_power_update=force_rec_power_update;
if newtimestamp>timestamp % physical topology changed 
    [radiotopology, rec_power_update]=radio_topology(new_topology, topology, radiotopology, transmit_power);
    topology=new_topology;
    timestamp=newtimestamp;
end
if rec_power_update
    total_rec_power=transmit_power*radiotopology;
end


function PropagationPlot(h,x)
% the axis is set to hold before calling this fcn
% the ideal propagation fcn is already plotted in green

param_save=sim_params('get'); % temporarily store parameters
tmp_pars=prowparams('getparams_from_gui'); % get GUI params
sim_params('set_from_gui',tmp_pars); % set parameters temporarily from GUI

topology_ex=[x(:), ones(length(x),1)];
radiotopology_ex=radio_topology(topology_ex, [], [],ones(length(x),1));

s_beta=sim_params('get', 'RADIO_SS_VAR_RAND');
idle_limit=sim_params('get', 'IDLE_LIMIT');
noise_var=sim_params('get', 'REC_NOISE_VAR');

y=radiotopology_ex(1,:);

sim_params('set_from_gui',param_save); % restore parameters

y2=y.*(1+s_beta*randn(size(y)));
y3=idle_limit*ones(size(x))*noise_var;
y4=noise_var*ones(size(x));
plot(x, y, 'b', x, y2, 'r', x, y3, 'y', x, y4, 'c', 'parent', h)
legend(h, 'P_{rec\_id}', 'P_{rec} (s_\beta=0)', 'P_{rec}', 'Idle limit', 'Rec noise var')

        
function y=randexp(size);
% produces random variables of size SIZE and of exponential distribution
% with mean one
y=randn(size).^2/2+randn(size).^2/2;