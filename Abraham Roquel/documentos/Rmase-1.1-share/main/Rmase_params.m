function param=params;
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

% Modified by Ying Zhang, yzhang@parc.com
% Last modified: Nov. 3, 2002

% Modified by Lukas D. Kuhn, lukas.kuhn@parc.com
% Last modified: Nov. 13, 2003

%##########################################################################
%## Using Parameters
%## By now there are three diffrent Types of User Interface Controls (uicontrol)   
%## implemented: text | pop up menu | checkbox
%##
%## all parameter using:
%## param(i).name       def. the name which describes the parameter
%##         .group      def. the group
%##         .type       def. the type (text | pop up menu | checkbox)
%##                          default value is text
%##
%## text:
%##         .default    def. the default value
%## pop up menu:
%##         .default    def. the default value
%##         .data       def. the list of values (char('value1','value2','value3',...))
%## checkbox:
%##         .default    def. if the checkbox is selected (=1) or not (=0)
%##         
%##
%##########################################################################

i=0;
param = [];

disp('Set Topology Parameters...');
[param, i] = topology_set_params(param, i, 1);
[param, i] = hole_set_params(param, i, 2);
disp('Set Transmission Parameters...');
[param, i] = transmission_set_params(param, i, 3);
disp('Set Source and Destination Parameters...');
[param, i] = source_set_params(param, i, 4);
[param, i] = dest_set_params(param, i, 5);
disp('Set Simulation Parameters');
[param, i] = sim_set_params(param, i, 6);
disp('Set Layers');
[param, i] = layer_set_params(param, i, 7);
disp('Set Common Parameters');
[param, i] = common_set_params(param, i, 8);

%modify this list if you like to put your routing parameters

gId = 8;

% gId = gId + 1;
% [param, i] = backbone_set_params(param, i, gId);
% 
% gId = gId + 1;
% [param, i] = grid_set_params(param, i, gId);
% 
% gId = gId + 1;
% [param, i] = grad_set_params(param, i, gId);
% 
% gId = gId + 1;
% [param, i] = mint_set_params(param, i, gId);
% 
% gId = gId + 1;
% [param, i] = nd_set_params(param, i, gId);

gId = gId + 1;
[param, i] = aodv_set_params(param, i, gId);

gId = gId + 1;
[param, i] = mcbr_set_params(param, i, gId);

gId = gId + 1;
[param, i] = ant_set_params(param, i, gId);

gId = gId + 1;
[param, i] = comb_set_params(param, i, gId);

gId = gId + 1;
[param, i] = sensor_set_params(param, i, gId);

gId = gId + 1;
[param, i] = idr_set_params(param, i, gId);

% gId = gId + 1;
% [param, i] = pc_set_params(param, i, gId);

groups=char('Network Topology',...
    'Network Holes',...
    'Transmision',...
    'Application Source',...
    'Application Destination',...
    'Application Simulation',...
    'Routing Layers',...
    'Common Routing Parameters',...
    'AODV Routing Parameters',...
    'MCBR Routing Parameters',...
    'Ant Routing Parameters',...
    'Comb Query Parameters', ...
    'Target Tracking', ...
    'IDR Parameters');

% this loop matches groupID and groupName
for i=1:length(param)
   param(i).groupname = groups(param(i).group,:);
end