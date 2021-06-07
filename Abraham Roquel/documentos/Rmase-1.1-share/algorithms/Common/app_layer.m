function status = app_layer(N, S)

% generate an application instance

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

global SOURCES DESTINATIONS TOTAL_SEND

persistent rate
persistent rrate

persistent sourceNofPackets
persistent sourceType
persistent destinationType
persistent sourceSpeed
persistent destinationSpeed
persistent randSourceSpeed
persistent randDestinationSpeed
persistent simInterval
persistent bittime
persistent initTime
persistent traces

global sourceCenterType
global destinationCenterType

if ~strcmp(event, 'Init_Application') 
    
         if (DESTINATIONS(ID)) LED('green on');
         else LED('green off'); end
   
         if (SOURCES(ID)) LED('red on');
         else LED('red off'); end
end

switch event
case 'Init_Application'   
    if (ix==1) %only need to compute it once
        TOTAL_SEND = 0;
        
        rate = sim_params('get_app', 'SourceRate');
        if (isempty(rate)) rate = 4; end
        rrate = sim_params('get_app', 'RandSourceRate');
        if (isempty(rrate)) rrate = 0; end
        
        bittime = sim_params('get', 'BIT_TIME');
        
        sourceNofPackets = sim_params('get_app', 'SourceNofPackets');
        if (isempty(sourceNofPackets)) sourceNofPackets = Inf; end
        
        sourceType = sim_params('get_app', 'SourceType');
        if (isempty(sourceType)) sourceType = 'static'; end
        sourceSpeedX = sim_params('get_app', 'SourceSpeedX');
        if (isempty(sourceSpeedX)) sourceSpeedX = 0; end
        sourceSpeedY = sim_params('get_app', 'SourceSpeedY');
        if (isempty(sourceSpeedY)) sourceSpeedY = 0; end
        sourceSpeed = [sourceSpeedX, sourceSpeedY];
        destinationType = sim_params('get_app', 'DestinationType');
        if (isempty(destinationType)) destinationType = 'static'; end
        destinationSpeedX = sim_params('get_app', 'DestinationSpeedX');
        if (isempty(destinationSpeedX)) destinationSpeedX = 0; end
        destinationSpeedY = sim_params('get_app', 'DestinationSpeedY');
        if (isempty(destinationSpeedY)) destinationSpeedY = 0; end
        destinationSpeed = [destinationSpeedX, destinationSpeedY];
        
        randSourceSpeed = sim_params('get_app', 'RandSourceSpeed');
        if (isempty(randSourceSpeed)) randSourceSpeed = 0; end
        randDestinationSpeed = sim_params('get_app', 'RandDestinationSpeed');
        if (isempty(randDestinationSpeed)) randDestinationSpeed = 0; end
        
        sourceCenterType = sim_params('get_app', 'SourceCenterType');
        if (isempty(sourceCenterType)) sourceCenterType = 'random'; end
        destinationCenterType = sim_params('get_app', 'DestinationCenterType');
        if (isempty(destinationCenterType)) destinationCenterType = 'random'; end

%-----------calculate simulation speed instead

        maxSpeedS = 0;
        maxSpeedD = 0;
        if (~strcmp(sourceType, 'static'))
            maxSpeedS = max(abs(sourceSpeed));
        end
        if (~strcmp(destinationType, 'static'))
            maxSpeedD = max(abs(destinationSpeed));
        end
        maxSpeed = max([maxSpeedS, maxSpeedD]);
        
        if (maxSpeed == 0) simInterval = Inf; 
        else simInterval = 0.1/maxSpeed; end
        
%-------end of calculation
        
        sourceSpeed = sourceSpeed*simInterval;
        destinationSpeed = destinationSpeed*simInterval;
        randSourceSpeed = randSourceSpeed*simInterval;
        randDestinationSpeed = randDestinationSpeed*simInterval;
        
        simInterval = simInterval/bittime;
        
        initTime = sim_params('get_app', 'InitTime');
        if (isempty(initTime)) initTime = 0; end
        
        % one may set a trace file from GUI       
        useTraceFile = sim_params('get_app', 'UseTraceFile');
        if (isempty(useTraceFile)) useTraceFile = 0; end
        
        traces = [];             
        if (useTraceFile)
            fileName = sim_params('get_app', 'TraceFileName');
            if (~isempty(fileName))
                try 
