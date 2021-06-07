function status = stats_layer(N, S)

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

global TIME LATENCY THROUGHPUT LOSSRATE SUCCRATE ENERGY ENERGY_VAR PACKET_SENT

persistent logInterval
persistent lastTotalSent
persistent bittime
persistent initTime

switch event
case 'Init_Application'
    if (ix==1) 
        TIME = [];
        LATENCY=[];
        THROUGHPUT=[];
        LOSSRATE=[];
        SUCCRATE=[];
        ENERGY=[];
        ENERGY_VAR=[];
        PACKET_SENT=[];
        lastTotalSent = 0;
        
        bittime = sim_params('get','BIT_TIME');
        initTime = sim_params('get_app', 'InitTime');
        if(isempty(initTime)) initTime = 0; end
        initTime = initTime/bittime;
        logInterval = sim_params('get_app', 'LogInterval');
        if (isempty(logInterval)) logInterval = 1; end
        logInterval = logInterval/bittime;
        Set_Log_Clock(initTime);
    end
case 'Clock_Tick' 
    try type = data.type; catch type = 'none'; end        
    if(strcmpi(type,'log'))      
        sys_stat = permstats;
        TIME = [TIME, (t-initTime)*bittime];
        LATENCY = [LATENCY, sys_stat.Average_Delays];
        THROUGHPUT = [THROUGHPUT, sys_stat.Total_Throughput];
        LOSSRATE = [LOSSRATE, sys_stat.Average_LossRate];
        ENERGY = [ENERGY, sys_stat.Total_Energy_Used];
        ENERGY_VAR= [ENERGY_VAR, sys_stat.Energy_Used_diff];
        PACKET_SENT = [PACKET_SENT, sys_stat.Total_Packet_Sent];
        if (sys_stat.Total_Packet_Sent == lastTotalSent) succRate = 0;
        else succRate = sys_stat.Total_Packet_Received/(sys_stat.Total_Packet_Sent-lastTotalSent);
        end
        SUCCRATE = [SUCCRATE, succRate];       
        Set_Log_Clock(logInterval);
        
        disp(['sim time: ' num2str(t*bittime) '---------------'])
        %last interval
        disp(['latency: ' num2str(sys_stat.Average_Delays)])
        disp(['throughput: ' num2str(sys_stat.Total_Throughput)])
        disp(['lossrate: ' num2str(sys_stat.Average_LossRate)])
        disp(['succrate: ' num2str(succRate)])
        %total to this time
        disp(['energy: ' num2str(sys_stat.Total_Energy_Used)])
        disp(['energy_var: ' num2str(sys_stat.Energy_Used_diff)])
        disp(['packet_sent: ' num2str(sys_stat.Total_Packet_Sent)])      
        
        %log to file as well
        [tag err]= sprintf(' %d\t %d/%d\t %.3f\t %.3f\t %.3f\t %d',...
            t*bittime,sys_stat.Total_Packet_Received,sys_stat.Total_Packet_Sent,...
            succRate,sys_stat.Total_Energy_Used,sys_stat.Average_Delays,sys_stat.Control_Packets);
        logevent('Results',[],tag);
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

function b=Set_Log_Clock(interval);
global ID t
clock.type = 'log';
prowler('InsertEvents2Q', make_event(t+interval, 'Clock_Tick', ID, clock));