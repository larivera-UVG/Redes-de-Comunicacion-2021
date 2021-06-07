sim_params('set', 'APP_NAME', 'Rmase');  % set the application name for the simulator
sim_params('set_app_default');

%network topology
sim_params('set_app', 'Xsize', 6);
sim_params('set_app', 'Ysize', 15);
sim_params('set_app', 'Xoffset', 0.1);
sim_params('set_app', 'Yoffset', 0.1);

%radio
sim_params('set_app', 'Strength', 0.6);
sim_params('set', 'RADIO_SS_VAR_CONST', 0);
sim_params('set', 'RADIO_SS_VAR_RAND', 0);
sim_params('set', 'TR_ERROR_PROB', 0);

sim_params('set_app', 'InitTime', 5);

%max_hops
sim_params('set_app', 'IDRMaxHops', 20);
sim_params('set_app', 'MinInfoGain', 0.1);
sim_params('set_app', 'SourceRate', 0.2);

sim_params('set_app', 'DOASensorProb', 0.1);