%                     traces = load(fileName); 
%                     traces(:, 4) = (traces(:, 4) ./ 1000000) .* 31.25; % 1 jiffie = 31.25 * realpow(10, -6) seconds
%                     traces(:, 4) = traces(:, 4) - min(traces(:, 4)) + initTime;   % allow initTime seconds for the application initialization 
                    traces = feval(fileName); %traces(:,1)-> ID, traces(:,2)-> send time (in second)
                    traces(:, 2) = traces(:, 2) - min(traces(:, 2)) + initTime; % allow initTime seconds for the application initialization 
                catch 
                    disp('wrong file name for traces') 
                end
            else 
                disp('no file name for traces')
            end
        end
        %end of trace file
        
        Set_SourceDestination(traces);
        
        normdist = sim_params('get_app', 'PairNorminalDist');
        randdist = sim_params('get_app', 'PairRandDist');
        if (isempty(normdist)) normdist = 0.5; end
        if (isempty(randdist)) randdist = 0.1; end
        check = sim_params('get_app', 'CheckSourceDest');
        if (isempty(check)) check = 1; end
        if (check && isempty(traces) && (strcmp(sourceCenterType, 'random') || strcmp(destinationCenterType, 'random')))
            count=0;
            while (~pair_satisfied(normdist, randdist) && (count<20))
                Set_SourceDestination(traces);
                count=count+1;
            end
            if (count==20) disp('cannot find source destination pair'); end
        end
                
        initTime = initTime/bittime; %bit time
        Set_Sim_Clock(simInterval);
   
    end % end of compute once for all
    
    memory.index=0;
    
    if (~isempty(traces)) %use trace file
        memory.myTrace = traces(find(traces(:, 1) == ID), :);
        memory.isSource = ~isempty(memory.myTrace); 
        SOURCES(ID) = 0;
        if memory.isSource
            PrintMessage('s');
            SOURCES(ID) = 1;
            memory.totalPackets = length(memory.myTrace);
            memory.packetPtr = 1; 
            %added by guoliang, we need rate information even when trace
            %file is used. The rate informatio will be encoded in every
            %packet sent by the application.
            memory.rate = ...
                size(memory.myTrace,1)/(max(memory.myTrace(:,2))-min(memory.myTrace(:,2)));
            Set_App_Clock(memory.myTrace(memory.packetPtr, 2)/bittime); % schedule the first packet to be sent
        end
    else %use generated traces        
        memory.totalPackets = sourceNofPackets;
        if (SOURCES(ID)) 
            PrintMessage('s'); 
            memory.rate = 1/bittime/(rate*(1+rrate*rand)); %variations between source nodes
            Set_App_Clock(memory.rate*rand+initTime); 
        end
    end    
    %PrintMessage(['id:', num2str(ID)]);
case 'Packet_Received'
    try msgID = data.data.msgID; catch msgID = 0; end
    try duplicated = data.duplicated; catch duplicated = 0; end
    if (~DESTINATIONS(ID) || msgID < 0 || duplicated)
        pass = 0;
    else %received data
        PrintMessage([num2str(data.data.value),',',num2str(data.data.source)]);
    end
case 'Clock_Tick'    
    if (strcmp(data.type, 'app_send')) 
        if (~isempty(traces)) %use trace file
            if (memory.isSource)
                SendData(memory.index, memory.rate); %myTrace(:, 3): sequence number
                memory.index = memory.index+1;
                memory.packetPtr = memory.packetPtr + 1;
                if memory.packetPtr <= memory.totalPackets
                    Set_App_Clock(memory.myTrace(memory.packetPtr, 2)/bittime); % schedule the next packet to be sent, if any
                end
            end
        else %use generated traces
            if (SOURCES(ID))
                memory.totalPackets = memory.totalPackets - 1;
                try memory.rate; catch memory.rate = 1/bittime/(rate*(1+rrate*rand)); end
                if (memory.totalPackets>0)
                    Set_App_Clock(t+memory.rate);
                end
                SendData(memory.index, 1/(bittime*memory.rate));
                memory.index = memory.index+1;
            end
        end
    end
    if (strcmp(data.type, 'app_sim'))
        Set_Sim_Clock(t+simInterval);
        if (t>initTime) %start simulate motion after initTime           
            if (strcmp(sourceType, 'mobile'))
                sID = find(SOURCES==1);
                set_mobile_motes(sID, 2*(rand(1,2)-0.5).*randSourceSpeed+sourceSpeed);
                
            elseif (strcmp(sourceType, 'dynamic'))
                sources = SOURCES;           
                SOURCES = Set_Source(2*(rand(1,2)-0.5).*randSourceSpeed+sourceSpeed);
                
                diff = SOURCES - sources;
                for id=find(diff>0)
                   clock.type = 'app_send';
                   memory.rate = 1/bittime/(rate*(1+rrate*rand));                 
                   prowler('InsertEvents2Q', make_event(t+memory.rate, 'Clock_Tick', id, clock)); 
                end
            end
            if (strcmp(destinationType, 'mobile'))
                dID = find(DESTINATIONS==1);
                set_mobile_motes(dID, 2*(rand(1,2)-0.5).*randDestinationSpeed+destinationSpeed);           
            elseif (strcmp(destinationType, 'dynamic'))
                destinations = DESTINATIONS;
                DESTINATIONS = Set_Destination(2*(rand(1,2)-0.5).*randDestinationSpeed+destinationSpeed);
            end
        end
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

