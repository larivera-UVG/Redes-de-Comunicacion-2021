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
% Last modified: Oct. 7, 2004 by YZ

Number_of_Runs = varargin{1};
Number_of_Packets = varargin{2};

if (length(varargin)>1)
    dir = varargin{3};
else
    dir = '.';    
end

%1. shortest path with known hops
sim_params('set_app', 'IDRMaxHops', 3);
set_layers({'mac', 'neighborhood', 'sensor', 'check_duplicate', 'idr_remote', 'init_backward', 'idr_stats', 'app', 'stats', 'log'});
run_idr(dir,'/shortestpath.txt', Number_of_Runs, Number_of_Packets);

%2. maximum 20 hops
sim_params('set_app', 'IDRMaxHops', 20);
set_layers({'mac', 'neighborhood', 'sensor', 'check_duplicate', 'idr_remote', 'init_backward', 'idr_stats', 'app', 'stats', 'log'});
run_idr(dir,'/idr.txt', Number_of_Runs, Number_of_Packets);

%2. maximum 20 hops, with path estimate
% sim_params('set_app', 'KnownLocation', 1);
% sim_params('set_app', 'IDRMaxHops', 20);
% set_layers({'mac', 'neighborhood', 'sensor', 'check_duplicate', 'idr_remote', 'init_backward', 'idr_stats', 'app', 'stats', 'log'});
% run_idr(dir,'/idrp.txt', Number_of_Runs, Number_of_Packets);

%3. same as before, without dest info
%sim_params('set_app', 'KnownLocation', 1);
sim_params('set_app', 'IDRMaxHops', 20);
set_layers({'mac', 'neighborhood', 'sensor', 'idr_remote', 'init_hello', 'idr_stats', 'app', 'stats', 'log'});
% sim_params('set_app', 'DestFunc', 'geo_dest');
run_idr(dir,'/idru.txt', Number_of_Runs, Number_of_Packets);
