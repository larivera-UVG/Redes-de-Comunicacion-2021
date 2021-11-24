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
global CUSTOM_COLOR_FORWARD
global CUSTOM_COLOR_BACKWARD

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
persistent window_size                      % cantidad de muestras sobre las cuales tomar el mejor rtt
persistent max_window_size                  % valor maximo de window_size
persistent t_arr                            % arreglo de tiempo para almacenar las trayectorias
persistent T_column_arr                     % matriz que guarda las columnas de T_matrix correspondientes con t arr
persistent N_column_arr                     % matriz que guarda los vecinos correspondientes con t arr
persistent counter_arr                      % contador para apuntar al ultimo valor valido
persistent bit_time                         % da acceso al factor de conversion
persistent stop_condition                   % valor para parar la simulacion
persistent standalone_figure                % handler para capturar las imagenes de los paths
persistent p_zeta
persistent p_c
persistent p_v
persistent p_c1
persistent p_c2
persistent reinf_mode
persistent penalize_forward_loss            % variable para decidir si se penalizan las perdidas de las hormigas de forward
persistent penalize_k                       % factor de penalizacion
persistent i_am_source

switch event
case 'Init_Application'
        
    %%%%%%%%%%%%%%   Memory should be initialized here  %%%%%%%%%%%%%%%%%
    % incializacion de constantes
    bit_time = sim_params('get', 'BIT_TIME');
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
    Tp = ceil(possible_destinations_count/2);                                   % estimamos el cuadrado de vecinos posibles
    force_endpoints = 1;
    forced_source = 17;
    forced_destination = 41;
    CUSTOM_COLOR_FORWARD = [0 0 0];
    CUSTOM_COLOR_BACKWARD = [1 0 0];

    penalize_forward_loss = 1;
    penalize_k = 0.05;

    p_zeta = 0.2;
    p_c = 1;
    max_window_size = 5*p_c/p_zeta;
    window_size = max_window_size;

    p_v = 0.9;
    p_c1 = 0.5;
    p_c2 = 0.5;

    reinf_mode = 2; % 1 para modelo del libro, 2 para solo wbest, 3 para solo modelo de la media

    max_iterations = 100;
    i_am_source = ((force_endpoints && (ID == forced_source)) || (~force_endpoints && not(isempty(SOURCES)) && SOURCES(ID)));
    if i_am_source
        stop_condition = 1e-3;
        counter_arr = 0;                                                        % empezar sin valores validos
        t_arr = zeros([1, max_iterations]);                                     % vector fila
        T_column_arr = zeros([possible_destinations_count, max_iterations]);    % cada columna corresponde con t_arr
        N_column_arr = zeros([possible_destinations_count, max_iterations]);    % cada columna corresponde con t_arr
        h2 = findall(groot,'Type','figure');
        if strcmp(h2(1).Name, 'Prowler - Display')
            standalone_figure = h2(1);
        else
            standalone_figure = h2(2);
        end
    end 

    
    % inicializacion de la memoria de cada elemento del enjambre
    % neighbors_count ->    cantidad de vecinos del elemento
    % destinations ->       IDs (direcciones) de los nodos destino
    % time_slot_count ->    cantidad de slots transcurridos desde inicio del programa (condicion de para para pasar a fase de construccion de soluciones)
    % T_matrix ->           matriz de feromonas (alineada en filas con memory.neighbors_list , y en columnas con memory.destinations)
    % neighbors_list ->     copia de NEIGHBORS{ID} para preservar la interidad de las funciones locales (vector columna) en el orden cronologico de descubrimiento
    % i_counter ->          contador que aumenta en cada unidad de tiempo para calcular el RTT
    % S_matrix ->           matriz d 4 x N donde N es el número de destinos (alineado en columnas con memory.destinations)
    %   fila 1 para la media, 2 para la varianza
    % R_martix ->     matriz de valores previos del rtt para los diferentes destinos (alineado en columnas memory.destinations)
    % seq ->                vector fila alineado con destinations que guarda un numero de secuencia de para cada destino
        % fila 1 es un contador que asciende cada vez que se envia (o se hace forward) una hormiga de forward al destino d
        % fila 2 es un contador que asciende cada vez que se recibe una hormiga de backward del destino d
        % fila 3 es la perdida actual (fila 1 - fila 2) que se actualiza cada vez que se envia una hormiga de forward
        % fila 4 guarda el id del ultimo vecino por medio del cual se mando el paquete
    memory = struct('neighbors_count', 0, 'destinations', mote_IDs(mote_IDs ~= ID),... 
        'time_slot_count', 0, 'T_matrix', [], 'neighbors_list', [], 'i_counter', 0,...
        'S_matrix', zeros([2, possible_destinations_count]), 'R_matrix', zeros([window_size, possible_destinations_count]),...
        'seq', zeros([4, possible_destinations_count]));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   

    % se inicia la tarea para descubrir vecinos
    Set_Flood_Clock(t + total_waiting_time);

    % agendar tarea de contador
    %Set_Counter_Clock(t + 1);

    if (ix==1)
         loginit('log/reinf_ant_net.log');
    end