function PrintMessage(msg)
global ID
prowler('TextMessage', ID, msg)

function LED(msg)
global ID
prowler('LED', ID, msg)

%set send rate

function b=Set_App_Clock(alarm_time);
global ID
clock.type = 'app_send';
prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));

%set simulation clock

function b=Set_Sim_Clock(alarm_time);
global ID
clock.type = 'app_sim';
prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));

%send data out

function status = SendData(varargin);
global ID t TOTAL_SEND
sdata.forward = 0;
sdata.value = varargin{1};
sdata.source = ID;
sdata.msgID = 0;
if (length(varargin)>2)
    sdata.seqID = varargin{3};
else 
    sdata.seqID = varargin{1};
    if (length(varargin)>1)
        sdata.rate = varargin{2};
    end
end
%if (length(varargin)<2) sdata.maxhops = Inf; else sdata.maxhops = varargin{2}; end
sdata.startTime = t;
PrintMessage(num2str(sdata.value));
N = find_layer('app');
status = app_layer(N, make_event(t, 'Send_Packet', ID, sdata));
TOTAL_SEND = TOTAL_SEND + 1;

%initial source destination pair

function Set_SourceDestination(traces)

global SOURCES DESTINATIONS

if (isempty(traces))
    SOURCES = Set_Source;
    N=0;
    while (~sum(SOURCES) && (N<10))
        prowler('PrintEvent', 'finding a source...');
        SOURCES = Set_Source;
        N=N+1;
    end
    if (N==10)
        disp('cannot find sources');
    end
end

DESTINATIONS = Set_Destination;
N=0;
while (~sum(DESTINATIONS) && (N<10))
    prowler('PrintEvent', 'finding a destination...');
    DESTINATIONS = Set_Destination;
    N=N+1;
end
if (N==10)
    disp('cannot find destinations');
end

%set source

function out = Set_Source(varargin);

persistent x y r p
global sourceCenterType

if (nargin==0)

    if (strcmp(sourceCenterType, 'random')) 
        [minx, maxx, miny, maxy]=network_size;
        x = rand*(maxx-minx)+minx;
        y = rand*(maxy-miny)+miny;
    else
        x = sim_params('get_app', 'SourceCenterX');
        y = sim_params('get_app', 'SourceCenterY');
        if isempty(x)
            x=0; 
        end
        if isempty(y)
            y=0; 
        end
    end

    r = sim_params('get_app', 'SourceRadius');
    if isempty(r); r=0.5; end

    p = sim_params('get_app', 'SourcePercentage');
    if isempty(p); p=1; end

else
    new_s = [x, y] + varargin{1};
    x = new_s(1);
    y = new_s(2);
    
end

out = set_static_motes([x,y], r, p);

unique = sim_params('get_app', 'SourceUnique');
if (isempty(unique)) unique = 1; end
if (unique) out = Set_Unique(out); end

%set destination

function out = Set_Destination(varargin);

persistent x y r p
global destinationCenterType

if (nargin==0)

    if (strcmp(destinationCenterType, 'random')) 
        [minx, maxx, miny, maxy]=network_size;
        x = rand*(maxx-minx)+minx;
        y = rand*(maxy-miny)+miny;
    else
        x = sim_params('get_app', 'DestinationCenterX');
        y = sim_params('get_app', 'DestinationCenterY');
        if isempty(x)
            x=0; 
        end
        if isempty(y)
            y=0; 
        end      
    end

    r = sim_params('get_app', 'DestinationRadius');
    if isempty(r); r=0.5; end

    p = sim_params('get_app', 'DestinationPercentage');
    if isempty(p); p=1; end
    
else
    new_d = [x, y] + varargin{1};
    x = new_d(1);
    y = new_d(2);
    
end

out = set_static_motes([x,y], r, p);

unique = sim_params('get_app', 'DestinationUnique');
if (isempty(unique)) unique = 1; end
if (unique) out = Set_Unique(out); end

%pick one mote with the least ID

function out = Set_Unique(in);

idx = find(in==1);

out = zeros(size(in));
if (~isempty(idx)) out(idx(1)) = 1; end

%find bounding box of topology
function [minx, maxx, miny, maxy]=network_size

topology = prowler('GetTopologyInfo');

minx=min(topology(:,1));
maxx=max(topology(:,1));
miny=min(topology(:,2));
maxy=max(topology(:,2));

