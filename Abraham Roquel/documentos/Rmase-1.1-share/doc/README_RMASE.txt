               		R-MASE: Routing Modeling Application Simulation Environment
				A Routing Test Platform in PROWLER

                                      Jan. 21, 2005



Copyright (C) 2003 PARC Inc.  All Rights Reserved.

Use, reproduction, preparation of derivative works, and distribution 
of this software is permitted, but only for non-commercial research 
or educational purposes. Any copy of this software or of any derivative 
work must include both the above copyright notice of PARC Incorporated 
and this paragraph. Any distribution of this software or derivative 
works must comply with all applicable United States export control laws. 
This software is made available AS IS, and PARC INCORPORATED DISCLAIMS 
ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE 
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
PURPOSE, AND NOTWITHSTANDING ANY OTHER PROVISION CONTAINED HEREIN, ANY 
LIABILITY FOR DAMAGES RESULTING FROM THE SOFTWARE OR ITS USE IS EXPRESSLY 
DISCLAIMED, WHETHER ARISING IN CONTRACT, TORT (INCLUDING NEGLIGENCE) 
OR STRICT LIABILITY, EVEN IF PARC INCORPORATED IS ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGES. This notice applies to all files in this 
release (sources, executables, libraries, demos, and documentation).

// ----- NEST Repository Information [START] -----
// MODULE: Rmase
// KEY WORDS DESCRIPTIONS: routing simulation
// FUNCTIONAL DESCRIPTION: simulation environment for routing applications.
// AUTHOR: Ying Zhang
// AUTHOR CONTACT INFO.: yzhang@parc.com
// VERSION: 1.1
// DATE: Jan. 21, 2005
// LICENSING: see copyright license above, per contract F33615-01-C-1904
// ----- NEST Repository Information [END] -----


Written by Ying Zhang, e-mail: yzhang@parc.com

This release is for Prowler_v1_25

Further documentation is in

http://www.parc.com/era/nest/Rmase/

Application: Rmase

  generate network topology
  generate application senario
  layered architecture for plug routing components
  performance statistic analysis
  routing algorithms developed by PARC and other institutions


Main
	%application
	Rmase_animation.m
	Rmase_application.m
	Rmase_params.m
	Rmase_info.m
	Rmase_topology.m

	%support for the application 'Rmase'
	init_app_layers.m
	app_layers.m
	find_layer.m
	set_mobile_motes.m
	set_static_motes.m
	pair_satisfied.m
	topology_creator.m
	common_layer.m
	appparamdefault.m

Utilities
	permstats.m
	attribute.m
	Plot3D.m
	DrawHoles.m
	...

Parameters
	includes parameter settings for the system, e.g., all the layers,
	and default parameters for the system

Algorithms
	includes common routing components as well as 
	algorithms developed by various institutions
	(only PARC's algorithms are released here. For other institutions, please ask by email)

	Each algorithm has its source, such as papers or original NesC code
	

	%common layers
	stats_layer.m
	app_layer.m
	check_duplicate_layer.m
	fault_layer.m
	mac_layer.m
	max_hops_layer.m
	

Tests

	

	testpeg: %Pursuer/Evader Game
		peg_test.m


	To run a test, set working directory to Rmase-1.1, and 
	add this and all its subdirectories to matlab path.

Other directories include: 
   sensor -- modeling acustic sensors with probability model, 
             used for information directed routing
   radio_USC -- a new radio model developed by USC, the model is 
             used for minimum power configuration by WUSTL
   doc -- documents including this file and the html description of Rmase,
          and a paper on Rmase.
   log -- used for record all log files during simulation for debugging


Modified Files of Prowler-1.25:

	prowler.m 
		added
		print_event('initializing...') in the beginning

		and
		%print_event(['Application ''' app_name ''' initialized...'])
    		print_event(['Application ''' app_name ''' INITIALIZED...'])
		
		so that not to clean up the screen

		added set radio parameters
		
	sim_params.m
		added 'set_app_default' case

		added set radio parameters

	register_applications.m
		added application Rmase and USC radio model

