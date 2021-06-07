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

peg_model;
%sim_params('set', 'STOP_SIM_TIME', 100*40000);
sim_params('set', 'STOP_SIM_TIME', 200*40000);

%sim_params('set_app', 'DestinationType', 'static');
sim_params('set_app', 'RandSpeedDestination', 0);
sim_params('set_app', 'RandSpeedSource', 0.00);
%sim_params('set_app', 'TR_ERROR_PROB', 0.00);             % probability of transmission errors [5%]
%sim_params('set_app', 'RADIO_SS_VAR_CONST', 0.00);             % variance of the radio transmission signal strength (topology) [45%]
%sim_params('set_app', 'RADIO_SS_VAR_RAND', 0.00);             % variance of the radio transmission signal strength (random) [2%]
   
for speed=0:0.02:0.2
    sim_params('set_app', 'DestinationSpeedX', speed);
    sim_params('set_app', 'DestinationSpeedY', speed);
    sim_params('set_app', 'SourceSpeedX', speed);
    sim_params('set_app', 'SourceSpeedY', speed);
    
    dir = strcat('tests/testpeg/result_aodv-75s/',num2str(speed),'-');
    peg_aodv(75, 10, 5, dir);
end