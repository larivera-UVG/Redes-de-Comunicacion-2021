function status = sensor_layer(N, S)

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

%this layer is the application for information-directed routing
%at the initialization, sensor types and parameters are defined
%each packet includes a belief state
%after receiving a packet, belief state is updated
%a target is also simulated at this layer

global typeProb

persistent beliefDx beliefDy
persistent maxX maxY minX minY
persistent threshold
persistent v_max
persistent asigma alo ahi 
persistent thetaStd
persistent A simSigma
global distanceThreshold

persistent bittime initTime

persistent target targetSpeed randTargetSpeed simInterval

global INIT_BELIEF

global DESTINATIONS
global NEIGHBORS
global CURRENT_BELIEF
global CURRENT_TARGET
global BELIEF_HANDLES

switch event
case 'Init_Application'   
    if (ix==1) %only need to compute it once
        typeProb = sim_params('get_app', 'DOASensorProb'); %percentage of DOA type
        if (isempty(typeProb)) typeProb = 0.3; end
        beliefDx = sim_params('get_app', 'BeliefDx');
        if (isempty(beliefDx)) beliefDx = 0.2; end
        beliefDy = sim_params('get_app', 'BeliefDy');
        if (isempty(beliefDy)) beliefDy = 0.2; end
        [minX maxX minY maxY] = network_size;
        threshold = 0.9/(((maxX-minX)/beliefDx)*((maxY-minY)/beliefDy));
        v_max = sim_params('get_app', 'MaxTargetSpeedBelieved');
        if (isempty(v_max)) v_max = 0; end
        NearRange = sim_params('get_app', 'NearRange');
        if (isempty(NearRange)) NearRange= 0.5; end
        FarRange = sim_params('get_app', 'FarRange');
        if (isempty(FarRange)) FarRange= 2.5; end
        AngleStd = sim_params('get_app', 'AngleStd');
        if (isempty(AngleStd)) AngleStd= 10; end
        R_max = sim_params('get_app', 'R_max');
        if (isempty(R_max)) R_max = 7; end
        beliefD = min(beliefDx, beliefDy);
        [r, thetaStd]= SetDOARange(NearRange, FarRange, R_max, AngleStd, beliefD);
        alo = sim_params('get_app', 'A_LO');
        if (isempty(alo)) alo = 0; end
        ahi = sim_params('get_app', 'A_HI');
        if (isempty(ahi)) ahi = 2; end
        asigma = sim_params('get_app', 'A_Sigma');
        if (isempty(asigma)) asigma = 0.1; end
        simSigma = asigma/2;
        A = sim_params('get_app', 'A');
        if (isempty(A)) A = 1; end
        
        distanceThreshold = min(beliefDx, beliefDy)/10;
        target = sim_params('get_app', 'TargetInit');     
        if (isempty(target)) target = [(maxX+minX)/2, 0]; end
        CURRENT_TARGET = target;
        targetSpeed = sim_params('get_app', 'TargetSpeed');
        if (isempty(targetSpeed)) targetSpeed = [0, 0]; end
        randTargetSpeed = sim_params('get_app', 'RandTargetSpeed');
        if (isempty(randTargetSpeed)) randTargetSpeed = 0; end
        maxSpeed = max(targetSpeed)+randTargetSpeed;
        bittime = sim_params('get', 'BIT_TIME');
        simInterval = inf;
        if (maxSpeed>0)
            simInterval = min(beliefDx, beliefDy)/maxSpeed;
            targetSpeed = targetSpeed*simInterval;
            randTargetSpeed = randTargetSpeed*simInterval;
            simInterval = simInterval/bittime;
        end
        
        initTime = sim_params('get_app', 'InitTime');
        if (isempty(initTime)) initTime = 0; end
        initTime = initTime/bittime;
        
        INIT_BELIEF = initBelief(minX, maxX, minY, maxY, beliefDx, beliefDy, threshold);
        CURRENT_BELIEF = INIT_BELIEF;
        
        Set_Target_Clock(simInterval);
        
        BELIEF_HANDLES = [];
    end % end of compute once for all
    
    memory.sensor.pos = [ATTRIBUTES{ID}.x ATTRIBUTES{ID}.y];
    memory.sensor.kind = 0; % 0 for amplitude sensor, 1 for PIR sensor, 2 for DOA
    memory.sensor.sigma = asigma;% Noise standard deviation for amplitude sensor
    memory.sensor.alpha = 2;
    memory.sensor.LowA = alo;
    memory.sensor.HighA = ahi;
    memory.sensor.alpha1 = 10;
    memory.sensor.alpha2 = 1;
    memory.sensor.theta= thetaStd; 
    if (rand < typeProb) 
        memory.sensor.kind = 2; 
        LED('yellow on');
    end %DOA
    
    ATTRIBUTES{ID}.z = 0;
    ATTRIBUTES{ID}.r = 0;
    ATTRIBUTES{ID}.belief = INIT_BELIEF;
    ATTRIBUTES{ID}.nsensors = [];
    
    if (~memory.sensor.kind) %only for amplitude sensors
        Set_Sensor_Clock(simInterval);
        ATTRIBUTES{ID}.r = simulateZ(memory.sensor, target, distanceThreshold, A, simSigma);
    end
    
case 'Packet_Sent'
     
    
case 'Send_Packet'
    try msgID = data.msgID; catch msgID = 0; end
    try forward = data.forward; catch forward = 0; end
    
    
    if (msgID >= 0) %events from any node
        if (~forward) 
            ATTRIBUTES{ID}.belief = INIT_BELIEF; 
            [data.belief, data.mse, data.beliefSize] = ...
                addNewMeasure(ATTRIBUTES{ID}.belief, memory.sensor, target, distanceThreshold, threshold, A, simSigma);
            data.beliefTime = t;
            ATTRIBUTES{ID}.belief = data.belief;
            CURRENT_BELIEF = data.belief;
        end
    end
    
    if (msgID < 0) %initial neighborhood, broadcast sensor information
        data.sensor = memory.sensor;
    end
    
