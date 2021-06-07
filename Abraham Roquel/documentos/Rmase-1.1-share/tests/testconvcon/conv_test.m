function out=generator_test

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

disp('With the GUI window open, you can see the simulations running,')
disp('but it may take a while.')
disp('Without the GUI it''s much faster.')
disp(' ')

is_gui=input('Do you want to continue with (1) or without (0) the GUI? ');
if is_gui
    prowler('OpenGUI')
    prowler('show_animation', 1)
    prowler('show_events', 1)
else
    prowler('CloseGUI')
end 
sim_params('set_default')

sim_params('set', 'APP_NAME', 'Rmase');  % set the application name for the simulator
sim_params('set_app_default');

sim_params('set_app', 'SourceNofPackets', 1);
sim_params('set_app', 'InitTime', 3);

sim_params('set_app', 'Xsize', 10);
sim_params('set_app', 'Ysize', 10);

sim_params('set_app', 'SourceCenterType', 'fixed');
sim_params('set_app', 'SourceCenterX', 5);
sim_params('set_app', 'SourceCenterY', 5);
sim_params('set_app', 'SourceRadius', 10);
sim_params('set_app', 'SourceUnique', 0);

sim_params('set_app', 'DestinationCenterType', 'fixed');
sim_params('set_app', 'DestinationCenterX', 5);
sim_params('set_app', 'DestinationCenterY', 5);

nOfT = 10;
sim_params('set_app', 'Strength', 0.5);

%flood
set_layers({'mac', 'transmit_queue', 'neighborhood', 'delay_transmit', 'converge_control', 'init_backward', 'app', 'stats', 'log'});
conv_strategies(50, nOfT, 50, 'tests/testconvcon/resultoutward');

% set_layers({'mac', 'transmit_queue', 'neighborhood', 'delay_transmit', 'converge_inward', 'init_backward', 'app', 'stats', 'log'});
% conv_strategies(50, nOfT, 50, 'tests/testconvcon/resultinward');

set_layers({'mac', 'transmit_queue', 'neighborhood', 'delay_transmit', 'converge_inwardN', 'init_backward', 'app', 'stats', 'log'});
conv_strategies(50, nOfT, 50, 'tests/testconvcon/resultinwardN');

% 
set_layers({'mac', 'aggregate_queue', 'neighborhood', 'delay_transmit', 'converge_control', 'init_backward', 'app', 'stats', 'log'});
conv_strategies(50, nOfT, 50, 'tests/testconvcon/resultoutwarda');

% set_layers({'mac', 'aggregate_queue', 'neighborhood', 'delay_transmit', 'converge_inward', 'init_backward', 'app', 'stats', 'log'});
% conv_strategies(50, nOfT, 50, 'tests/testconvcon/resultinwarda');

set_layers({'mac', 'aggregate_queue', 'neighborhood', 'delay_transmit', 'converge_inwardN', 'init_backward', 'app', 'stats', 'log'});
conv_strategies(50, nOfT, 50, 'tests/testconvcon/resultinwardNa');

%test for three signal strength
% 
% sim_params('set_app', 'Strength', 0.3);
% conv_strategies(100, nOfT, 100, 'tests/testconvcon/resultflood03');
% 
% sim_params('set_app', 'Strength', 0.7);
% conv_strategies(100, nOfT, 100, 'tests/testconvcon/resultflood07');

%tree
% set_layers({'mac', 'transmit_queue', 'neighborhood', 'confirm_transmit', 'check_duplicate', 'converge_tree', 'init_backward', 'app', 'stats', 'log'});

%test for three signal strength

% sim_params('set_app', 'Strength', 0.5);
% conv_strategies(100, nOfT, 100, 'tests/testconvcon/resulttree05');

% sim_params('set_app', 'Strength', 0.3);
% conv_strategies(100, nOfT, 100, 'tests/testconvcon/resulttree03');
% 
% sim_params('set_app', 'Strength', 0.7);
% conv_strategies(100, nOfT, 100, 'tests/testconvcon/resulttree07');