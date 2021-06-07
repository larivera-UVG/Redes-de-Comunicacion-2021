function varargout=prowler(command, varargin)
%  prowler - PROBABILISTIC WIRELESS NETWORK  SIMULATOR - Main simulation program
%
%  Command line options:
%    initialize: prowler('Init')
%    simulate:   prowler('StartSimulation')
% 
% A graphical user interface can be invoked by typing prowler.
%
% See also: radio_channel, sim_params, demo_application, simstats, demo_opt

% ***	
% ***	 Copyright 2002, Vanderbilt University. All rights reserved.
% ***
% ***    This program is distributed in the hope that it will be useful,
% ***    but WITHOUT ANY WARRANTY; without even the implied warranty of
% ***    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% ***
% ***

% Written by Gyula Simon, gyula.simon@vanderbilt.edu
% Last modified: Jan 28, 2004  by GYS


persistent event_Q  event_Q_ix topology mote_IDs topology_update_stamp
persistent radio app_name  sim_t  real_sim_T
global global_event_Q


if nargin<1
    command='OpenGui'; 
end
if strcmpi(command, 'Init')
    sim_t=0;
    print_event('initializing...');
    prowler('RefreshApplicationAndRadioInfo');
    SetApplicationParams(app_name);  % if exists _params file, set the default parameters
    SetRadioParams(radio); %if exists _params file, set the default parameters, YZ
    prowler('RefreshTopologyInfo', 'init');
    prowler('show_animation');
    prowler('show_events');

    
    prowparams('select_active_params')  % if parameters window is open, enable/disable radio specific UICs
    
    event_Q=[]; global_event_Q=[];
    prowler('InsertEvents2Q', make_event(0, 'Init_Radio', -999));
    for mote_ID=mote_IDs
        prowler('InsertEvents2Q', make_event(0, 'Init_Application', mote_ID));
    end
    event_Q_ix=1;
    %print_event(['Application ''' app_name ''' initialized...'])
    print_event(['Application ''' app_name ''' INITIALIZED...'])
    plot_event('init')
    AdjustTipButton(app_name);
    
    prowler('show_LEDs')
    real_sim_T=0; % measure simulation time
elseif strcmpi(command, 'StartSimulation')
    sim_t=0; 
    % housekeeping A1: remove those events from  global_event_Q which were added when simulation was suspended (by stop button)
    % see housekeeping A2
    NUM_EVENTS_STOP=1000; % max number of events shown when stopped
    sim_params('set', 'SIMULATION_RUNNING',1);
    if length(global_event_Q)>0
        ix_end=length(global_event_Q)-length(event_Q)+event_Q_ix-1;
        print_event(global_event_Q(max(1,end-NUM_EVENTS_STOP):ix_end))
        global_event_Q=global_event_Q(1:end-length(event_Q));
    end
    % simulation
    % disable buttons and pulldown menus
    h_fig=findobj(allchild(0), 'flat', 'tag', 'Simulation_Fig');
    if ~isempty(h_fig)
        a=guihandles(h_fig);
        set([a.Application_def, a.Radio_def, a.Simulation_start, a.Simulation_continue], 'enable', 'off')
    end
    tic; last_draw=clock; last_print=clock;
    while sim_t<sim_params('get', 'STOP_SIM_TIME') & event_Q_ix <= length(event_Q) & sim_params('get','SIMULATION_RUNNING')
        
        event=event_Q(event_Q_ix);
        print_event(event)
        plot_event(event)
        last_sim_t=sim_t;
        [sim_t, event_name, ID, data]=get_event(event);
        if last_sim_t~=sim_t % new time instant, perhaps screen update necessary
            upd=sim_params('get', 'ANIMATE');
            if upd==1
                drawnow, last_draw=clock;
            else % slow update or no update
                if etime(clock, last_draw)>1
                    drawnow, last_draw=clock; 
                end  
            end
        end
        
        if etime(clock, last_print)>1, % this is to prevent gui from freezing when no animation is done
            last_print=clock; 
            if ~sim_params('get', 'PRINT_EVENTS'), print_event(make_event(sim_t, 'Simulation running...',0), 0, 0), end
        end  
        
        % decide to whom the event should be sent
        switch event_name
        case {'Init_Radio', 'Channel_Request', 'Channel_Idle_Check', ...
                    'Packet_Receive_Start', 'Packet_Receive_End', ...
                    'Packet_Transmit_Start', 'Packet_Transmit_End'}
            % event to radio layer
            feval(radio, event);
        case {'Init_Application', 'Packet_Sent', 'Packet_Received', ...
                    'Collided_Packet_Received', 'Clock_Tick'}
            % event to application layer
            feval([app_name, '_application'], event);
        otherwise
            error(['Unknown event: ' event_name])
        end
        event_Q_ix=event_Q_ix+1;
        
    end % while 
    try % try provided for compatibility reasons, older applications cannot handle the following events
        if sim_params('get','SIMULATION_RUNNING') % event queue empty
            for mote_ID=mote_IDs
                feval([app_name, '_application'], make_event(0, 'Application_Finished', mote_ID));
            end
        else
            for mote_ID=mote_IDs
                feval([app_name, '_application'], make_event(0, 'Application_Stopped', mote_ID));
            end
        end 
    catch
    end
    
    sim_params('set', 'SIMULATION_RUNNING',0);
    real_sim_T=real_sim_T+toc;
    % housekeeping A2: add events to global_event_Q which were not purged from event_Q by the time
    % simulation was stopped
    % see housekeeping A1
    global_event_Q=[global_event_Q, event_Q]; 
    highlight_offset=length(event_Q)-event_Q_ix; % event monitor highlights the next event to be executed
    
    print_event(global_event_Q(max(1,end-NUM_EVENTS_STOP):end)) % update event list with a longer list
    print_event(['Stopped. (SimTime=' sprintf('%1.1f', real_sim_T) 's)'], highlight_offset+1)
    drawnow;
    % enable pulldown menus
    h_fig=findobj(allchild(0), 'flat', 'tag', 'Simulation_Fig');
    if ~isempty(h_fig)
        a=guihandles(h_fig);
        set([a.Application_def, a.Radio_def, a.Simulation_start, a.Simulation_continue], 'enable', 'on')
    end

elseif strcmpi(command, 'StopSimulation')
    sim_params('set','SIMULATION_RUNNING',0);
    % enable pulldown menus
    h_fig=findobj(allchild(0), 'flat', 'tag', 'Simulation_Fig');
    if ~isempty(h_fig)
        a=guihandles(h_fig);
        set([a.Application_def, a.Radio_def, a.Simulation_start, a.Simulation_continue], 'enable', 'on')
    end

elseif strcmpi(command, 'InsertEvents2Q')
    events=varargin{1}; 
    [event_Q, event_Q_ix]=insert_events(event_Q,event_Q_ix,events,sim_t);
    
elseif strcmpi(command, 'GetRadioName')
    varargout={radio};
elseif strcmpi(command, 'GetAnimationName')
    varargout={[app_name '_animation']};
elseif strcmpi(command, 'GetTopologyInfo')
    varargout={topology, mote_IDs, topology_update_stamp};
    
elseif strcmpi(command, 'RefreshApplicationAndRadioInfo')
    app_name=sim_params('get', 'APP_NAME');
    radio=sim_params('get', 'RADIO_NAME');
    
    application_name=[app_name '_application'];      % application is implemented in this m-file
    topology_name   =[app_name '_topology'];         % topology and ID info for the application 
    animation_name  =[app_name '_animation'];        % topology and ID info for the application 
    % check names
    if ~exist(application_name, 'file'), error(['Application file '' '  application_name '''.m is missing']); end
    if ~exist(topology_name, 'file'),    error(['Topology file '' '        topology_name '''.m is missing']); end
    if ~exist(animation_name, 'file'),   error(['Animation file '' '      animation_name '''.m is missing']); end
    if ~exist(radio, 'file'),            error(['Radio definition file '' '        radio '''.m is missing']); end
    
    
elseif strcmpi(command, 'RefreshTopologyInfo')
    topology_name=[app_name '_topology'];         % topology and ID info for the application 
    if nargin >1; % init
        topology_update_stamp=0;    
        [topology, mote_IDs]=feval(topology_name, 'init');
    else
        [topology, mote_IDs]=feval(topology_name);
    end
    topology_update_stamp=topology_update_stamp+1;
    if  topology_update_stamp>1   % not init
        radio=sim_params('get', 'RADIO_NAME');
        feval(radio, 'Prowler!RefreshTopology');  % notify the radio channel, it should update its internal info
    end
elseif strcmpi(command, 'TextMessage')
    plot_event('TextMessage', varargin{1}, varargin{2})
elseif strcmpi(command, 'LED')
    plot_event(command, varargin{1}, varargin{2})
    
elseif findstr(command, 'Draw')
    if findstr(command, 'Line')
        plot_line('Line', varargin{:})
    elseif findstr(command, 'Arrow')
        plot_line('Arrow', varargin{:})
    elseif findstr(command, 'Delete')
        plot_line('Delete', varargin{:})
    end
    
elseif strcmpi(command, 'Redraw')
    plot_event(command)
    
elseif strcmpi(command, 'Gui_Mouse_Axes_Click')  % message from gui; can be used to update topology
    position=varargin{1}; position=position(1,1:2);
    try
        feval([app_name '_topology'], 'Refresh', position);
        prowler('RefreshTopologyInfo');
        prowler('Redraw')
    end
elseif strcmpi(command, 'GuiMouseMoteClick')
    h_clicked_mote=varargin{1};
    clicked_mote_ID=get(h_clicked_mote, 'userdata');
    feval([app_name, '_application'], make_event(sim_t, 'GuiInfoRequest', clicked_mote_ID));
    
    
elseif strcmpi(command, 'show_LEDs')
    h_fig=findobj(allchild(0), 'flat', 'tag', 'Simulation_Fig');
    ch=allchild(h_fig);
    h_cb=findobj(ch, 'flat', 'tag', 'showLEDs');
    show_LEDs=get(h_cb, 'value');
    % find all LED related staff on plot
    %h_ax=findobj(ch, 'flat', 'tag', 'simulation_plot_ax');
    h_ax=findall(0, 'tag', 'simulation_plot_ax');
    %     h_line=findobj(allchild(h_ax), 'flat', 'type', 'line');
    %     h_LEDs=[]; h_frames=[]; i=1; found=1;
    %     while ~isempty(found)
    %         found=[ findobj(h_line, 'flat', 'tag', ['rLED' num2str(i)]); ...
    %                 findobj(h_line, 'flat', 'tag', ['gLED' num2str(i)]); ...
    %                 findobj(h_line, 'flat', 'tag', ['yLED' num2str(i)]); ...
    %                 findobj(h_line, 'flat', 'tag', ['LED_frame' num2str(i)])];
    %         h_LEDs=[h_LEDs; found]; i=i+1;
    %     end
    %     h_LEDs  =[findobj(h_ax, 'tag', 'rLED'); findobj(h_ax, 'tag', 'gLED'); findobj(h_ax, 'tag', 'yLED')];
    %     h_frames=findobj(h_ax, 'tag', 'LED_frame');
    h_LEDs=findobj(allchild(h_ax), 'flat',  'buttondownfcn', '3.1415926;'); 

    if show_LEDs
        set([h_LEDs], 'visible', 'on')
    else
        set([h_LEDs], 'visible', 'off')
    end
    
    
elseif strcmpi(command, 'show_distances')
    h_fig=findobj(allchild(0), 'flat', 'tag', 'Simulation_Fig');
    ch=allchild(h_fig);
    % h_ax=findobj(ch, 'flat', 'tag', 'simulation_plot_ax');
    h_ax=findall(0, 'tag', 'simulation_plot_ax');
    h_cb=findobj(ch, 'flat', 'tag', 'show_distances');
    if nargin > 1
        show=varargin{1};
        set(h_cb, 'value', show);
    else
        show=get(h_cb, 'value');
    end
    if show
        set(h_ax, 'xtickmode', 'auto')
        set(h_ax, 'ytickmode', 'auto')
        grid(h_ax, 'on')
    else
        set(h_ax, 'xtickmode', 'manual')
        set(h_ax, 'ytickmode', 'manual')
        set(h_ax, 'xtick', [])
        set(h_ax, 'ytick', [])
        
        grid(h_ax, 'off')

    end
    
elseif strcmpi(command, 'show_animation')
    h_fig=findobj(allchild(0), 'flat', 'tag', 'Simulation_Fig');
    ch=allchild(h_fig);
    h=findobj(ch, 'flat', 'tag', 'show_animation');
    if nargin >1 % value provided
        anim=varargin{1};
        if anim==0; anim=3; end
        set(h,'value', anim);
        sim_params('set_from_gui', 'ANIMATE', mod(anim,3));
    else
        anim=get(h,'value');
        sim_params('set_from_gui', 'ANIMATE', mod(anim,3));
    end
    
elseif strcmpi(command, 'show_events')
    h_fig=findobj(allchild(0), 'flat', 'tag', 'Simulation_Fig');
    ch=allchild(h_fig);
    h=findobj(ch, 'flat', 'tag', 'show_events');

    if nargin >1 % value provided
        shw=varargin{1};
        set(h,'value', shw);
        sim_params('set_from_gui', 'PRINT_EVENTS', shw);
    else
        sim_params('set_from_gui', 'PRINT_EVENTS', get(h,'value'));
    end

elseif strcmpi(command, 'ShowApplicationInfo')
    infofile=AdjustTipButton(app_name);
    if ~isempty(infofile)
        feval(infofile);
    end
    
elseif strcmpi(command, 'ShowApplicationParams')
    appparamw('init', app_name)
    
elseif strcmpi(command, 'OpenGUI')
    simgui;
elseif strcmpi(command, 'CloseGUI')
    h_fig=findobj(allchild(0), 'flat', 'tag', 'Simulation_Fig');
    delete(h_fig)
    h_fig=findobj(allchild(0), 'flat', 'tag', 'paramgui_fig');
    close(h_fig)
    h_fig=findobj(allchild(0), 'flat', 'tag', 'Prowler_External_Display_fig');
    delete(h_fig)
   
elseif strcmpi(command, 'SwitchDisplay')
    h_fig=findobj(allchild(0), 'flat', 'tag', 'Simulation_Fig');
    h_cb=findobj(allchild(h_fig), 'flat', 'tag', 'external_display');
    if nargin>1
        mode=varargin{1};
        if strcmp('mode', 'out')
            set(h_cb, 'value', 1)
        else
            set(h_cb, 'value', 0)
        end
    end
    if get(h_cb, 'value')
        mode='out';
    else 
        mode='in';
    end
    SwitchDisplay(mode);

elseif strcmpi(command, 'GetDisplayHandle')
        h_fig=findobj(allchild(0), 'flat', 'tag', 'Simulation_Fig');
        h_ax=findall(h_fig, 'tag', 'simulation_plot_ax');
        if isempty(h_ax)
            h_fig=findobj(allchild(0), 'flat', 'tag', 'Prowler_External_Display_fig');
            h_ax=findall(h_fig, 'tag', 'simulation_plot_ax');
        end
        varargout={h_ax};
    
% 'PrintEvent' command is added by LK and YZ    
elseif strcmpi(command, 'PrintEvent')
    print_event(varargin{1});
    
elseif strcmpi(command, 'version')
    % CURRENT VERSION NUMBER
    varargout={'1.25'};
else
    error(['Unknown command: ' command])
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [new_Q, new_Q_ix]=insert_events(old_Q,old_Q_ix,events,last_t);
global global_event_Q

PURGE_LIMIT=50;

new_Q=[old_Q, events];

L=length(new_Q);
t=zeros(1,L);
for i=1:L
    t(i)=new_Q(i).time;
end
[tmp,ix]=sort(t);

ix1=find(t(ix)>=last_t); 
purge_Num=length(ix)-length(ix1);
if purge_Num>PURGE_LIMIT; PURGE=1; else PURGE=0; end
if PURGE % purge old events from Q
    global_event_Q=[global_event_Q, old_Q(1:purge_Num)];
    new_Q=new_Q(ix(ix1));
    new_Q_ix=old_Q_ix-purge_Num;
else
    new_Q=new_Q(ix);
    new_Q_ix=old_Q_ix;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function print_event(e, offset,force)
persistent h_list ct str
if (~sim_params('get', 'PRINT_EVENTS'))&sim_params('get', 'SIMULATION_RUNNING')&nargin<3, return, end
if nargin<2, offset=0; end
if nargin>2, ct=100; end % force event update
MAX_LINES=100;
if ischar(e) % init or finish
    if findstr(e, 'init')
        clear=1; ct=100;
        h_list=findall(0, 'tag', 'message_list');
        disp_str=e; list_str={e};
        %plot_event('init')
    elseif findstr(e, 'Running')
        clear=1; ct=100;
        disp_str=e; list_str={e};
    else % finish
        clear=0; MAX_LINES=inf; % prevent list truncation
        disp_str=e; list_str={e}; ct=100; % ensure to update listbox
    end
else
    len_e=length(e);
    if len_e>1,
        clear=1; 
        list_str=[];
    else
        clear=0;
        list_str=[];
    end
    
    for ev_ix=1:len_e
        [sim_t, event, ID, data]=get_event(e(ev_ix));
        sim_t_sec=sim_t*sim_params('get', 'BIT_TIME');
        list_stri=sprintf('%7d %6.2f  %-26s %5d', floor(sim_t), sim_t_sec, event, ID);
        list_str=[list_str; {list_stri}];
    end
    if len_e >1
        disp_str=[]; ct=100;
    else
        disp_str=sprintf('t:%7d (%6.2fs), %-27s ID:%3d', floor(sim_t), sim_t_sec, [event ','], ID);
        %plot_event(e)
    end
end

if ~isempty(h_list) 
    %str=get(h_list, 'string');
    if clear
        str=list_str;
    else
        if length(str)>MAX_LINES-1;
            str=[str(end-MAX_LINES+1:end); list_str];
        else
            str=[str; list_str];
        end
    end
    if ct>10 % do not update list too frequently; it's too slow
        set(h_list, 'string',  str, 'listboxtop', max(1, length(str)-1), 'value', length(str)-offset)
        ct=0;
    end
    ct=ct+1;
else
    % disp(disp_str)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plot_event(varargin)
persistent h hr hg hy ht hf ax updatetime
upd=sim_params('get', 'ANIMATE');
if ischar(varargin{1}) % command
    cmd=varargin{1};
    if ~upd&~strcmp(cmd, 'init')
        return
    end
else
    if ~upd
        return
    end
    cmd='update';
    event_struct=varargin{1};
    [t, event, ID, data]=get_event(event_struct);
end
[topology, mote_IDs]=prowler('GetTopologyInfo');
drw=0; % init draw update flag
switch cmd
case 'Refresh'  % refresh handles which could be changed when display changed
    ax=findall(0, 'tag', 'simulation_plot_ax');
    ch=allchild(ax);
    lines=findobj(ch, 'flat', 'type', 'line');
    texts=findobj(ch, 'flat', 'type', 'text');
    for i=1:length(h)
        h(i) =findobj(lines, 'flat', 'tag', ['DisplayObjMote' num2str(i)]);
        hr(i)=findobj(lines, 'flat', 'tag', ['rLED' num2str(i)]);
        hg(i)=findobj(lines, 'flat', 'tag', ['gLED' num2str(i)]);
        hy(i)=findobj(lines, 'flat', 'tag', ['yLED' num2str(i)]);
        ht(i)=findobj(texts, 'flat', 'tag', ['DisplayObjTxt' num2str(i)]);
        hf(i)=findobj(lines, 'flat', 'tag', ['LED_frame' num2str(i)]);
    end
    plot_line('refresh')
    
    
case {'init', 'Redraw'}
    
    ax=findall(0, 'tag', 'simulation_plot_ax');
    if ~isempty(ax)
        Mx=max(topology(:,1)); mx=min(topology(:,1));
        My=max(topology(:,2)); my=min(topology(:,2));
        
        if Mx-mx<1, Mx=Mx+.5; mx=mx-.5; end
        if My-my<1, My=My+.5; my=my-.5; end
        %sc=0.001; mx=mx-sc*abs(mx); my=my-sc*abs(my); Mx=Mx+sc*abs(Mx); My=My+sc*abs(My);
        deltaX=Mx-mx;
        deltaY=My-my;
        DX=deltaX/50; DY=-deltaY/50;
        
        if strcmp(cmd, 'init')
            updatetime=clock;
            delete(allchild(ax));
            set(ax, 'nextplot', 'add')
            axis(ax, [mx-1*DX Mx+6*DX my+4*DY My-3*DY])
            h=[]; hr=[]; hg=[]; hy=[]; ht=[]; hf=[];
            for i=1:length(mote_IDs)
                PX=topology(i, 1); PY=topology(i, 2);
                h(i)=plot(PX,PY,'.', 'parent', ax, ...
                    'userdata', mote_IDs(i), 'buttondownfcn', 'prowler(''GuiMouseMoteClick'', gcbo)', 'tag', ['DisplayObjMote' num2str(i)]);
                hr(i)=plot(PX+1.5*DX,PY+DY,'.r', 'parent', ax, 'tag', ['rLED' num2str(i)], 'userdata', [1   0   0]);
                hg(i)=plot(PX+2.5*DX,PY+DY,'.g', 'parent', ax, 'tag', ['gLED' num2str(i)], 'userdata', [0   1   0]);
                hy(i)=plot(PX+3.5*DX,PY+DY,'.y', 'parent', ax, 'tag', ['yLED' num2str(i)], 'userdata', [1   0.6 0]);
                hf(i)=line(PX+[.7*DX, .7*DX 4*DX 4*DX .7*DX],...
                    PY+[DY/2 DY*3/2 DY*3/2 DY/2 DY/2], 'parent', ax, 'tag', ['LED_frame' num2str(i)]);
                ht(i)=text(PX+.5*DX,PY-DY,' ', 'FontSize', 8, 'clipping', 'on', 'parent', ax, 'tag', ['DisplayObjTxt' num2str(i)]);
            end
            set([hr hg hy], 'markersize', 6, 'color', [1 1 1])
            set([hr hg hy hf], 'buttondownfcn', '3.1415926;', 'hittest', 'off'); % search purposes
            plot_line('init')
            drawnow
        else
            for i=1:length(mote_IDs)
                PX=topology(i, 1); PY=topology(i, 2);
                set(h(i), 'xdata', PX, 'ydata', PY);
                set(hr(i), 'xdata', PX+1.5*DX, 'ydata', PY+DY);
                set(hg(i), 'xdata', PX+2.5*DX, 'ydata', PY+DY);
                set(hy(i), 'xdata', PX+3.5*DX, 'ydata', PY+DY);
                set(hf(i), 'xdata', PX+[.7*DX, .7*DX 4*DX 4*DX .7*DX], ...
                    'ydata',  PY+[DY/2 DY*3/2 DY*3/2 DY/2 DY/2]);
                set(ht(i), 'position', [PX+.5*DX,PY-DY]);
            end
            plot_line('redraw')
        end
        drw=1;
    end
case 'update'
    if ~isempty(ax)
        ix=find(mote_IDs==ID);
        a=feval(prowler('GetAnimationName'));
        for i=1:length(a)
            if strcmpi(a(i).event, event)
                if a(i).animated
                    switch a(i).animated
                    case 1 % the mote 
                        if ~isempty(a(i).color), set(h(ix), 'color', a(i).color); end
                        if ~isempty(a(i).size),  set(h(ix), 'markersize',  a(i).size);  end
                    case {2,3,4} % LEDs
                        if a(i).color(1)
                            mode='on';
                        elseif a(i).color(2)
                            mode='off';
                        else
                            mode='toggle';
                        end
                        switch a(i).animated
                        case 2 % red LED
                            h_LED=hr(ix);
                        case 3 % green LED
                            h_LED=hg(ix);
                        case 4 % yellow LED
                            h_LED=hy(ix);
                        end
                        cur_col=get(h_LED, 'color');
                        on_col =get(h_LED, 'userdata');
                        if strcmp('toggle', mode)
                            if cur_col==on_col
                                mode='off';
                            else
                                mode='on';
                            end
                        end
                        if strcmp('on', mode)
                            set(h_LED, 'color', on_col);
                        else
                            set(h_LED, 'color', [1 1 1]);
                        end
                    end
                    drw=1;
                end
                break
            end
        end
    end
case 'TextMessage'
    if ~isempty(ax)
        ID=varargin{2};
        txt=varargin{3};
        ix=find(mote_IDs==ID);
        set(ht(ix), 'string', txt)
        drw=1;
    end
case 'LED'
    if ~isempty(ax)
        ID=varargin{2};
        msg=varargin{3};
        ix=find(mote_IDs==ID);
        if findstr(lower(msg), 'red');    h_LED=hr(ix); 
        elseif findstr(lower(msg), 'green');  h_LED=hg(ix); 
        elseif findstr(lower(msg), 'yellow'); h_LED=hy(ix); 
        else error(['Bad LED color in command ' msg]); 
        end
        
        cur_col=get(h_LED, 'color');
        on_col =get(h_LED, 'userdata');
        
        if findstr(lower(msg), 'on');     mode='on';  
        elseif findstr(lower(msg), 'off');    mode='off'; 
        elseif findstr(lower(msg), 'toggle');    
            if cur_col==on_col; mode='off'; else mode='on'; end
        else error(['Bad LED state in command ' msg]); 
        end
        
        if strcmp('on', mode)
            set(h_LED, 'color', on_col);
        else
            set(h_LED, 'color', [1 1 1]);
        end
        drw=1;
    end
end

if drw*0  % drawnow's are managed in the main loop
    if upd==1 % fast update
        % drawnow necessary
        drwnow=1;
    else % slow update
        % check update time
        if etime(clock, updatetime)>5
            drwnow=1;
        else
            drwnow=0;
        end
    end
    if drwnow
        drawnow;
        updatetime=clock;
    end
end

function plot_line(command, ID1, ID2, varargin)
persistent table
% table contains current lines (or arrows) in the following format: 
% each line (arrow) has a row in the table: {ID1_i, ID2_i, handle_i, command, varargin}

command=lower(command);

if nargin>3
    style=varargin;
else
    style=[];
end

switch command
case {'line', 'arrow', 'delete'}
    if ~sim_params('get', 'ANIMATE');
        return
    end
    [topology, mote_IDs]=prowler('GetTopologyInfo');
    %delete all lines, added by YZ
    if strcmp(command, 'delete') & isinf(ID1) & isinf(ID2)
        if (~isempty(table))
            h = [table{:,3}];
            delete(h);
            table = {};
        end
        return;
    end
    %end added by YZ
    if strcmp(command, 'delete') & isinf(ID1+ID2)
        ct=1; % special delete all syntax, only ID1 is needed
    else
        ct=0; % two ID's required
    end
    for ix=1:length(mote_IDs)
        if mote_IDs(ix) == ID1
            ix1=ix; ct=ct+1;
        elseif  mote_IDs(ix) == ID2
            ix2=ix; ct=ct+1;
        end
        if ct>1
            break
        end
    end
    if ct<2 % ID not found
        error(sprintf('Bad ID for line draw: %d, %d', ID1, ID2))
    else
        ax=findall(0, 'tag', 'simulation_plot_ax');
        if ~isempty(ax)
            % search for line in the table; if exists, remove
            len_t=size(table,1);
            for t_ix=1:len_t
                if table{t_ix, 1}==ID1 & table{t_ix, 2}==ID2
                    h=table{t_ix, 3};
                    table(t_ix,:)=[];
                    delete(h);
                    break
                end
            end
            if strcmp(command, 'delete')   
                if isinf(ID1+ID2)  % delete all
                    if isinf(ID1)
                        ID_ix=2; ID_val=ID2;
                    else
                        ID_ix=1; ID_val=ID1;
                    end
                    
                    del_h=[]; del_ix=[];
                    for t_ix=1:len_t
                        if table{t_ix, ID_ix}==ID_val
                            del_h=[del_h, table{t_ix, 3}];
                            del_ix=[del_ix, t_ix];
                        end
                    end
                    table(del_ix,:)=[];
                    delete(del_h);
                end
                return
            end
            
            x1=topology(ix1,1); y1=topology(ix1,2); 
            x2=topology(ix2,1); y2=topology(ix2,2); 
            
            if strcmp(command, 'arrow')   
                
                phi=pi/10;  % arrow angle
                L=0.03;     % arrow size constant
                
                xa = get(ax,'xlim');
                ya = get(ax,'ylim');
                set(ax, 'unit', 'points');
                pos= get(ax,'position');
                xp=pos(3); yp=pos(4); % axis size in figure
                xd = xa(2)-xa(1);     % axis limits
                yd = ya(2)-ya(1); 
                scalex = L*xd/xp*yp; % compensate aspect ratio
                scaley = L*yd; 
                
                dx = x1 - x2;
                dy = y1 - y2;
                
                alphac=atan2(dy/yd*yp, dx/xd*xp); % angle of line on screen
                
                xx = [x1, x2, x2+scalex*cos(alphac+phi), NaN, ...
                        x2, x2+scalex*cos(alphac-phi)]';
                yy = [y1, y2, y2+scaley*sin(alphac+phi), NaN, ...
                        y2, y2+scaley*sin(alphac-phi)]';
                
                hl=line(xx,yy, 'parent', ax, 'hittest', 'off', 'tag', 'DisplayArrow', 'userdata', [ID1, ID2]);
                set(ax, 'unit', 'normalized');  % necessary for resizable external plot
            else % line
                hl=line([x1,x2], [y1,y2], 'parent', ax, 'hittest', 'off', 'tag', 'DisplayArrow', 'userdata', [ID1, ID2]);
            end
            if ~isempty(style)
                set(hl,  style{:})
            end
            table=[table; {ID1, ID2, hl, command, varargin}];
        end
    end
case 'init'
    table={};
case 'refresh'
    ax=findall(0, 'tag', 'simulation_plot_ax');
    h_arr=findobj(allchild(ax), 'flat', 'tag', 'DisplayArrow');
    new_table=table;
    for i=1:length(h_arr)
        ix=get(h_arr(i),'userdata');
        for j=1:length(h_arr)
            if table{j,1}==ix(1) & table{j,2}==ix(2)
                new_table{j,3}=h_arr(i);
                break
            end
        end
    end
    table=new_table;
    
case 'redraw'
    [topology, mote_IDs]=prowler('GetTopologyInfo');
    len_t=size(table,1);
    table_old=table;
    for t_ix=1:len_t
        ID1=table_old{t_ix,1};
        ID2=table_old{t_ix,2};
        command=table_old{t_ix,4};
        xtra=table_old{t_ix,5};
        plot_line(command, ID1, ID2, xtra{:})
    end
end

function out=AdjustTipButton(app_name)
% Enables Application Info pushbutton if _info file exists for the application,
% disables otherwise. Returns the info file name.
h_fig=findobj(allchild(0), 'flat', 'tag', 'Simulation_Fig');
h_tip=findobj(allchild(h_fig), 'flat', 'tag', 'Application_tips');
infofile=[app_name, '_info'];
if exist([infofile '.m'], 'file')
    set(h_tip, 'enable', 'on')
    out=infofile;
else
    set(h_tip, 'enable', 'off')
    out=[];
end


function out=SetApplicationParams(app_name)
% Checks if application parameters are defined.
% If not, set the default.
h_fig=findobj(allchild(0), 'flat', 'tag', 'Simulation_Fig');
h_par=findobj(allchild(h_fig), 'flat', 'tag', 'Application_params');
paramfile=[app_name, '_params'];
if exist([paramfile '.m'], 'file')
    set(h_par, 'enable', 'on')
    p=feval(paramfile);
    for i=1:length(p)
        if isempty(sim_params('get_app', p(i).name))
            if iscell(p(i).default) % popupmenu, the first element is the default
                sim_params('set_app', p(i).name, p(i).default{1});
            else
                sim_params('set_app', p(i).name, p(i).default);
            end
        end
    end
    out=paramfile;
else
    set(h_par, 'enable', 'off')
    out=[];
end

%Added by YZ for radio parameters
function out=SetRadioParams(radio_name)
% Checks if radio parameters are defined.
% If not, set the default.

paramfile=[radio_name, '_params'];
if exist([paramfile '.m'], 'file')
    p=feval(paramfile);
    for i=1:length(p)
        if isempty(sim_params('get_radio', p(i).name))
            if iscell(p(i).default) % popupmenu, the first element is the default
                sim_params('set_radio', p(i).name, p(i).default{1});
            else
                sim_params('set_radio', p(i).name, p(i).default);
            end
        end
    end
    out=paramfile;
else
    out=[];
end
%end of radio parameters

function SwitchDisplay(mode)
% switch between internal and external display modes

switch mode
case 'out'
    h_sim_fig=findall(0, 'tag', 'Simulation_Fig');
    h_ax=findall(h_sim_fig, 'tag', 'simulation_plot_ax');
    if ~isempty(h_ax)
        set(h_ax, 'tag', 'inactive_simulation_plot_ax')
        h=findall(0, 'tag', 'simulation_plot_ax'); delete(h); % just in case...
        
        h_fig=figure(...
            'name', 'Prowler - Display',...
            'numbertitle', 'off', ...
            'integerhandle', 'off', ...
            'closerequestfcn', 'prowler(''SwitchDisplay'', ''in'')', ...
            'handlevisibility', 'off', ...
            'units', 'pixels', ...
            'tag', 'Prowler_External_Display_fig');
        
        h_ax_new=copyobj(h_ax, h_fig);
        delete(allchild(h_ax))
        set(h_ax, 'buttondownfcn', 'figure(findall(0,''tag'', ''Prowler_External_Display_fig''))');

        set(h_ax_new, ...
            'unit', 'normalized',...
            'position', [0 0 1 1], ...
            'tag', 'simulation_plot_ax');
        xx=get(h_ax, 'Xlim'); yy=get(h_ax, 'Ylim');
        plot([xx(2) xx(1) nan xx(1) xx(2)], [yy(1) yy(2) nan yy(1) yy(2)], 'parent', h_ax)
        
    end
case 'in'
    h_sim_fig=findall(0, 'tag', 'Simulation_Fig');
    h_ext_fig=findall(0, 'tag', 'Prowler_External_Display_fig');
    h_ax=findall(h_ext_fig, 'tag', 'simulation_plot_ax');
    if ~isempty(h_ax)
        set(h_ax, 'tag', 'external_simulation_plot_ax');
        
        h=findall(0, 'tag', 'simulation_plot_ax'); delete(h); % just in case...
        
        h_ax_old=findall(h_sim_fig, 'tag', 'inactive_simulation_plot_ax');
        h_ax_new=copyobj(h_ax, h_sim_fig);
        set(h_ax_new, ...
            'unit', get(h_ax_old, 'unit'), ...
            'position', get(h_ax_old, 'position'), ...
            'tag', 'simulation_plot_ax');
        delete(h_ax_old)
        delete(h_ext_fig)
    end
end
plot_event('Refresh'); % update handles