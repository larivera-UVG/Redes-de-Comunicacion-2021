function y=sim_params(command, varargin)
% SIM_PARAMS  Simulation and application parameter set/get
% 
% Usage:
% sim_params('set', param_name1, param_value1, ...)  set simulation parameters
% sim_params('set_default', param_name, param_value)  set default simulation parameters
% sim_params('get')                                  get all simulation parameters
% sim_params('get', param_name)                      get simulation parameters
% sim_params('get_default')                          get default simulation parameters
% sim_params('set_app', param_name, param_value)     set application parameters
% sim_params('get_app', param_name)                  get application parameters
% 
% For possible simulation parameters and thei default value type sim_params('get_default')
% 
% There is no restriction for application parameters.

% ***	
% ***	 Copyright 2002, Vanderbilt University. All rights reserved.
% ***
% ***    This program is distributed in the hope that it will be useful,
% ***    but WITHOUT ANY WARRANTY; without even the implied warranty of
% ***    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% ***
% ***

%% Written by Gyula Simon, gyula.simon@vanderbilt.edu
% Last modified: Dec 5, 2003  by GYS


persistent SimulationParameters ApplicationParameters

% Added by YZ yzhang@parc.com Dec. 30, 2004
% sim_params('set_radio', param_name, param_value)     set radio parameters
% sim_params('get_radio', param_name)                  get radio parameters

persistent RadioParameters

switch command
case 'get'
    if isempty(SimulationParameters)
        SimulationParameters=sim_params('get_default');
    end
    if nargin>1
        param_name=varargin{1};
        if isfield(SimulationParameters, param_name)
            y=getfield(SimulationParameters, param_name);
        else 
            y=[];
        end
        if isempty(y)
            DefaultSimulationParameters=sim_params('get_default');
            if isfield(DefaultSimulationParameters, param_name)
                y=getfield(DefaultSimulationParameters, param_name);
            else 
                y=[];
            end
        end
    else % get all params
        def=sim_params('get_default');
        y=def;
        fn=fieldnames(def);
        for i=1:length(fn)
            y=setfield(y,fn{i}, sim_params('get', fn{i}));
        end
    end
case {'set', 'set_from_gui'}
    if isempty(SimulationParameters), SimulationParameters=sim_params('get_default'); end
    if ischar(varargin{1}) % char format
        for ii=1:2:length(varargin)
            param_name=varargin{ii};    
            param_value=varargin{ii+1};
            SimulationParameters=setfield(SimulationParameters, param_name, param_value);
        end
    else % struct format
        pars=varargin{1};
        names=fieldnames(pars);
        for ii=1:length(names)
            param_name=names{ii};    
            param_value=getfield(pars, param_name);
            SimulationParameters=setfield(SimulationParameters, param_name, param_value);
        end
    end
    if IsParamGuiOpen & ~strcmp(command, 'set_from_gui')
        pars=sim_params('get');
        prowparams('set_params_to_gui',pars)
        prowparams('plot_fx')
    end
   
case 'get_default'
    DefaultSimulationParameters=struct(...
        'APP_NAME'          , 'demo', ...           % name of the application [test]
        'RADIO_NAME'        , 'radio_channel', ...  % name of the radio definition file
        'SIMULATION_RUNNING', 0, ...                % Flag showing if simulation is currently running
        'STOP_SIM_TIME'     , 4000000, ...          % End Simulation Time (40000->1s)
        'SIGNAL_FCN'        , '1./(1+x.^2)', ...    % signal power vs distance
        'RECEPTION_LIMIT'   , 0.1, ...              % signal strength limit for reception (old model)
        'RECEPTION_SINR'    , 4, ...                % signal to noise ind interference limit for reception (ND model)
        'REC_NOISE_VAR'     , 0.025, ...            % receiver's noise variance (ND model)
        'IDLE_LIMIT'        , 4, ...                % REC_NOISE_VAR*IDLE_LIMIT = max signal strength for idle (ND model)
        'TR_ERROR_PROB'     , 0.05, ...             % probability of transmission errors [5%]
        'RADIO_SS_VAR_CONST', 0.45, ...             % variance of the radio transmission signal strength (topology) [45%]
        'RADIO_SS_VAR_RAND' , 0.02, ...             % variance of the radio transmission signal strength (random) [2%]
        'RADIO_RAYLEIGH_COH', 1, ...                % Rayleigh fading param 1:         %%'RADIO_RAYLEIGH_2'  , 10, ...                % Rayleigh fading param 2: 
        'MAC_MIN_WAITING_TIME'  ,   2*100, ...          %    MAC_LAYER PARAMS: mimimum waiting time
        'MAC_RAND_WAITING_TIME' ,   2*64, ...           %       additional max. random waiting time
        'MAC_MIN_BACKOFF_TIME'  ,   2*50, ...           %       minimum backoff time
        'MAC_RAND_BACKOFF_TIME' ,   2*15, ...           %       additional max. random backoff time
        'MAC_PACKET_LENGTH'     ,   8*(36*3+12), ...    %       length of a package
        'BIT_TIME'          , 1/40000, ...          % bit-time in sec
        'PRINT_EVENTS'      , 1, ...                % list event to gui or command window
        'ANIMATE'           , 1, ...                % animate events in gui
        'PLOT_PARS_linlog'            ,   1, ...    %    lin/log switch
        'PLOT_PARS_range'             ,   10);      %    plot range
        
    y=DefaultSimulationParameters;
    
case 'set_default'
    SimulationParameters=sim_params('get_default');
    if IsParamGuiOpen & ~strcmp(command, 'set_from_gui')
        pars=sim_params('get');
        prowparams('set_params_to_gui',pars)
        prowparams('plot_fx')
    end

case 'get_app'
    param_name=varargin{1};
    if isfield(ApplicationParameters, param_name)
        y=getfield(ApplicationParameters, param_name);
    else
        y=[];
    end
    
case 'set_app'
    param_name=varargin{1};    
    param_value=varargin{2};
    ApplicationParameters=setfield(ApplicationParameters, param_name, param_value);

%added by YZ, yzhang@parc.com
case 'set_app_default'
    app_name = sim_params('get', 'APP_NAME');
    appparamdefault(app_name);
%end of set_app_default

case 'get_radio'
    param_name=varargin{1};
    if isfield(RadioParameters, param_name)
        y=getfield(RadioParameters, param_name);
    else
        y=[];
    end
    
case 'set_radio'
    param_name=varargin{1};    
    param_value=varargin{2};
    RadioParameters=setfield(RadioParameters, param_name, param_value);
    
%end of radio parameters

otherwise
    error(['Bad command for sim_params: ' command])
end

function x=IsParamGuiOpen
h_fig=findall(0, 'tag', 'paramgui_fig');
x=length(h_fig)==1;