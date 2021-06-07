% DEMO_OPT
% This is a demo to illustrate how to use prowler for optimization purposes.
%
% A 2D flood is analyzed: 
%   The goal is to find the 'best' retransmission probability  
%   in order to provide low settling time.

% ***	
% ***	 Copyright 2002, Vanderbilt University. All rights reserved.
% ***
% ***    This program is distributed in the hope that it will be useful,
% ***    but WITHOUT ANY WARRANTY; without even the implied warranty of
% ***    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% ***
% ***

% Written by Gyula Simon, gyula.simon@vanderbilt.edu
% Last modified: Sep 24, 2002  by GYS



disp('This demo illustrates how to use the simulator for optimization purposes.')
disp('Now a 1D flood algorithm with random retransmission will be simulated.')
disp('The first mote transmits the message, the receivers retransmit it')
disp('with probability P=[0.0:0.1:1]')
disp('Important factors are the Settling_Time and the Number_of_Receiving_Motes')
disp('This demo will simply scan the range of possible P values,')
disp('with each value 10 simulations will be run.')
disp(' ')
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

% probability values to try:
P=[0.0: 0.1: 1];    % probability values to scan
Number_of_Runs=10;  % number of runs for each P value

sim_params('set', 'APP_NAME', 'flood1D');  % set the application name for the simulator



mean_receiving_nodes = [];
var_receiving_nodes  = [];
mean_settling_time   = [];
var_settling_time    = [];

for p_ix=1:length(P)
    p=P(p_ix);
    disp(['p=' num2str(p)])
    sim_params('set_app', 'P', p);
    receiving_nodes = [];
    settling_time   = [];
    
    sim_params('set_app', 'P', p)
    for itnum=1:Number_of_Runs
        prowler('Init');
        prowler('StartSimulation');
        [sys_stat, node_stat] = simstats;
        receiving_nodes(itnum)= sys_stat.Receiving_Nodes;
        settling_time(itnum)  = sys_stat.Last_Receive_Time-sys_stat.First_Send_Time;
        if isinf(settling_time(itnum)) % no received messages
            mac_params_pl=sim_params('get', 'MAC_PACKET_LENGTH');
            settling_time(itnum)=mac_params_pl;
        end
    end
    mean_receiving_nodes(p_ix) = mean(receiving_nodes);
    mean_settling_time(p_ix)   = mean(settling_time);
    
    var_receiving_nodes(p_ix) = var(receiving_nodes);
    var_settling_time(p_ix)   = var(settling_time);
    disp(['# nodes: ' num2str(mean_receiving_nodes(p_ix))])
    disp(['settling time: ' num2str(mean_settling_time(p_ix)/40000)])
end
figure(1), clf
subplot(211)
plot(P, mean_receiving_nodes), title('# of receiving nodes'), xlabel('p')
subplot(212)
plot(P, mean_settling_time/40000), title('settling time (s)'), xlabel('p')