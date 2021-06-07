sim_params('set_default')
sim_params('set', 'APP_NAME', 'Rmase');  % set the application name for the simulator
sim_params('set_app_default');

sim_params('set_app', 'Xoffset', 0.1);
sim_params('set_app', 'Yoffset', 0.1);

sim_params('set_app', 'SourceType', 'dynamic');
sim_params('set_app', 'SourceCenterType', 'fixed');
sim_params('set_app', 'SourceCenterX', 3);
sim_params('set_app', 'SourceCenterY', 3);

sim_params('set_app', 'DestinationType', 'mobile');
sim_params('set_app', 'DestinationCenterType', 'fixed');
sim_params('set_app', 'DestinationCenterX', 6);
sim_params('set_app', 'DestinationCenterY', 6);

sim_params('set_app', 'SourceRate', 1);

%stop at 25 sec. for a short demo with init at 5 sec.
sim_params('set_app', 'InitTime', 5);
sim_params('set', 'STOP_SIM_TIME', 25*40000);

% all_layers = all_app_layers;
% for i=1:length(all_layers)
%     sim_params('set_app', all_layers{i}, 0);
% end