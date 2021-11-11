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
global CUSTOM_COLOR

persistent possible_destinations_count      % cantidad posible de destinos
persistent forward_ant_interval             % intervalo de tiempo entre envio de hormigas de forward
persistent waiting_time                     % tiempo de espera maximo de espera antes de sensar canal
persistent backoff_time                     % tiempo de espera de TinyOS al hallar colisiones
persistent packet_lenght_time               % delay para desplazamiento del paquete en el medio
persistent total_waiting_time               % time-slot para algoritmo de descubrimiento de vecinos
persistent theta                            % angulo de ancho del haz de la antena
persistent k                                % estimacion del numero de nodos alcanzables en la vecindad
persistent p_t                              % probabilidad optima para maximizar probabilidad de conocer vecinos (aproximacion para k grande)
persistent Tp                               % cantidad de time slots antes de pasar a modo de construccion de soluciones
persistent TmaxHops                         % numero de saltos limite para hormiga de forward
persistent forced_source
persistent forced_destination
persistent force_endpoints

switch event
case 'Init_Application'
        
    %%%%%%%%%%%%%%   Memory should be initialized here  %%%%%%%%%%%%%%%%%
    % incializacion de constantes
    possible_destinations_count = (max(size(mote_IDs)) - 1);                    % el destino es cualquier nodo menos el mismo
    %forward_ant_interval = (50 * 100)/3;                                        % bit-time
    waiting_time = 200 + 128;                                                   % bit-time
    backoff_time = 100 + 30;                                                    % bit-time
    packet_lenght_time = 960;                                                   % bit-time
    total_waiting_time = waiting_time + backoff_time + packet_lenght_time;      % bit-time
    TmaxHops = 5;
    forward_ant_interval = total_waiting_time * TmaxHops * 2;
    theta = pi;
    k = possible_destinations_count;                                            % sobre estimacion del numero de nodos en la vecindad (one-hop)
    p_t = 2*pi / (k*theta);
    Tp = 2 * (possible_destinations_count);                                   % estimamos el cuadrado de vecinos posibles
    force_endpoints = 1;
    forced_source = 1;
    forced_destination = 6;
    CUSTOM_COLOR = [0 0 0];
    
    % inicializacion de la memoria de cada elemento del enjambre
    % neighbors_count ->    cantidad de vecinos del elemento
    % destinations ->       IDs (direcciones) de los nodos destino
    % time_slot_count ->    cantidad de slots transcurridos desde inicio del programa (condicion de para para pasar a fase de construccion de soluciones)
    % T_matrix ->           matriz de feromonas (alineada en filas con el orden de NEIGHBORS{ID})
    % neighbors_list ->     copia de NEIGHBORS{ID} para preservar la interidad de las funciones locales (vector columna) en el orden cronologico de descubrimiento
    memory = struct('neighbors_count', 0, 'destinations', mote_IDs(mote_IDs ~= ID),... 
        'time_slot_count', 0, 'T_matrix', [], 'neighbors_list', []);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   

    % se inicia la tarea para descubrir vecinos
    Set_Flood_Clock(t + total_waiting_time);
    if (ix==1)
         loginit('log/ant_net.log');
    end
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
    if (msgID >= 0) % identificador del paquete                                                       
        logevent('PacketReceived');
        if(msgID == 0)                                                              % paquete para descubrir vecinos
            pass = 0;                                                               % no es de interes que llegue a capa de app
            PrintMessage(sprintf("id: %d ne: %d", ID, max(size(NEIGHBORS{ID}))));            
            if max(size(NEIGHBORS{ID})) > memory.neighbors_count                    % verificamos si el vecino es nuevo
                memory.neighbors_count = max(size(NEIGHBORS{ID}));                  % es nuevo vecino, actualizar matriz de feromonas
                memory.neighbors_list = [memory.neighbors_list; NEIGHBORS{ID}(end)];
                memory.T_matrix = enter_new_row(memory.T_matrix, possible_destinations_count);
            end
        elseif (msgID == 1)                                                         % paquete de hormiga de forward
            pass = 0;                                                               % no es de interes que llegue a capa de app
            rdata.maxhops = rdata.maxhops - 1;
            if rdata.destination == ID                                              % condicion de paro
                % enviar hormiga de backward
                bdata.msgID = 2;                                                    % ID para hormigas de backward
                bdata.source = ID;
                bdata.destination = rdata.source;
                %bdata.maxhops = TmaxHops;
                bdata.back_path = rdata.path;
                bdata.back_path.remove_loops();
                bdata.address = bdata.back_path.pop();
                bdata.value = 'Backward_Ant';
                mainAntNet_layer(N, make_event(t, 'Send_Packet', ID, bdata));
            else
                % evaluar el numero de saltos, si ya no le quedan saltos (maxhops == 0) botar el paquete (en este caso no hacer nada)
                if rdata.maxhops ~= 0
                    % se quiere elegir el siguiente salto, dentro de la vecindad
                    % los nodos no visitados ya
                    % con la distribucion de probabilidad de la matriz T
                    % si ya toda la vecindad fue visitada, dentro de todos
                    rdata.path.push(ID);     % agregar el nodo actual al path
                    rdata.address = next_hop_forward_ant(rdata.destination, memory.destinations, memory.neighbors_list, memory.T_matrix, cell2mat(rdata.path.content()));
                    PrintMessage(sprintf("%d -> %d: %d", rdata.source, rdata.destination, rdata.address));
                    mainAntNet_layer(N, make_event(t, 'Send_Packet', ID, rdata));
                end
            end
        elseif (msgID == 2)
            pass = 0;
            if rdata.destination == ID
                pass = 0; % dummy
            else
                rdata.address = rdata.back_path.pop();
                mainAntNet_layer(N, make_event(t, 'Send_Packet', ID, rdata));
            end 
        end
    end

