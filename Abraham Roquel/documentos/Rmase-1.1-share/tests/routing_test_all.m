function [latency, throughput, lossrate, succrate, energy, energy_var, packet_sent] = test(varargin)

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

% Written by Lukas D. Kuhn, lukas.kuhn@parc.com
% Last modified: May 27, 2004  by YZ

global LATENCY THROUGHPUT LOSSRATE SUCCRATE ENERGY ENERGY_VAR PACKET_SENT

Max_Sim_Time = varargin{1};
Number_of_Runs = varargin{2};
if (length(varargin)>2)
    Time_Interval = varargin{3};
else
    Time_Interval = 1;
end

sim_params('set_app', 'LogInterval', Time_Interval);
sim_params('set', 'STOP_SIM_TIME', Max_Sim_Time*40000);

for (inum=1:Number_of_Runs)
    prowler('Init');
    disp(['current run: ' num2str(inum)])
    prowler('StartSimulation');
    
    latency(inum, :) = LATENCY;
    throughput(inum, :) = THROUGHPUT;
    lossrate(inum, :) = LOSSRATE;
    energy(inum, :) = ENERGY;
    energy_var(inum, :) = ENERGY_VAR;
    packet_sent(inum, :) = PACKET_SENT;
    succrate(inum, :) = SUCCRATE;
    
end




