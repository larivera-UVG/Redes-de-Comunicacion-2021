function varargout = simgui(varargin)
% GUI for prowler

% ***	
% ***	 Copyright 2002, Vanderbilt University. All rights reserved.
% ***
% ***    This program is distributed in the hope that it will be useful,
% ***    but WITHOUT ANY WARRANTY; without even the implied warranty of
% ***    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% ***
% ***

% Written by Gyula Simon, gyula.simon@vanderbilt.edu
% Last modified: Dec 5, 2003  by GYS



if nargin == 0  % LAUNCH GUI

	fig = openfig(mfilename,'reuse');


	% Generate a structure of handles to pass to callbacks, and store it. 
	handles = guihandles(fig);
	guidata(fig, handles);

	if nargout > 0
		varargout{1} = fig;
	end
    set(fig, 'name', ['Prowler version ', prowler('version')])
    sim_params('set', 'APP_NAME', popupstr(handles.Application_def))
    sim_params('set', 'RADIO_NAME', popupstr(handles.Radio_def))
    prowler('init')
    
elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK
	%try
		if (nargout)
			[varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
		else
			feval(varargin{:}); % FEVAL switchyard
		end
        %catch
		%disp(lasterr);
        %end

end


%| ABOUT CALLBACKS:
%| GUIDE automatically appends subfunction prototypes to this file, and 
%| sets objects' callback properties to call them through the FEVAL 
%| switchyard above. This comment describes that mechanism.
%|
%| Each callback subfunction declaration has the following form:
%| <SUBFUNCTION_NAME>(H, EVENTDATA, HANDLES, VARARGIN)
%|
%| The subfunction name is composed using the object's Tag and the 
%| callback type separated by '_', e.g. 'slider2_Callback',
%| 'figure1_CloseRequestFcn', 'axis1_ButtondownFcn'.
%|
%| H is the callback object's handle (obtained using GCBO).
%|
%| EVENTDATA is empty, but reserved for future use.
%|
%| HANDLES is a structure containing handles of components in GUI using
%| tags as fieldnames, e.g. handles.figure1, handles.slider2. This
%| structure is created at GUI startup using GUIHANDLES and stored in
%| the figure's application data using GUIDATA. A copy of the structure
%| is passed to each callback.  You can store additional information in
%| this structure at GUI startup, and you can change the structure
%| during callbacks.  Call guidata(h, handles) after changing your
%| copy to replace the stored original so that subsequent callbacks see
%| the updates. Type "help guihandles" and "help guidata" for more
%| information.
%|
%| VARARGIN contains any extra arguments you have passed to the
%| callback. Specify the extra arguments by editing the callback
%| property in the inspector. By default, GUIDE sets the property to:
%| <MFILENAME>('<SUBFUNCTION_NAME>', gcbo, [], guidata(gcbo))
%| Add any extra arguments after the last argument, before the final
%| closing parenthesis.



% --------------------------------------------------------------------
function varargout = simulation_plot_ax_ButtonDownFcn(h, eventdata, handles, varargin)
% click on axes
prowler('Gui_Mouse_Axes_Click', get(h, 'currentpoint'))


% --------------------------------------------------------------------
function varargout = Application_def_Callback(h, eventdata, handles, varargin)
% application definition set
sim_params('set', 'APP_NAME', popupstr(h))
prowler('init')


% --------------------------------------------------------------------
function varargout = Radio_def_Callback(h, eventdata, handles, varargin)
% radio definition set
sim_params('set', 'RADIO_NAME', popupstr(h))
prowler('init')


% --------------------------------------------------------------------
function varargout = Simulation_start_Callback(h, eventdata, handles, varargin)
% simulation started
prowler('init')
prowler('startsimulation')


% --------------------------------------------------------------------
function varargout = Application_def_CreateFcn(h, eventdata, handles, varargin)
[app, radio]=register_applications;
set(h, 'string', app)


% --------------------------------------------------------------------
function varargout = Radio_def_CreateFcn(h, eventdata, handles, varargin)
[app, radio]=register_applications;
set(h, 'string', radio)

% --------------------------------------------------------------------
function varargout = Simulation_stop_Callback(h, eventdata, handles, varargin)
prowler('StopSimulation')



% --------------------------------------------------------------------
function varargout = Simulation_continue_Callback(h, eventdata, handles, varargin)
prowler('StartSimulation')


% --------------------------------------------------------------------
function varargout = Simulation_parameters_Callback(h, eventdata, handles, varargin)
prowparams;

% --------------------------------------------------------------------
function Simulation_tips_Callback(hObject, eventdata, handles)
prowparams('help')

% --------------------------------------------------------------------
function Application_params_Callback(hObject, eventdata, handles)
prowler('ShowApplicationParams')

% --------------------------------------------------------------------
function Application_tips_Callback(hObject, eventdata, handles)
prowler('ShowApplicationInfo')

% --------------------------------------------------------------------
function varargout = show_distances_Callback(h, eventdata, handles, varargin)
prowler('show_distances')

% --------------------------------------------------------------------
function varargout = show_animation_Callback(h, eventdata, handles, varargin)
prowler('show_animation')

% --------------------------------------------------------------------
function varargout = show_events_Callback(h, eventdata, handles, varargin)
prowler('show_events')

% --------------------------------------------------------------------
function varargout = showLEDs_Callback(h, eventdata, handles, varargin)
prowler('show_LEDs')

% --------------------------------------------------------------------
function varargout = external_display_Callback(h, eventdata, handles, varargin)
prowler('SwitchDisplay')

% --------------------------------------------------------------------

function Simulation_Fig_CloseRequestFcn(hObject, eventdata, handles)
prowler('CloseGui')




% the following lines are in the nargin==0 part, 
% here they are repeated to prevent GUIDE from deleting them
%    set(fig, 'name', 'Prowler v1.1')
%    sim_params('set', 'APP_NAME', popupstr(handles.Application_def))
%    sim_params('set', 'RADIO_NAME', popupstr(handles.Radio_def))
%    prowler('init')