case 'Send_Packet'
    try msgID = data.msgID; catch msgID = 0; end
    if (msgID >= 0)
        %logevent('sendPacket');
    end
case 'Packet_Sent'
    try msgID = data.msgID; catch msgID = 0; end
    if (msgID >= 0)
        %logevent('PacketSent');
    end
case 'Packet_Received'
    rdata = data.data;
    try msgID = rdata.msgID; catch msgID = 0; end
    if (msgID >= 0) % identificador del paquete                                                       
        %logevent('PacketReceived');
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
                bdata.back_path = rdata.path;                                       % hacer una copia de la pila de la hormiga de forward
                bdata.back_path.remove_loops2();                                    % quitar los loops (v2)
                top_element = bdata.back_path.top();                                % tomar el elemento en el top de la pila
                bdata.address = top_element(1);                                     % seguir el mismo camino de regreso, sin loops
                bdata.value = 'Backward_Ant';                               
                mainAntNet_layer(N, make_event(t, 'Send_Packet', ID, bdata));
            else
                % evaluar el numero de saltos, si ya no le quedan saltos (maxhops == 0) botar el paquete (en este caso no hacer nada)
                if rdata.maxhops ~= 0
                    % se quiere elegir el siguiente salto, dentro de la vecindad
                    % los nodos no visitados ya
                    % con la distribucion de probabilidad de la matriz T
                    % si ya toda la vecindad fue visitada, dentro de todos
                    rdata.path.push([ID, t]);                                       % agregar el nodo actual al path, con tiempo t para calcular el rtt
                    content_path = cell2mat(rdata.path.content());                  % extraer el contenido de la pila
                    focus_column = content_path(:, 1);                              % tomar la columna del path
                    % actualizar valores de matriz de secuencias
                    target_index_seq = find(memory.destinations == rdata.destination, 1);
                    previous_loss = memory.seq(3, target_index_seq);
                    current_loss = memory.seq(1, target_index_seq) - memory.seq(2, target_index_seq);
                    if penalize_forward_loss && (current_loss > previous_loss)
                        % penalizar las perdidas
                        memory.T_matrix = penalize_loss(memory.T_matrix, rdata.destination, memory.destinations, penalize_k, memory.seq(4, target_index_seq), memory.neighbors_list);
                    end
                    memory.seq(1, target_index_seq) = memory.seq(1, target_index_seq) + 1;  % actualizar contador de forward
                    memory.seq(3, target_index_seq) = current_loss;                         % actualizar las perdidas actuales

                    rdata.address = next_hop_forward_ant(rdata.destination, memory.destinations, memory.neighbors_list, memory.T_matrix, focus_column);
                    memory.seq(4, target_index_seq) = rdata.address;                        % actualizar el ultimo vecino
                    PrintMessage(sprintf("%d -> %d: %d", rdata.source, rdata.destination, rdata.address));
                    mainAntNet_layer(N, make_event(t, 'Send_Packet', ID, rdata));
                end
            end
        elseif (msgID == 2)                                                         % se recibio una hormiga de backwards
            pass = 0;                                                               % no debe llegar a capa de app
            top_element = rdata.back_path.top();                                    % el top element trae nuestro ID y el tiempo t cuando enviamos (o hicimos forward) la hormiga
            spent_time = t - top_element(2);                                        % rtt
            [memory.S_matrix, memory.R_matrix, r_T] = udpate_and_get_r(memory.S_matrix, memory.R_matrix, rdata.source, memory.destinations, spent_time, p_zeta, window_size, p_c1, p_c2, p_v, reinf_mode);
            %r_T = 0.7;                                                              % reinforcement
            memory.T_matrix = udpate_T_matrix(memory.T_matrix, rdata.source, memory.destinations, r_T, rdata.from, memory.neighbors_list);

            % actualizar el contador apropiado de la matriz de secuencias
            target_index_seq = find(memory.destinations == rdata.source, 1);
            memory.seq(2, target_index_seq) = memory.seq(2, target_index_seq) + 1;

            if rdata.destination == ID
                pass = 0; % dummy
                % guardar en memoria los valores actualizados
                counter_arr = counter_arr + 1;
                saveas(standalone_figure, sprintf('img_%d.jpg', counter_arr));
                t_arr(counter_arr) = t * bit_time;
                N_column_arr(1 : memory.neighbors_count, counter_arr) = memory.neighbors_list;
                f_column_save = memory.T_matrix(:, find(memory.destinations == rdata.source, 1));
                T_column_arr(1:  memory.neighbors_count, counter_arr) = f_column_save;
                % evalar la condicion de paro
                if (1 - max(f_column_save)) < stop_condition
                    save('test_results.mat', 'counter_arr', 't_arr', 'N_column_arr', 'T_column_arr');
                    abe_myfun();
                    prowler('StopSimulation');
                end
                DrawLine('delete', inf, inf); % borrar todas las flechas
            else
                rdata.back_path.pop();                                              % remover elemento en top                       
                top_element_new = rdata.back_path.top();
                rdata.address = top_element_new(1);                                 % seguir camino de regreso    
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
            if (force_endpoints && (ID == forced_source)) || ((~force_endpoints) && SOURCES(ID)) % evaluar nodo fuente
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
            fdata.destination = forced_destination;                                 % elegir el destino indicado explícitamente
        else
            fdata.destination = find(DESTINATIONS == 1, 1);                         % acoplar el destino elegido por RMASE
        end
        fdata.source = ID;                                                          % source a nivel de capa 3
        %fdata.path = CStack(fdata.source);                                          
        %fdata.address = next_hop_forward_ant(fdata.destination, memory.destinations, memory.neighbors_list, memory.T_matrix, cell2mat(fdata.path.content()));
        %v2
        fdata.path = CStack([fdata.source, t]);                                     % pila para guardar el camino en forward, con su tiempo t
        content_path = cell2mat(fdata.path.content());                              % extraer el conenido de la pila en forma matricial
        focus_column = content_path(:, 1);                                          % tomar la primera columna (columna de IDs sobre el path)
        % actualizar la matriz de secuencias
        target_index_seq = find(memory.destinations == fdata.destination, 1);
        previous_loss = memory.seq(3, target_index_seq);
        current_loss = memory.seq(1, target_index_seq) - memory.seq(2, target_index_seq);
        if penalize_forward_loss && (current_loss > previous_loss)
            % penalizar las perdidas
            memory.T_matrix = penalize_loss(memory.T_matrix, fdata.destination, memory.destinations, penalize_k, memory.seq(4, target_index_seq), memory.neighbors_list);
            pGGG = 0;
        end
        memory.seq(1, target_index_seq) = memory.seq(1, target_index_seq) + 1;  % actualizar contador de forward
        memory.seq(3, target_index_seq) = current_loss;                         % actualizar perdidas actuales

        fdata.address = next_hop_forward_ant(fdata.destination, memory.destinations, memory.neighbors_list, memory.T_matrix, focus_column);
        memory.seq(4, target_index_seq) = fdata.address;    % actualizar el ultimo vecino
        fdata.value = 'Forward_Ant';
        PrintMessage(sprintf("%d -> %d: %d", fdata.source, fdata.destination, fdata.address));
        %DrawLine('delete', inf, inf); % borrar todas las flechas
        mainAntNet_layer(N, make_event(t, 'Send_Packet', ID, fdata));
        Set_Forward_Ant_Clock(t + forward_ant_interval);                  % este evento siempre se reagenda a sí mismo en intervalos regulares
    elseif (strcmp(data.type,'counter_up'))
        % tarea para aumentar contador
        memory.i_counter = memory.i_counter + 1;
        Set_Counter_Clock(t + 1);
    end

    if (abs(t - sim_params('get', 'STOP_SIM_TIME')) <= 1) && i_am_source
        save('test_results.mat', 'counter_arr', 't_arr', 'N_column_arr', 'T_column_arr', 'penalize_forward_loss', 'penalize_k');
        abe_myfun();
        prowler('StopSimulation');
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


