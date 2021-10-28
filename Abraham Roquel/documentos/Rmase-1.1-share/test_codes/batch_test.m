% Universidad del Valle de Guatemala
% ejecución de pruebas en batch sobre el framework de RMASE
% basado en los ejemplos de la documentación original

%set Rmase as Prowler application
sim_params('set_default');
sim_params('set', 'APP_NAME', 'Rmase');
sim_params('set_app_default');

% parámetros de interés
usar la topología de test_topo
sourcerate = 0
mac, neighborhood, mainAntNet


%start Prowler
prowler('Init');
prowler('StartSimulation');
