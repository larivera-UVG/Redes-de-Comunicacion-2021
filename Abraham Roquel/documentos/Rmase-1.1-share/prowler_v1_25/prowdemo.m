% demo for simulator
disp('DEMO for radio propagation / MAC layer simulation')
disp(' ')
disp(' ')
disp('The first mote is transmitting a message in every second') 
disp('The other motes retransmit the message (flood)') 
disp('The received/sent message IDs are shown on the motes') 
disp(' ')
disp('Mote colors:')
disp('  Small red dots indicate motes with pending transmission') 
disp('  Bigger red dots indicate transmitting motes') 
disp(' ')
disp('LEDs:')
disp('  Small green dots indicate receiving motes') 
disp('  Green LED is toggled when a message is received succesfully') 
disp('  Yellow LED is toggled when a collided message is received') 
disp(' ')
disp('Click on the white area to move the first mote during simulation') 
disp('You can also click on the mote''s dot to see memory dump (even during simulation)') 
disp(' ')
disp(' ')
disp('Press a key to begin (you can suspend simulation any time by pressing ''Stop'' on GUI)')
pause
disp('Simulation running')


simgui
sim_params('set', 'APP_NAME', 'demo');  % set the application name for the simulator
prowler('Init')
prowler('StartSimulation')

disp('Simulation stopped.')
disp(' ')
disp('Try the FLOOD applications from the GUI (select ''Application name'' pulldown menu)')
disp(' ')
disp('You can try ''simstats'' for simulation statistics') 
disp('Try also ''demo_opt'' from the command window') 
