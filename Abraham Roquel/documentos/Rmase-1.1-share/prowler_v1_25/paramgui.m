function varargout = paramgui(varargin)
% parameter setting GUI for prowler

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
    %rmappdata(fig, 'radio_specific_UIC_list');
	% Use system color scheme for figure:
	set(fig,'Color',get(0,'defaultUicontrolBackgroundColor'));

	% Generate a structure of handles to pass to callbacks, and store it. 
	handles = guihandles(fig);
	guidata(fig, handles);

	if nargout > 0
		varargout{1} = fig;
	end

elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK

	try
		if (nargout)
			[varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
		else
			feval(varargin{:}); % FEVAL switchyard
		end
	catch
		disp(lasterr);
	end

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
function varargout = paramgui_SIGNAL_FCN_Callback(h, eventdata, handles, varargin)
prowparams('plot_fx')


% --------------------------------------------------------------------
function varargout = paramgui_RADIO_SS_VAR_CONST_Callback(h, eventdata, handles, varargin)
prowparams('check_edit', h, 'x>=0, refresh');

% --------------------------------------------------------------------
function paramgui_RADIO_RAYLEIGH_COH_Callback(h, eventdata, handles, varargin)
prowparams('check_edit', h, 'x>=0, refresh');

% --------------------------------------------------------------------
%function paramgui_RADIO_RAYLEIGH_2_Callback(h, eventdata, handles, varargin)
%prowparams('check_edit', h, 'x>=0, refresh');

% --------------------------------------------------------------------
function varargout = paramgui_RADIO_SS_VAR_RAND_Callback(h, eventdata, handles, varargin)
prowparams('check_edit', h, 'x>=0, refresh');

% --------------------------------------------------------------------
function varargout = paramgui_PLOT_PARS_range_Callback(h, eventdata, handles, varargin)
prowparams('check_edit', h, 'x>0, refresh');


% --------------------------------------------------------------------
function varargout = paramgui_PLOT_PARS_linlog_Callback(h, eventdata, handles, varargin)
prowparams('plot_fx')


% --------------------------------------------------------------------
function varargout = paramgui_RECEPTION_LIMIT_Callback(h, eventdata, handles, varargin)
prowparams('check_edit', h, 'x>=0, refresh');


% --------------------------------------------------------------------
function varargout = paramgui_TR_ERROR_PROB_Callback(h, eventdata, handles, varargin)
prowparams('check_edit', h, 'x>=0, x<=1');




% --------------------------------------------------------------------
function varargout = paramgui_MAC_MIN_WAITING_TIME_Callback(h, eventdata, handles, varargin)
prowparams('check_edit', h, 'x>=0');

% --------------------------------------------------------------------
function varargout = paramgui_MAC_RAND_WAITING_TIME_Callback(h, eventdata, handles, varargin)
prowparams('check_edit', h, 'x>=0');

% --------------------------------------------------------------------
function varargout = paramgui_MAC_MIN_BACKOFF_TIME_Callback(h, eventdata, handles, varargin)
prowparams('check_edit', h, 'x>=0');

% --------------------------------------------------------------------
function varargout = paramgui_MAC_RAND_BACKOFF_TIME_Callback(h, eventdata, handles, varargin)
prowparams('check_edit', h, 'x>=0');

% --------------------------------------------------------------------
function varargout = paramgui_MAC_PACKET_LENGTH_Callback(h, eventdata, handles, varargin)
prowparams('check_edit', h, 'x>=0');

% --------------------------------------------------------------------
function varargout = paramgui_STOP_SIM_TIME_Callback(h, eventdata, handles, varargin)
prowparams('check_edit', h, 'x>0');


% --------------------------------------------------------------------
function varargout = paramgui_apply_Callback(h, eventdata, handles, varargin)
prowparams('apply');

% --------------------------------------------------------------------
function varargout = paramgui_close_Callback(h, eventdata, handles, varargin)
prowparams('apply');
delete(handles.paramgui_fig)

% --------------------------------------------------------------------
function varargout = paramgui_load_Callback(h, eventdata, handles, varargin)
prowparams('loadgui');

% --------------------------------------------------------------------
function varargout = paramgui_save_Callback(h, eventdata, handles, varargin)
prowparams('savegui');

% --------------------------------------------------------------------
function varargout = paramgui_default_Callback(h, eventdata, handles, varargin)
prowparams('loaddefault');

% --------------------------------------------------------------------
function varargout = paramgui_cancel_Callback(h, eventdata, handles, varargin)
delete(handles.paramgui_fig)

% --------------------------------------------------------------------
function varargout = paramgui_help_Callback(h, eventdata, handles)
prowparams('help')


% ND VERSION OBJECTS
function paramgui_RECEPTION_SINR_Callback(h, eventdata, handles)
prowparams('check_edit', h, 'x>0, refresh');


function paramgui_REC_NOISE_VAR_Callback(h, eventdata, handles)
prowparams('check_edit', h, 'x>=0, refresh');


function paramgui_IDLE_LIMIT_Callback(h, eventdata, handles)
prowparams('check_edit', h, 'x>1, refresh');


% add radio specific information (change GUI according to radio needs)
function paramgui_RECEPTION_LIMIT_text_CreateFcn(hObject, eventdata, handles)
prowparams('add_radio_specific_UIC', hObject, 'radio_model_1', 'enable', 'on')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_2', 'enable', 'off')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_3', 'enable', 'off')

