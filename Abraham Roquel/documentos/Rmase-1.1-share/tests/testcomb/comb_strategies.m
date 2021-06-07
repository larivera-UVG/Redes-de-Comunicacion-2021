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

global TIME

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

sim_params('set_app', 'DuplicationLength', 0);
sim_params('set_app', 'CombSpace', 1);

[delays, throughput, lossrate, succrate, energy, energy_var, sent] = routing_test(Max_Sim_Time, Number_of_Runs, Time_Interval);
X=[TIME;delays;throughput;lossrate;succrate;energy;energy_var;sent];
filename = [dir, '/s1.txt'];
fid = fopen(filename, 'w');
fprintf(fid, '%d %f %f %f %f %d %f %d\n', X);
fclose(fid);

sim_params('set_app', 'DuplicationLength', 1);
sim_params('set_app', 'CombSpace', 3);

[delays, throughput, lossrate, succrate, energy, energy_var, sent] = routing_test(Max_Sim_Time, Number_of_Runs, Time_Interval);
X=[TIME;delays;throughput;lossrate;succrate;energy;energy_var;sent];
filename = [dir, '/s3.txt'];
fid = fopen(filename, 'w');
fprintf(fid, '%d %f %f %f %f %d %f %d\n', X);
fclose(fid);

sim_params('set_app', 'DuplicationLength', 2);
sim_params('set_app', 'CombSpace', 5);

[delays, throughput, lossrate, succrate, energy, energy_var, sent] = routing_test(Max_Sim_Time, Number_of_Runs, Time_Interval);
X=[TIME;delays;throughput;lossrate;succrate;energy;energy_var;sent];
filename = [dir, '/s5.txt'];
fid = fopen(filename, 'w');
fprintf(fid, '%d %f %f %f %f %d %f %d\n', X);
fclose(fid);

sim_params('set_app', 'DuplicationLength', 3);
sim_params('set_app', 'CombSpace', 7);

[delays, throughput, lossrate, succrate, energy, energy_var, sent] = routing_test(Max_Sim_Time, Number_of_Runs, Time_Interval);
X=[TIME;delays;throughput;lossrate;succrate;energy;energy_var;sent];
filename = [dir, '/s7.txt'];
fid = fopen(filename, 'w');
fprintf(fid, '%d %f %f %f %f %d %f %d\n', X);
fclose(fid);