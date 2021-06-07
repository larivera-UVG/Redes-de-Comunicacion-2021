function varargout=permstats(varargin)
% PERMSTATS Performance statistics using the last simulation results
% [sys_stat, node_stat]=permstats

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

global RECEIVED_DELAYS
global RECEIVED_LOST
global RECEIVED_TIMES
global ATTRIBUTES
global SENT_TIMES

global Packet_Sent_Count TOTAL_SEND  routePkts

[topology, mote_IDs]=prowler('GetTopologyInfo');
N=length(mote_IDs);
initTime=sim_params('get_app', 'InitTime');
if (isempty(initTime)) initTime=0; end
if (length(varargin)>0) initTime = varargin{1}; end
bittime = sim_params('get', 'BIT_TIME');
initTime = initTime/bittime;

try t = SENT_TIMES(length(SENT_TIMES)); catch t = 0; end

for i=1:N
    node_stat(i)=struct(...
        'Average_Delays',              0,  ...
        'Variance_Delays',             0,  ...
        'Average_Throughput',          0,  ...
        'Average_LossRate',            0,  ...
        'Received_Packets',            0,  ...
        'Energy_Used',                 0);
    id = mote_IDs(i);
    try last_received = RECEIVED_TIMES{id}(length(RECEIVED_TIMES{id}));
    catch last_received = 0; end
    if (t<last_received) 
        t = last_received; 
    end
    if (length(varargin)>1) t = varargin{2}/bittime; end
end

for i=1:N
    id = mote_IDs(i);
    
    indexes = 1:length(RECEIVED_TIMES{id});

    if (length(varargin)==1)
        indexes = find(RECEIVED_TIMES{id}*bittime >= varargin{1});
    elseif (length(varargin)==2)
        indexes = find((RECEIVED_TIMES{id}*bittime >= varargin{1})&(RECEIVED_TIMES{id}*bittime <= varargin{2}));
    end
    
    if (isempty(indexes))
        node_stat(i).Average_Delays = 0;
        node_stat(i).Variance_Delays = 0;
        node_stat(i).Average_Throughput = 0;
        node_stat(i).Average_LossRate = 0;
        node_stat(i).Received_Packets = 0;
    else
        totalReceived = length(indexes);
        node_stat(i).Average_Delays = mean(RECEIVED_DELAYS{id}(indexes)*bittime);
        node_stat(i).Variance_Delays = var(RECEIVED_DELAYS{id}(indexes)*bittime);
        totalLost = sum(RECEIVED_LOST{id}(indexes));
        node_stat(i).Average_LossRate = totalLost/(totalLost+totalReceived);
        node_stat(i).Received_Packets = totalReceived;
        if (t<=initTime)node_stat(i).Average_Throughput=0;
        else
            node_stat(i).Average_Throughput = totalReceived/(t-initTime)/bittime;
        end
    end
    node_stat(i).Energy_Used = ATTRIBUTES{id}.usedPower;
end

sys_stat=struct(...
        'Average_Delays',              0,  ...
        'Variance_Delays',             0,  ...
        'Total_Throughput',            0,  ...
        'Average_LossRate',            0,  ...
        'Total_Packet_Received',       0,  ...
        'Total_Energy_Used',           0,  ...
        'Energy_Used_diff',            0,  ...
        'Total_Packet_Sent',           0 ...
        );

Total_Energy_Used_sq = 0;
nOfD = 0;
for i=1:N
    if (node_stat(i).Average_Delays>0)
        nOfD = nOfD + 1;
        sys_stat.Average_Delays              = ...
            sys_stat.Average_Delays + node_stat(i).Average_Delays;
        sys_stat.Variance_Delays              = ...
            sys_stat.Variance_Delays + node_stat(i).Variance_Delays;
        sys_stat.Total_Throughput          = ...
            sys_stat.Total_Throughput + node_stat(i).Average_Throughput;
        sys_stat.Average_LossRate = ...
            sys_stat.Average_LossRate + node_stat(i).Average_LossRate;
    end
    sys_stat.Total_Energy_Used = sys_stat.Total_Energy_Used + node_stat(i).Energy_Used;
    Total_Energy_Used_sq = Total_Energy_Used_sq + node_stat(i).Energy_Used^2;
    sys_stat.Total_Packet_Received = sys_stat.Total_Packet_Received+node_stat(i).Received_Packets;  
end

%sys_stat.Total_Packet_Sent = Packet_Sent_Count;
sys_stat.Total_Packet_Sent = TOTAL_SEND;
try 
    routePkts; 
    sys_stat.Control_Packets = routePkts; 
catch
    sys_stat.Control_Packets = 0; 
end

if (nOfD>0)
    sys_stat.Average_Delays = sys_stat.Average_Delays/nOfD;
    sys_stat.Variance_Delays = sys_stat.Variance_Delays/nOfD;
    sys_stat.Average_LossRate = sys_stat.Average_LossRate/nOfD;
end

sys_stat.Energy_Used_diff = Total_Energy_Used_sq/N - (sys_stat.Total_Energy_Used/N)^2;

if nargout==0
    disp(sys_stat)
else
    varargout={sys_stat, node_stat};
end