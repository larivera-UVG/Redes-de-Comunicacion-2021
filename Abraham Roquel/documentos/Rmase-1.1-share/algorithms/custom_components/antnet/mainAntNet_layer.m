function status = mainAntNet_layer(N, S)

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
global SOURCES

persistent neighbors_discover_interval
persistent neighbors_discover_pm
persistent neighbors_discovery
persistent forward_ant_interval
persistent waiting_time
persistent backoff_time
persistent packet_lenght_time
persistent theta
persistent total_waiting_time
persistent p_t %probabilidad optima para maximizar probabilidad de conocer vecinos (aproximacion para k grande)
persistent k % estimacion del numero de nodos alcanzables en la vecindad
persistent possible_destinations_count
persistent steady_neighbor %cantidad de slots sin cambios en la vencidad antes de empezar construccion de soluciones
persistent Tp %cantidad de time slots antes de pasar a modo de construccion de soluciones

switch event
case 'Init_Application'
        
    %%%%%%%%%%%%%%   Memory should be initialized here  %%%%%%%%%%%%%%%%%
    possible_destinations_count = (max(size(mote_IDs)) - 1);
    Tp = 2*(possible_destinations_count ^ 2);
    steady_neighbor = possible_destinations_count / 3;
    waiting_time = 200 + 128; %bit-time
    backoff_time = 100 + 30; %bit-time
    packet_lenght_time = 960; %bit-time
    total_waiting_time = waiting_time + backoff_time + packet_lenght_time; %bit-time
    theta = pi;
    k = possible_destinations_count; %sobre estimacion del numero de nodos en la vecindad
    p_t = 2*pi / (k*theta);
    neighbors_discover_interval = 60; %ms
    neighbors_discover_pm = 30; %ms
    forward_ant_interval = 50; %ms
    neighbors_discovery = max(size(mote_IDs));
    memory = struct('neighbors_count', 0, 'destinations', mote_IDs(mote_IDs ~= ID),... 
        'steady_neighbor_count', 0, 'time_slot_count', 0);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    %Set_Flood_Clock(get_random_time(t, neighbors_discover_interval, neighbors_discover_pm));
    Set_Flood_Clock(t + total_waiting_time);
    if (ix==1)
         loginit('log/ant_net.log');
    end

    % if DESTINATIONS(ID)
    %     LED(['yellow', 'on']);
    % elseif SOURCES(ID)
    %     LED(['yellow', 'on']);
    % end

case 'Send_Packet'
    try msgID = data.msgID; catch msgID = 0; end
    if (msgID >= 0)
        logevent('sendPacket');
    end
case 'Packet_Sent'
    try msgID = data.msgID; catch msgID = 0; end
    if (msgID >= 0)
        logevent('PacketSent');
    end
case 'Packet_Received'
    rdata = data.data;
    try msgID = rdata.msgID; catch msgID = 0; end
    if (msgID >= 0) %source data
        logevent('PacketReceived');
        if(strcmp(rdata.value,'Ant_discover'))
            pass = 0;
            PrintMessage(sprintf("id: %d ne: %d", ID, max(size(NEIGHBORS{ID}))));
            % if (msgID == 0)
            %     sdata.msgID = 1;
            %     sdata.maxhops = 1;
            %     sdata.address = rdata.from;
            %     sdata.source = ID;
            %     sdata.value = 'Ant_discover';
            %     mainAntNet_layer(N, make_event(t + 500, 'Send_Packet', ID, sdata));
            % end
        elseif (strcmp(rdata.value,'Forward_Ant'))
            pass = 0;
            fdata.msgID = 2; %id para hormigas de forward
            fdata.maxhops = rdata.maxhops - 1; %tope 20 saltos
            %elegir un destino aleatorio que no sea el mismo y de dónde vino
            fdata.value = 'Forward_Ant';
            possible_hops = NEIGHBORS{ID}(NEIGHBORS{ID} ~= rdata.from);
            if isempty(possible_hops)
                fdata.address = rdata.from;
            else
                fdata.address = randsample(possible_hops,1);
            end
            mainAntNet_layer(N, make_event(t, 'Send_Packet', ID, fdata));
        end
    end

case 'Collided_Packet_Received'
    % this is for debug purposes only
    