function b =Set_Counter_Clock(alarm_time)
global ID
clock.type = 'counter_up';
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


% actualizar la matriz de feromonas para el destino correspondiente con base en el refuero r
function new_T = udpate_T_matrix(old_T, destination, destinations_list, r, chosen_neighbor, neighbors_list)
new_T = old_T(:, :); % hacer una copia de la matriz de feromonas
target_destination_index = find(destinations_list == destination, 1);       % hallar los indices apropiados de la matriz T
target_neighbor_index = find(neighbors_list ==chosen_neighbor, 1);
% aplicar la regla de asignacion
old_chosen = new_T(target_neighbor_index, target_destination_index);
new_T(target_neighbor_index, target_destination_index) = old_chosen + r * (1 - old_chosen);
for ii = 1 : max(size(neighbors_list))
    if ii ~= target_neighbor_index
        old_val = new_T(ii, target_destination_index);
        new_T(ii, target_destination_index) = old_val - r * old_val;
    end
end

% debe devolver un valor entre 0 y 1 para calcular el reinforcement
function r = get_reinforcement(rtt_mean, rtt_variance, rtt_best, new_rtt, c1, c2, w, v, reinf_mode)
if reinf_mode == 1
    Iinf = rtt_best;
    z = 1.0 / sqrt(1 - v);
    Isup =  rtt_mean + z * (rtt_variance / sqrt(w));
    denominator = (Isup - Iinf) + (new_rtt - Iinf);
    if denominator == 0
        term_mean = 0;
    else
        term_mean = c2 * (Isup - Iinf) / denominator;
    end
    term_best = c1 * rtt_best / new_rtt;
    r = term_best + term_mean;
    r = min([r, 0.3]);
