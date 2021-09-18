function status = mainAntNet_layer(N, S)

% Universidad del Valle de Guatemala
% Diseño e innovación en ingeniería 2
% capa principal del algoritmo de enrutamiento basado en ANTNET


% para una prueba sencilla, se puede usar la configuración
%	set_layers({'mac','mainAntNet','app','stats'})

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

global NEIGHBORS
global DESTINATIONS
global SOURCES


% DEFINIR PAR�?METROS DEL ALGORITMO
persistent source_rate  % define la tasa de transmisión de salida 
persistent delta_t      % intervalo de tiempo para enviar hormigas de forward hacia un desitno (constante)
persistent w_max        % tamaño máximo de la ventana de observación (Wbest sobre w_max observaciones) (constante)
persistent zeta_p       % parámetro para actualización de u_id, sigma_id
persistent c_w          % parámetro para definir ventana de observación de w_max = 5*c_w / zeta_p
persistent alpha_p      % parámetro para medir la importancia de eta_ij (medida de la cola en nodo i hacia j)
persistent max_life     % máximo número de saltos de hormiga de forward antes de ser descartada
persistent r_p          % parámetro de reinforcement (qué tan buena es una ruta)
persistent c1           % peso de la calidad del trip time actual en comparación con Wbest para r_p
persistent c2           % peso de la calidad del trip time actual en comparación con el intervalo de confianza
persistent z_i          % parámetro para escalar la cota superior del intervalo de confianza z_i = 1 / sqrt(1 - v_i)
persistent v_i          % parámetro para definir el intervalo de confiaza (mientras más cercano a 1, más grande)
persistent discover_message_id
persistent possible_message_ids
persistent random_range
persistent generic_message_id



switch event
case 'Init_Application'
    % inicialización de parámetros
    if (ix==1)
        possible_message_ids = [];
        discover_message_id = 1;
        possible_message_ids(end+1) = discover_message_id;
        generic_message_id = 2;
        possible_message_ids(end+1) = generic_message_id;
        random_range = [0 50e-3]; % ms
        source_rate = 100e3;                        % supongamos un ancho de banda de 100 kbps
        delta_t = 100e-3;                           % cada 100 ms enviamos una hormiga de forward
    end

    % reserva de memoria
    memory = struct('test', 0);

    % print del ID
    PrintMessage(sprintf("a_%d", ID));

    % agendar tarea incial
    Set_Start_Clock(t + delta_t + get_random_number(random_range));

case 'Send_Packet'
    % try msgID = data.msgID; catch msgID = 0; end
    % if (msgID >= 0)
    %     logevent('sendPacket');
    %      if (memory.parent>0)
    %       data.address = memory.parent;
    %     else
    %       pass = 0;
    %     end
    % end
    try msgID = data.msgID; catch msgID = -1; end     %leer el msgID del paquete que se quiere enviar
    if (ismember(msgID, possible_message_ids))
        logevent(sprintf("Message sent from %d to %d", ID, data.address));
    else
        pass = 0; % si no tiene sentido botar el paquete
    end

case 'Packet_Received'
    try msgID = data.msgID; catch msgID = -1; end
    if (msgID == discover_message_id)
        pass = 0;
    end
    
case 'Clock_Tick'
    try type = data.type; catch type = 'none'; end      %determinar qué tipo de tarea es tiempo de hacer
    %prowler('PrintEvent', sprintf("clock event type %s", type));
    if (strcmp(type, 'periodic_ant_send'))
        % if(isempty(NEIGHBORS{ID}) == 0)
        %     vecindad = NEIGHBORS{ID};               % evaluar la vecindad
        %     destino = randsample(vecindad, 1);      % elegir un vecino al azar
        %     PrintMessage(sprintf("s -> %d", destino))
        %     datos_paquete.msgID = destino;          % adjuntarlo a la estructura para el evento
        %     status = mainAntNet_layer(N, make_event(t + delta_t/5, 'Send_Packet', ID, datos_paquete)); % generar el evento
        % else
        
        if(isempty(NEIGHBORS{ID}))   
            datos_paquete.msgID = discover_message_id;
            datos_paquete.address = 0;
            status = mainAntNet_layer(N, make_event(t + delta_t/5, 'Send_Packet', ID, datos_paquete));
        else
            datos_paquete.msgID = generic_message_id;
            datos_paquete.address = randsample(NEIGHBORS{ID});
            status = mainAntNet_layer(N, make_event(t + delta_t/5, 'Send_Packet', ID, datos_paquete));
        end
        Set_Start_Clock(t + delta_t + get_random_number(random_range));           % encolar la tarea de nuevo
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

function b=Set_Start_Clock(alarm_time);
global ID
clock.type = 'periodic_ant_send';
prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));


% function b=Set_Flood_Clock(alarm_time);
% global ID
% clock.type = 'spantree_flood';
% prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));

function PrintMessage(msg)
global ID
prowler('TextMessage', ID, msg)


function r = get_random_number(limits)
r = limits(1) + (limits(2) - limits(1))*rand;


% function discover_ant_neighbors()
% clock.destination = 0;
% clock.msgID = 0;
% status = mainAntNet_layer(N, make_event(t + delta_t/5, 'Send_Packet', ID, datos_paquete));


% function LED(msg)
% global ID
% prowler('LED', ID, msg)

% function DrawLine(command, varargin)
% switch lower(command)
% case 'line'
%     prowler('DrawLine', varargin{:})
% case 'arrow'
%     prowler('DrawArrow', varargin{:})
% case 'delete'
%     prowler('DrawDelete', varargin{:})
% otherwise
%     error('Bad command for DrawLine.')
% end