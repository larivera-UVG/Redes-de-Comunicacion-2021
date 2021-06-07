               PROWLER  - PROBABILISTIC WIRELESS NETWORK SIMULATOR V1.25

                                      January 28, 2004



Copyright 2003, Vanderbilt University. All rights reserved. 
This program is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Written by Gyula Simon, e-mail: gyula.simon@vanderbilt.edu

Tested on MATLAB version 6.5 (R13)

IMPROVEMENTS SINCE V1.1

  A new radio model is added 
    (radio_channel_ND*, based on the model of Martin Haenggi, University of Notre Dame)
  Improved graphical capabilities (DrawLine command, see application spantree)
  Application parameters are handled from GUI
  Application information can be added and invoked from GUI
  Online Help
*this file has been renamed; the new name is radio_channel_sinr

IMPROVEMENTS SINCE V1.21
  New events to signal end of simulation:
     Application_Stopped  -- activated when STOP button is pressed
     Application_Finished -- activated when simulation is finished (not stopped)
  Enhanced application parameters

IMPROVEMENTS SINCE V1.22
  New radio definition file added: radio_channel_Rayleigh*
  It models Rayleigh fading. (Based on the model of Martin Haenggi, 
  University of Notre Dame.)
*this file has been renamed; the new name is radio_channel_Rayleigh_ND

IMPROVEMENTS SINCE V1.23
  Application parameter features have been improved, thanks to Lukas D. Kuhn, 
  lukas.kuhn@parc.com. See route_angle_params.m for usage.
  To avoid further confusion, the radio definition files has been renamed to 
  reflect their true content. See * comments above.
  
IMPROVEMENTS SINCE V1.24
  The GetDisplayHandle function is added to aid creation of user graphic in the 
   current (internal or external) Prowler diplay.
   usage: handle = prowler('GetDisplayHandle')
   Warning: handle can change if internal / external window switch is changed
  The 'PrintEvent' command is added for debugging purposes. This command prints 
   a message to the end of the event monitor. 
   usage: prowler('PrintEvent', 'Hello World')
   warning:The message disappears when the display is refreshed (e.g. start/stop 
   application) 

GENERAL:

This simulator simulates the radio transmission/propagation/reception, including 
collisions in ad-hoc radio networks, and the operation of the MAC-layer. Any 
application can be implemented on any number of motes. The radio definitions 
(propagation and MAC-layer) and the applications are plug-ins. For the time 
being three radio definition files are provided (radio_channel.m, radio_channel_sinr.m and 
radio_channel_Rayleigh_ND.m), with a set of applications (demo, flood1D, flood2D, 
collision_demo, spantree).

The simulator can be set to deterministic operation mode (it's useful to test 
algorithms) as well as to probabilistic operation mode (which is even more 
useful to test algorithms ;-)). The parameters can be set from command line by 
sim_params. (See help sim_params.)The parameter setting GUI can conveniently be 
accessed by pressing the Simulation Parameters button in the prowler GUI.

SIMULATION OF THE RADIO CHANNEL AND THE MAC-LAYER:

See Simulation Parameters in the Prowler GUI, and Help in Simulation Parameters 
for more details. 

APPLICATIONS:

Each application consists of three files: 

  Name_topology.m     topology information (coordinates of the motes)
  Name_animation.m    animation information (how to display events during 
                      simulation)
  Name_application.m  the actual application code

Two additional files may be added to the application:

  Name_info           displays information about the application when 
                      the Application Info button is pressed.
  Name_params         defines application specific parameters. These 
                      parameters can be viewed and modified by pressing 
                      the Aplication Parameters button.

The applications are event based. 
Events:  
  Init_Application  
  Packet_Sent  
  Packet_Received  
  Collided_Packet_Received  
  Clock_Tick
  Application_Finished
  Application_Stopped

Actions can be activated when events occur. These actions cause further events. 
  Actions:  
  Set_Clock  
  Send_Packet
Note: After events Application_Finished and Application_Stopped no further actions can be activated.

 
There are debug/visualization actions (no events caused):  
PrintMessage : example:  PrintMessage('Prowler')  
LED          : examples: LED('red on'), LED('green off'), LED('yellow toggle')  
DrawLine     : format:   
                   Drawline(ModeStr, ID1, ID2 [, optional formatting commands]);
                   ModeStr=Line|Arrow|Delete
               examples: DrawLine('Arrow', ID1, ID2, 'color', [1 0 0]), 
                         DrawLine('Delete', ID1, ID2)  

The function call prowler('GetDisplayHandle') can be used to get the actual display's
handle. Can be useful when creating extra graphics on the display.

See the applications files of demo, flood1D and spantree for further details.

SUPPLIED EXAMPLE APPLICATIONS:

  demo  
  flood1D  
  flood2D  
  collision_demo  
  spantree  
  route_angle

DEMOS:

There are two command line demos in the current package: prowdemo.m and 
demo_opt.m.

Prowdemo illustrates the capabilities of the simulator. Type prowdemo and follow 
instructions.

Demo_opt is a simple optimization program showing how to use the simulator to 
compute simulation related statistics. Type demo_opt and follow instructions.

INSTALLATION:

Copy all files from the zip-file to one directory. Add this directory to 
MATLAB_PATH.

Start the GUI by typing prowler on the command line.

WRITING NEW APPLICATIONS:

Use any of the supplied _application, _animation, and _topology files as 
templates for your program (_info and _params files are optional). 

  _application: contains the code for the application
  _animation  : determines the graphical representation of events
  _topology   : defines topology of the motes
  _info       : info (help) on the application [optional]
  _params     : application parameters [optional]

The application MUST BE REGISTERED by editing the file register_applications.m.