elseif reinf_mode == 2
    r = min([rtt_best/new_rtt, 0.3]);
else
    r = min([rtt_mean/new_rtt, 0.3]);
end

% devuelve las nuevas matrices de modelos y valores previos del rtt, y el reinforcement para los nuevos valores
function [new_S, new_R, reinf] = udpate_and_get_r(old_S, old_R, destination, destinations_list, new_rtt, p_zeta, p_window, c1, c2, v, reinf_mode)
new_S = old_S(:, :);                                                                    % hacer una copia de la matriz de modelos
new_R = old_R(:, :);                                                                    % hacer una copia de la matriz de rtts
target_destination_index = find(destinations_list == destination, 1);                   % indice de columna clave en ambas matrices
old_values = old_S(:, target_destination_index);                                        % valores previos del modelo
new_S(1, target_destination_index) = old_values(1) + p_zeta*(new_rtt - old_values(1));  % actualizar modelo de la media
new_S(2, target_destination_index) = old_values(2) + p_zeta*((new_rtt - new_S(1, target_destination_index))^2 - old_values(2)); % actualizar modelo de varianza
new_R(1:end-1, target_destination_index) = new_R(2:end, target_destination_index);      % hacer el shift de los valores previos de rtt
new_R(end, target_destination_index) = new_rtt;                                         % hacer el feed del registro con new_rtt
focus_column_best = new_R(end + 1 - p_window : end, target_destination_index);          % grupo de interes para hallar el mínimo
current_best = min(focus_column_best(focus_column_best > 0));                           % calcular el máximo sobre el grupo de interés
% obtener el refuerzo
reinf = get_reinforcement(new_S(1, target_destination_index), new_S(2, target_destination_index), current_best, new_rtt, c1, c2, p_window, v, reinf_mode);


% disminuye la feromona para los parametros indicados manteniendo la normalizacion
function new_T = penalize_loss(old_T, destination, destinations_list, k, neighbor, neighbors_list)
new_T = old_T(:, :);                                                    % hacer una copia de la matriz de feromonas
target_destination_index = find(destinations_list == destination, 1);   % ubicar la columna de interes
target_neighbor_index = find(neighbors_list == neighbor, 1);            % ubicar la fila de interes
select_y = (neighbors_list == neighbor);                                % vectores de seleccion
select_x = ~ select_y;
old_column = old_T(:, target_destination_index);                        % valores antiguos de la columna
alpha_y = 1 - k;                                                        % factor de escala para el target
K = 1 - (alpha_y * old_column(target_neighbor_index));                  % factor de escala para el resto de filas
L = sum(old_column .* select_x);
alpha_x = K/L;
new_T(:, target_destination_index) = (alpha_y * (select_y .* old_column)) + (alpha_x * (select_x .* old_column));

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