case 'Clock_Tick'
    if (strcmp(data.type,'ant_net_discovery'))
        %comparar los vecinos conocidos actuales para ver si hubo cambios
        %current_neighbors_count = max(size(NEIGHBORS{ID}));
        %if current_neighbors_count == memory.neighbors_count
        %    memory.steady_neighbor_count = memory.steady_neighbor_count + 1;
        %else
        %    memory.steady_neighbor_count = 0;
        %    memory.neighbors_count = current_neighbors_count;
        %end
        % si ya no hay cambios agendar construccion de soluciones si es nodo fuente
        %if (memory.steady_neighbor_count >= steady_neighbor) && (current_neighbors_count > 0)
        %    if (SOURCES(ID)) 
        %        Set_Forward_Ant_Clock(t + (neighbors_discover_interval*100)/3);
        %    end
        %else
        % actualizar contador de time slots
        memory.time_slot_count = memory.time_slot_count  + 1;
        % si ya se llego a Tp y se tienen vecinos pasar al siguiente modo
        if (memory.time_slot_count >= Tp) && (current_neighbors_count > 0)
            if (SOURCES(ID)) 
                Set_Forward_Ant_Clock(t + (neighbors_discover_interval*100)/3);
            end
        else
            % enviar un frame de descubrimiento con probabilidad pt
            if (rand < p_t)
                fdata.msgID = 0; %id de mensaje hello
                fdata.maxhops = 1; %solo un salto
                fdata.address = 0; %broadcast
                fdata.source = ID; %source en capa 3
                fdata.value = 'Ant_discover'; %identificador de discover
                mainAntNet_layer(N, make_event(t, 'Send_Packet', ID, fdata));
            end
            Set_Flood_Clock(t + total_waiting_time);
        end
        %mainAntNet_layer(N, make_event(t, 'Send_Packet', ID, fdata));
        %memory.neighbors_discovery_count = memory.neighbors_discovery_count + 1;
        %if  memory.neighbors_discovery_count == neighbors_discovery
        %    %empezar el envío de paquetes de ruteo
        %    memory.neighbors_discovery_count = 0;
        %    Set_Forward_Ant_Clock(t + (memory.destinations_count * forward_ant_interval * 100)/3);
        %else
        %    Set_Flood_Clock(get_random_time(t, neighbors_discover_interval, neighbors_discover_pm));
        %end
    elseif (strcmp(data.type,'periodic_ant_send'))
        fdata.msgID = 2; %id para hormigas de forward
        fdata.maxhops = 20; %tope 20 saltos
        fdata.source = ID; %source a nivel de capa 3
        %elegir un destino aleatorio que no sea el mismo
        %fdata.destination = randsample(memory.destinations, 1); 
        fdata.value = 'Forward_Ant';
        fdata.address = randsample(NEIGHBORS{ID},1);
        mainAntNet_layer(N, make_event(t, 'Send_Packet', ID, fdata));
        %PrintMessage(sprintf("%d picked %d", ID, fdata.destination));
        %este evento siempre se reagenda a sí mismo en intervalos regulares
        Set_Forward_Ant_Clock(t + (forward_ant_interval * 100)/3); 
        
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


function b=Set_Flood_Clock(alarm_time)
global ID
clock.type = 'ant_net_discovery';
prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));

function b=Set_Forward_Ant_Clock(alarm_time)
global ID
clock.type = 'periodic_ant_send';
prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));


function t_sched = get_random_time(t, interval, pm)
%retornar un valor aleatorio de tiempo t + rand[interval-pm, interval+pm]
t_sched = (t + floor((((interval - pm) + rand*2*pm) * 100)/3))

function v = pick_random_value(val_list, val_weights)
s = sum(val_weights);
val_probs = val_weights / s;    % normalizar los pesos
test_n = rand;                  % numero aleatorio entre 0 y 1
k = 1;                          % apunta a la posicion de val_list a retornar
accum_sum = val_probs(k);       % valor para comparacion, suma acumulada
while test_n > accum_sum        % vemos si la suma acumulada es menor que el numero aleatorio
    k = k + 1;
    accum_sum = accum_sum + val_probs(k);
end
v = val_list(k);

function PrintMessage(msg)
global ID
prowler('TextMessage', ID, msg)

function LED(msg)
global ID
prowler('LED', ID, msg)

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