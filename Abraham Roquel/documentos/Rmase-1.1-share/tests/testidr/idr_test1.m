%hole
sim_params('set_app', 'HPosX', 2.5);
sim_params('set_app', 'HPosY', 4);
sim_params('set_app', 'HLengthX', 4);
sim_params('set_app', 'HHeigthY', 2);

%source
sim_params('set_app', 'SourceCenterType', 'fixed');
sim_params('set_app', 'SourceRadius', 0.5);

%target
sim_params('set_app', 'TargetInit', [2.5, 7.5]);
sim_params('set_app', 'TargetSpeed', [0, 0]);
sim_params('set_app', 'RandTargetSpeed', 0);

sim_params('set_app', 'Promiscuous', 1); %overhear to learn
set_layers({'mac', 'neighborhood', 'sensor', 'idr_local', 'init_hello', 'idr_stats', 'app', 'stats', 'log'});