case 'Packet_Received'
    try msgID = data.data.msgID; catch msgID = 0; end
    try address = data.data.address; catch address = 0; end
    
    if ((msgID >= 0) && (address==ID))
        crtBelief = data.data.belief;
        dt = (t - data.data.beliefTime)*bittime; %second
        predictedBelief = gridPredictBeliefUniform(crtBelief, dt, threshold, v_max);
        predictedBelief = scaleBelief(predictedBelief, threshold);
        
        [data.data.belief, data.data.mse, data.data.beliefSize] = ...
            addNewMeasure(predictedBelief, memory.sensor, target, distanceThreshold, threshold, A, simSigma);
        
        ATTRIBUTES{ID}.belief = data.data.belief;
        CURRENT_BELIEF = data.data.belief;
        
        data.data.beliefTime = t;
        
    end
    
    if (msgID < 0) %initialization
        nID = find(NEIGHBORS{ID}==data.data.from);
        if (~isempty(nID))
            ATTRIBUTES{ID}.nsensors{nID} = data.data.sensor;
        end
    end
    
case 'Clock_Tick'    
    if (strcmp(data.type, 'target_sim'))
        pass = 0;
        Set_Target_Clock(t+simInterval);
        if (t>initTime) %start simulate motion after initTime           
            target = target + 2*(rand(1,2)-0.5).*randTargetSpeed+targetSpeed;
            CURRENT_TARGET = target;
        end
    end   
    if (strcmp(data.type, 'sensor_reading'))
        Set_Sensor_Clock(t+simInterval);
        ATTRIBUTES{ID}.r = simulateZ(memory.sensor, target, distanceThreshold, A, simSigma);
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

%find bounding box of topology
function [minx, maxx, miny, maxy]=network_size

topology = prowler('GetTopologyInfo');

minx=min(topology(:,1));
maxx=max(topology(:,1));
miny=min(topology(:,2));
maxy=max(topology(:,2));

function crtBelief = initBelief(minx, maxx, miny, maxy, dx, dy, threshold)

xv = minx:dx:maxx;
yv = miny:dy:maxy;
[x_mesh y_mesh] = meshgrid(0:length(xv)-1,0:length(yv)-1);
x = x_mesh(:)'; y = y_mesh(:)';

P = ones(length(x),1);
P = P/sum(P(:));
index  = find(P>threshold); % Currently, the threshold is a little bit problematic.
crtBelief.mass = P(index);
crtBelief.mass = crtBelief.mass/sum(crtBelief.mass(:));
crtBelief.x = x(index)';
crtBelief.y = y(index)';
crtBelief.display = zeros(length(yv), length(xv));
crtBelief.x_max = length(xv)-1;
crtBelief.y_max = length(yv)-1;
crtBelief.dx = dx;
crtBelief.dy = dy;

for i = 1:length(index)
    crtBelief.display(y(index(i))+1, x(index(i))+1) = P(index(i));
end

function newBelief = scaleBelief(belief, threshold)

newBelief = belief;
        
nonTrivialIndex  = find(newBelief.mass>threshold);  
newBelief.x = newBelief.x(nonTrivialIndex);
newBelief.y = newBelief.y(nonTrivialIndex);
newBelief.mass = newBelief.mass(nonTrivialIndex);
newBelief.mass = newBelief.mass/sum(newBelief.mass(:)); 

function b=Set_Target_Clock(alarm_time);
global ID
clock.type = 'target_sim';
prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));

function b=Set_Sensor_Clock(alarm_time);
global ID
clock.type = 'sensor_reading';
prowler('InsertEvents2Q', make_event(alarm_time, 'Clock_Tick', ID, clock));

function [updatedBelief, mse, beliefSize] = addNewMeasure(predictedBelief, sensor, target, distanceThreshold, threshold, A, simSigma)
global ID

z= simulateZ(sensor, target, distanceThreshold, A, simSigma);
ATTRIBUTES{ID}.z = z;
beliefDx = predictedBelief.dx;
beliefDy = predictedBelief.dy;
d = min(beliefDx, beliefDy);
marginalLikelihood = ...
    calculateLikelihoodGeneral(sensor, z,...
    [predictedBelief.x]'*beliefDx, [predictedBelief.y]'*beliefDy, distanceThreshold, d); 

updatedBelief = predictedBelief;

newLikelihood = marginalLikelihood';     
if (sum(newLikelihood(:)))
    newLikelihood =newLikelihood/sum(newLikelihood(:));

	updatedBelief.mass = newLikelihood.*predictedBelief.mass;            
	updatedBelief.mass = updatedBelief.mass/sum(updatedBelief.mass(:));  
	
	updatedBelief = scaleBelief(updatedBelief, threshold);
	updatedBelief.display = zeros(size(updatedBelief.display));
    
else
    updatedBelief = predictedBelief;

end

for a = 1:length(updatedBelief.x)
    updatedBelief.display(updatedBelief.y(a)+1, updatedBelief.x(a)+1) = ...
    updatedBelief.mass(a);
end

[mean_belief, var_belief, edist] =  ...
            computeMeanCovFromPmf(updatedBelief.x*beliefDx, updatedBelief.y*beliefDy, updatedBelief.mass);
mse = sqrt( (mean_belief(1)-target(1))^2+(mean_belief(2)-target(2))^2 );
        % belief state size
beliefSize = sqrt(length(updatedBelief.mass))*max(beliefDx, beliefDy);