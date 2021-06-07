%source
sim_params('set_app', 'SourceCenterType', 'fixed');
sim_params('set_app', 'SourceRadius', 0.5);
%destination
sim_params('set_app', 'DestinationCenterType', 'fixed');
sim_params('set_app', 'DestinationRadius', 0.5);
sim_params('set_app', 'DestinationCenterY', 14);


%target
% sim_params('set_app', 'TargetInit', [2.5, 7.5]);
sim_params('set_app', 'TargetInit', [4, 7.5]);
sim_params('set_app', 'TargetSpeed', [0, 0]);
sim_params('set_app', 'RandTargetSpeed', 0);
%sim_params('set_app', 'MaxTargetSpeedBelieved', 0.1);

sim_params('set_app', 'Promiscuous', 1); %overhear to learn