function paramgui_RECEPTION_SINR_text_CreateFcn(hObject, eventdata, handles)
prowparams('add_radio_specific_UIC', hObject, 'radio_model_1', 'enable', 'off')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_2', 'enable', 'on')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_3', 'enable', 'on')

function paramgui_REC_NOISE_VAR_text_CreateFcn(hObject, eventdata, handles)
prowparams('add_radio_specific_UIC', hObject, 'radio_model_1', 'enable', 'off')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_2', 'enable', 'on')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_3', 'enable', 'on')

function paramgui_IDLE_LIMIT_text_CreateFcn(hObject, eventdata, handles)
prowparams('add_radio_specific_UIC', hObject, 'radio_model_1', 'enable', 'off')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_2', 'enable', 'on')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_3', 'enable', 'on')

function paramgui_RECEPTION_LIMIT_CreateFcn(hObject, eventdata, handles)
prowparams('add_radio_specific_UIC', hObject, 'radio_model_1', 'enable', 'on')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_2', 'enable', 'off')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_3', 'enable', 'off')

function paramgui_RECEPTION_SINR_CreateFcn(hObject, eventdata, handles)
prowparams('add_radio_specific_UIC', hObject, 'radio_model_1', 'enable', 'off')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_2', 'enable', 'on')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_3', 'enable', 'on')

function paramgui_REC_NOISE_VAR_CreateFcn(hObject, eventdata, handles)
prowparams('add_radio_specific_UIC', hObject, 'radio_model_1', 'enable', 'off')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_2', 'enable', 'on')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_3', 'enable', 'on')

function paramgui_IDLE_LIMIT_CreateFcn(hObject, eventdata, handles)
prowparams('add_radio_specific_UIC', hObject, 'radio_model_1', 'enable', 'off')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_2', 'enable', 'on')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_3', 'enable', 'on')

function paramgui_Fading_title_CreateFcn(hObject, eventdata, handles)
prowparams('add_radio_specific_UIC', hObject, 'radio_model_1', 'string', ' Fading effect')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_2', 'string', ' Fading effect')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_3', 'string', ' Rayleigh fading')


function paramgui_text_alpha_CreateFcn(hObject, eventdata, handles)
prowparams('add_radio_specific_UIC', hObject, 'radio_model_1', 'string', ' s_alpha=')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_2', 'string', ' s_alpha=')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_3', 'string', ' tau =')

function paramgui_text_beta_CreateFcn(hObject, eventdata, handles)
prowparams('add_radio_specific_UIC', hObject, 'radio_model_1', 'string', ' s_beta=')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_2', 'string', ' ')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_3', 'string', ' ')

function paramgui_fadingtext_1_CreateFcn(hObject, eventdata, handles)
prowparams('add_radio_specific_UIC', hObject, 'radio_model_1', 'string', ' P_rec=P_Rec_id*(1+alpha(x))*(1+beta(t)),')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_2', 'string', ' P_rec=P_Rec_id*(1+alpha(x)),')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_3', 'string', ' P_rec=P_Rec_id*R, where R is a random')

function paramgui_fadingtext_2_CreateFcn(hObject, eventdata, handles)
prowparams('add_radio_specific_UIC', hObject, 'radio_model_1', 'string', 'where alpha and beta are random variables')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_2', 'string', 'where alpha is a random variable')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_3', 'string', 'variable with exp distribution (mu=1).')

function paramgui_fadingtext_3_CreateFcn(hObject, eventdata, handles)
prowparams('add_radio_specific_UIC', hObject, 'radio_model_1', 'string', 'with normal distribution N(0,s):')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_2', 'string', 'with normal distribution N(0,s):')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_3', 'string', 'The coherence time is tau.')

function paramgui_RADIO_SS_VAR_CONST_CreateFcn(hObject, eventdata, handles)
prowparams('add_radio_specific_UIC', hObject, 'radio_model_1', 'visible', 'on')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_2', 'visible', 'on')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_3', 'visible', 'off')


function paramgui_RADIO_SS_VAR_RAND_CreateFcn(hObject, eventdata, handles)
prowparams('add_radio_specific_UIC', hObject, 'radio_model_1', 'visible', 'on')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_2', 'visible', 'off')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_3', 'visible', 'off')


function paramgui_RADIO_RAYLEIGH_COH_CreateFcn(hObject, eventdata, handles)
prowparams('add_radio_specific_UIC', hObject, 'radio_model_1', 'visible', 'off')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_2', 'visible', 'off')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_3', 'visible', 'on')

function paramgui_RADIO_RAYLEIGH_2_CreateFcn(hObject, eventdata, handles)
prowparams('add_radio_specific_UIC', hObject, 'radio_model_1', 'visible', 'off')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_2', 'visible', 'off')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_3', 'visible', 'off')

function paramgui_unit_text_1_CreateFcn(hObject, eventdata, handles)
prowparams('add_radio_specific_UIC', hObject, 'radio_model_1', 'string', '')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_2', 'string', '')
prowparams('add_radio_specific_UIC', hObject, 'radio_model_3', 'string', 'sec')

