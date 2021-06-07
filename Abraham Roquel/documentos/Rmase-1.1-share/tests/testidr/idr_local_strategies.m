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

if (length(varargin)>2)
    dir = varargin{3};
else
    dir = '.';    
end

%greedy
sim_params('set_app', 'IDRType', 'greedy');
run_idr(dir,'/greedy.txt', Number_of_Runs, Number_of_Packets);

%learning
sim_params('set_app', 'IDRType', 'learning');
run_idr(dir,'/learning.txt', Number_of_Runs, Number_of_Packets);
% 
%probabilistic
% sim_params('set_app', 'IDRType', 'probabilistic');
% run_idr(dir,'/probabilistic.txt', Number_of_Runs, Number_of_Packets);