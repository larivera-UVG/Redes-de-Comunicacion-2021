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

% VARIABLES GLOBALES: SE MANTINENE EN CADA LLAMADA Y ACCESIBLES FUERA DEL SCOPE DE LA FUNCI�N
global NEIGHBORS
global DESTINATIONS
global SOURCES


% VARIABLES PERSISTENTES: SE MANTIENEN EN CADA LLAMADA A LA FUNCI�N
persistent source_rate  % define la tasa de transmisión de salida 
persistent delta_t      % intervalo de tiempo para enviar hormigas de forward hacia un desitno (constante)
persistent w            % tamaño de la ventana de observación (Wbest sobre w observaciones) (constante)
persistent varsigma     % parámetro para actualización de u_id, sigma_id
persistent c_w          % parámetro para definir ventana de observación de w_max = 5*c_w / varsigma
persistent alpha_p      % parámetro para medir la importancia de eta_ij (medida de la cola en nodo i hacia j)
persistent max_life     % máximo número de saltos de hormiga de forward antes de ser descartada
persistent r            % variable de reinforcement (qué tan buena es una ruta)
persistent c1           % peso de la calidad del trip time actual en comparación con Wbest para r_p
persistent c2           % peso de la calidad del trip time actual en comparación con el intervalo de confianza
persistent z_i          % parámetro para escalar la cota superior del intervalo de confianza z_i = 1 / sqrt(1 - v_i)
persistent v_i          % parámetro para definir el intervalo de confiaza (mientras más cercano a 1, más grande)
persistent discover_message_id  % id para los mensajes para descubrir vecinos
persistent possible_message_ids % arreglo que contiene los IDs de mensajes v�lidos
persistent random_range         % arreglo que contiene l�mites de tiempo aleatorio para agendar tareas
persistent generic_message_id   % id para mensajes gen�ricos (hello)


switch event
case 'Init_Application'
    % inicialización de parámetros
    if (ix==1)
        source_rate = 100e3;                        % supongamos un ancho de banda de 100 kbps
        delta_t = 100e-3;                           % cada 100 ms enviamos una hormiga de forward
        w = 10;
        varsigma = 0.01;
        c_w = 1;
        alpha_p = 0.5;
        max_life = 50;
        c1 = 0.5;
        c2 = 0.5;
        v_i = 0.9;
        z_i = 1 / sqrt(1 - v_i);
        possible_message_ids = [];
        discover_message_id = 1;
        possible_message_ids(end+1) = discover_message_id;
        generic_message_id = 2;
        possible_message_ids(end+1) = generic_message_id;
        random_range = [0 50e-3];                   % 0 a 50 ms
    end

    % reserva de memoria: espacio para la media, la varianza, el mejor tiempo y la matriz de feromonas
    memory = struct('tt_mean', [], 'tt_variance', [], 'tt_best', [], 'T_matrix', []);
    % 

    % print del ID
    PrintMessage(sprintf("a_%d", ID));

    % agendar tarea incial
    Set_Start_Clock(t + delta_t + get_random_number(random_range));

case 'Send_Packet'
    try msgID = data.msgID; catch msgID = -1; end       % leer el msgID del paquete que se quiere enviar
    if (ismember(msgID, possible_message_ids))          % validamos que el ID sea v�lido (esperado)
        logevent(sprintf("Message sent from %d to %d", ID, data.address));
    else
        pass = 0; % si no tiene sentido botar el paquete
    end

case 'Packet_Received'
    try msgID = data.msgID; catch msgID = -1; end
    if (msgID == discover_message_id)
        pass = 0;   % si el mensaje es de un paquete de hello no es necesario subirlo a capa de aplicaci�n
    end
    
case 'Clock_Tick'
    try type = data.type; catch type = 'none'; end      %determinar qué tipo de tarea es tiempo de hacer
    if (strcmp(type, 'periodic_ant_send'))
        if(isempty(NEIGHBORS{ID}))                      % si no tenemos vecinos encolar env�o broadcast
            datos_paquete.msgID = discover_message_id;
            datos_paquete.address = 0;                  % 0  es la direcci�n de broadcast
            status = mainAntNet_layer(N, make_event(t + delta_t/5, 'Send_Packet', ID, datos_paquete));
        else
            datos_paquete.msgID = generic_message_id;   % mensaje de hello
            datos_paquete.address = randsample(NEIGHBORS{ID});  %vecino aleatorio (arreglar la distribuci�n)
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


%funci�n para agendar el env�o peri�dico de hormigas
function b=Set_Start_Clock(alarm_time);
global ID
clock.type = 'periodic_ant_send';
prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));


% function b=Set_Flood_Clock(alarm_time);
% global ID
% clock.type = 'spantree_flood';
% prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));

%funci�n para mostrar un mensaje en pantalla
function PrintMessage(msg)
global ID
prowler('TextMessage', ID, msg)

%obtener un valor aleatorio entre dos l�mites dados
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