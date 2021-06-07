function out = routing_strategies(varargin)

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

% Written by Ying Zhang yzhang@parc.com
% Last modified: Dec. 22, 2003  by YZ
% Last modified: May 25, 2004 by GLX

Max_Sim_Time = varargin{1};
Number_of_Runs = varargin{2};
if (length(varargin)>2)
    Time_Interval = varargin{3};
else
    Time_Interval = 1;    
end

if (length(varargin)>3)
    dir = varargin{4};
else
    dir = '.';    
end

%UV
set_layers({'mac', 'aggregate_queue', 'check_duplicate', 'routing2Dmany', 'flood2Dgrad', 'app', 'stats', 'log'});
run_routing(dir,'/grad_floodagg.txt',Max_Sim_Time, Number_of_Runs, Time_Interval);

%UCB
set_layers({'mac', 'neighborhood', 'check_duplicate','mint_routing','app', 'stats', 'log'});
run_routing(dir,'/mint_routing.txt',Max_Sim_Time, Number_of_Runs, Time_Interval);

%OSU
set_layers({'mac', 'neighborhood', 'check_duplicate', 'grid_routing', 'app', 'stats', 'log'});
run_routing(dir,'/grid_routing.txt',Max_Sim_Time, Number_of_Runs, Time_Interval);

%ND
set_layers({'mac', 'neighborhood', 'check_duplicate', 'nd_hood','nd_broker','app', 'stats', 'log'});
run_routing(dir,'/nd.txt',Max_Sim_Time, Number_of_Runs, Time_Interval);

%UVA
set_layers({'mac', 'neighborhood', 'check_duplicate', 'SD', 'backbone','app', 'stats', 'log'});
run_routing(dir,'/backbone.txt',Max_Sim_Time, Number_of_Runs, Time_Interval);

%PARC search
set_layers({'mac', 'neighborhood', 'confirm_transmit','check_duplicate', 'mcbr_search','init_backward','app', 'stats', 'log'});
run_routing(dir,'/mcbr_search.txt',Max_Sim_Time, Number_of_Runs, Time_Interval);

%PARC flood
set_layers({'mac', 'neighborhood', 'delay_transmit','check_duplicate', 'mcbr_flood','init_backward','app', 'stats', 'log'});
run_routing(dir,'/mcbr_flood.txt',Max_Sim_Time, Number_of_Runs, Time_Interval);

%PARC tree
set_layers({'mac', 'neighborhood', 'confirm_transmit','check_duplicate', 'mcbr_tree','init_backward','app', 'stats', 'log'});
run_routing(dir,'/mcbr_tree.txt',Max_Sim_Time, Number_of_Runs, Time_Interval);

%AODV
set_layers({'mac', 'neighborhood','confirm_transmit','check_duplicate','aodv_routing','app', 'stats', 'log'});
run_routing(dir,'/aodv.txt',Max_Sim_Time, Number_of_Runs, Time_Interval);

%PARC converge: can be tested for LIS and SL for comparison
set_layers({'mac', 'transmit_queue', 'neighborhood', 'delay_transmit', 'converge_control', 'init_backward', 'app', 'stats', 'log'});
run_routing(dir,'/convcon.txt',Max_Sim_Time, Number_of_Runs, Time_Interval);