case 'Collided_Packet_Received'
    % this is for debug purposes only
    
case 'Clock_Tick'
    if (strcmp(data.type,'ant_net_discovery'))
        memory.time_slot_count = memory.time_slot_count  + 1;                       % actualizar contador de time slots
        if (memory.time_slot_count >= Tp) && (memory.neighbors_count > 0)           % si ya se llego a Tp time slots y se tienen vecinos pasar al siguiente modo
            if (force_endpoints && (ID == forced_source)) || ((~forced_destination) && SOURCES(ID)) % evaluar nodo fuente
                Set_Forward_Ant_Clock(t + forward_ant_interval);
            end
        else            
            if (rand < p_t)                                                         % enviar un frame de descubrimiento con probabilidad pt
                fdata.msgID = 0;                                                    % id de mensaje hello
                fdata.maxhops = 1;                                                  % solo un salto
                fdata.address = 0;                                                  % direccion de broadcast
                fdata.source = ID;                                                  % source en capa 3
                fdata.value = 'Ant_discover';                                       % identificador de paquete para descubrir vecinos
                mainAntNet_layer(N, make_event(t, 'Send_Packet', ID, fdata));       % enviar paquete
            end
            Set_Flood_Clock(t + total_waiting_time);
        end
    elseif (strcmp(data.type,'periodic_ant_send'))
        % construccion de soluciones - paso 1
        fdata.msgID = 1;                                                            % id para hormigas de forward
        fdata.maxhops = TmaxHops;                                                   % maximo de saltos
        %fdata.destination = randsample(memory.destinations, 1);                    % elegir un destino al azar (omitido por el momento)
        if force_endpoints
            fdata.destination = forced_destination;
        else
            fdata.destination = find(DESTINATIONS == 1, 1);                         % acoplar el destino elegido por RMASE
        end
        fdata.source = ID;                                                          % source a nivel de capa 3
        fdata.path = CStack(fdata.source);                                          % pila para guardar el camino en forward
        fdata.address = next_hop_forward_ant(fdata.destination, memory.destinations, memory.neighbors_list, memory.T_matrix, cell2mat(fdata.path.content()));
        fdata.value = 'Forward_Ant';
        PrintMessage(sprintf("%d -> %d: %d", fdata.source, fdata.destination, fdata.address));
        mainAntNet_layer(N, make_event(t, 'Send_Packet', ID, fdata));
        Set_Forward_Ant_Clock(t + forward_ant_interval);                  % este evento siempre se reagenda a sí mismo en intervalos regulares
        
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


% val_list es una lista (vector fila o columna de largo L)
% val_weights es una lista de largo L con pesos correspondientes con val_list
% se retorna un valor aleatorio entre los elementos de val_list con distribucion de probabilidad dada por val_weights
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


% A es una matriz de M X N
% retorno de una nueva matriz de (M + 1) X N con probabilidad normalizada por columnas
% la probabilidad asignada a la nueva fila es 
function B = enter_new_row(A, N)
K = size(A, 1);         % filas en A
if K == 0
    B = ones([1, N]);   % al inicio toda la probabilidad esta concentrada
else
    new_prob = (1 / (K + 1));                   % nueva probabilidad que tendra la fila nueva
    rem_prob = 1 - new_prob;                    % probabilidad a la que deben ajustarse los elementos viejos de cada columna
    scale_per_column = rem_prob ./ sum(A, 1);   % factores de escalamiento de cada columna
    A_rescaled = scale_per_column .* A;
    new_row = new_prob * ones([1, N]);
    B = [A_rescaled; new_row];
end


function marked_list = zeros_from_black_list(black_list, target_list)
% toma una lista negra con valores i, y otra lista negra con valores j
% devuelve una lista marked_list tal que las entradas con valor j = i para alguna i se hacen 0, de lo contrario 1
marked_list = zeros(size(target_list)); % ya se sabe el tamaño de la salida
for ii = 1 : max(size(target_list)) % ya se sabe cuántas iteraciones se van a tener
    lookup_value = target_list(ii);
    if isempty(find(black_list == lookup_value, 1)) % el elemento lookup_value no está en black_list, se puede quedar sin alteraciones
        marked_list(ii) = 1;
    end
end

% elije el siguiente salto para las hormigas de forward con base en el distino, los vecinos, la matriz de feromonas y los nodos ya visitados
function nh = next_hop_forward_ant(destination, destinations_list, neighors_list, T_matrix, visited_nodes)
target_index = find(destinations_list == destination, 1);                   % indice de la columna correspondiente al nodo destino
pick_list = zeros_from_black_list(visited_nodes, neighors_list);            % factor de escala para la columna de correspondiente al nodo destino
if isempty(find(pick_list == 1, 1))                                               % todos los nodos ya se visitaron
    nh = pick_random_value(neighors_list, T_matrix(:, target_index));
else
    nh = pick_random_value(neighors_list, pick_list .* T_matrix(:, target_index));
end

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