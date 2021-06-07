function appparamw(varargin)
% function AppParamW(application_name)
% generate window for application parameter setting

% ***	
% ***	 Copyright 2002, Vanderbilt University. All rights reserved.
% ***
% ***    This program is distributed in the hope that it will be useful,
% ***    but WITHOUT ANY WARRANTY; without even the implied warranty of
% ***    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% ***
% ***

% Written by Gyula Simon, gyula.simon@vanderbilt.edu
% Last modified: Sep 24, 2002  by GYS

% Modified by Lukas D. Kuhn, lukas.kuhn@parc.com
% Last modified: Dec 8, 2003

command=varargin{1};
switch command
    case 'init'
        app_name=varargin{2};
        try
            def_params = feval([app_name '_params']);
        catch
            def_params=[];
        end
        if isempty(def_params)
            error(['Application parameters are not defined for ''' app_name '''.'])
        end
        % checking if the parameters are using group classification
        % at the Parameter window you will allways see only one group shown, 
        % the other parameter uicontrols are invisible
        % if group classification is not used this loops def. that all
        % parameters are group 1 
        nogroup=0;
        try
            x=def_params(1).group;
        catch
            for i=1:length(def_params)
                def_params(i).group = 1;
                def_params(i).groupname = 'none';
            end
            nogroup=1;
        end
        try
            type = def_params(1).type;
        catch
            for i=1:length(def_params)
                def_params(i).type = 'edit';
            end
        end
        
        h_fig=findobj(allchild(0), 'tag', 'Prowler_Application_Parameters_fig');
        if ~isempty(h_fig), delete(h_fig), end
        
        scr=get(0,'ScreenSize');
        col=get(0, 'DefaultUiControlBackgroundColor');
        fig_x=380; fig_y=600;
        h_fig=figure(...
            'color', col, ...
            'name', 'Prowler - Application Parameters',...
            'numbertitle', 'off', ...
            'integerhandle', 'off', ...
            'handlevisibility', 'off', ...
            'units', 'pixels', ...
            'position', [300, scr(4)-100-fig_y, fig_x, fig_y],...
            'menubar', 'none',...
            'visible', 'off', ...
            'tag', 'Prowler_Application_Parameters_fig');
        
        
        % generate pusbuttons
        
        h_default=uicontrol('parent', h_fig, ...
            'style', 'pushbutton', ...
            'units', 'pixels', ...
            'position', [20, 10, 70, 25],...
            'string', 'Deafult', ...
            'HorizontalAlignment', 'center', ...
            'callback', 'appparamw(get(gcbo, ''tag''))', ...
            'tag', 'appparamw_default_pb');
        
        h_apply=uicontrol('parent', h_fig, ...
            'style', 'pushbutton', ...
            'units', 'pixels', ...
            'position', [110, 10, 70, 25],...
            'string', 'Apply', ...
            'HorizontalAlignment', 'center', ...
            'callback', 'appparamw(get(gcbo, ''tag''))', ...
            'tag', 'appparamw_apply_pb');
        
        h_close=uicontrol('parent', h_fig, ...
            'style', 'pushbutton', ...
            'units', 'pixels', ...
            'position', [200, 10, 70, 25],...
            'string', 'Close', ...
            'HorizontalAlignment', 'center', ...
            'callback', 'appparamw(get(gcbo, ''tag''))', ...
            'tag', 'appparamw_close_pb');
        
        h_cancel=uicontrol('parent', h_fig, ...
            'style', 'pushbutton', ...
            'units', 'pixels', ...
            'position', [290, 10, 70, 25],...
            'string', 'Cancel', ...
            'HorizontalAlignment', 'center', ...
            'callback', 'appparamw(get(gcbo, ''tag''))', ...
            'tag', 'appparamw_cancel_pb');
        
        % genarate frame
        h_frame=uicontrol('parent', h_fig, ...
            'style', 'frame', ...
            'units', 'pixels', ...
            'position', [1,1,1,1]);
        
        
        
        % genarate group pop up menu
        grostr={};
        gronum=[];
        count=zeros(1,length(def_params));
        for i=1:length(def_params)
            for j=1:length(def_params)
                if(def_params(j).group == i & ~ismember(i,gronum))
                    gronum=[gronum; i];
                    grostr=vertcat(grostr, {def_params(j).groupname});
                end
                if(def_params(j).group == i)
                    count(1,i)=count(1,i)+1;
                end
            end
        end
        wsize=max(count);
        % the size of the window depends on the size of the biggest group
        name_x=20; name_dx=160; name_dy=20; y1=100; y=(wsize*23)+y1;
        
        
        groupname=uicontrol('parent', h_fig, ...
                'style', 'text', ...
                'units', 'pixels', ...
                'position', [name_x,  y, name_dx, name_dy],...
                'string', 'Parameter Groups = ', ...
                'HorizontalAlignment', 'right');
        grouppum=uicontrol('parent', h_fig, ...
                'style', 'popupmenu', ...
                'units', 'pixels', ...
                'position', [name_x+name_dx+20,  y, name_dx, name_dy],...
                'string', grostr, ...
                'callback', 'appparamw(get(gcbo, ''tag''))',...
                'tag', 'appparamw_selectgroup_pum',...
                'HorizontalAlignment', 'right');    
        if(nogroup)
            set(groupname, 'visible','off');
            set(grouppum, 'visible','off');
        end
        
        
        % the parameter uicontrols are created in the same order how they are shown in the window,
        % so you can walk thru in the right direction with the Tab        
        groups=def_params(length(def_params)).group;
        pnum=length(def_params);
        for j=1:groups
            y=(wsize*23)+75;
            for i=1:pnum
                if(def_params(i).group == j)
                    % generate name text
                    h_name(i)=uicontrol('parent', h_fig, ...
                        'style', 'text', ...
                        'units', 'pixels', ...
                        'position', [name_x,  y, name_dx, name_dy],...
                        'string', [def_params(i).name ' = '], ...
                        'tag',num2str(def_params(i).group),...
                        'visible','off',...
                        'HorizontalAlignment', 'right');
                    % parameter type popupmenu
                    if strcmpi(def_params(i).type, 'popupmenu')
                        if iscell(def_params(i).default)
                            h_value(i)=uicontrol('parent', h_fig, ...
                                'style', 'popupmenu', ...
                                'units', 'pixels', ...
                                'position', [name_x+name_dx+20,  y, name_dx, name_dy],...
                                'string', def_params(i).default, ...
                                'tag',num2str(def_params(i).group),...
                                'visible','off',...
                                'HorizontalAlignment', 'left');
                        else
                            h_value(i)=uicontrol('parent', h_fig, ...
                                'style', 'popupmenu', ...
                                'units', 'pixels', ...
                                'position', [name_x+name_dx+20,  y, name_dx, name_dy],...
                                'string', def_params(i).data, ...
                                'tag',num2str(def_params(i).group),...
                                'visible','off',...
                                'HorizontalAlignment', 'left');
                        end
                        y=y-name_dy-3;
                    % parameter type checkbox
                    elseif strcmpi(def_params(i).type, 'checkbox')
                        if iscell(def_params(i).default)
                            h_value(i)=uicontrol('parent', h_fig, ...
                                'style', 'checkbox', ...
                                'units', 'pixels', ...
                                'Max',1,...
                                'Min',0,...
                                'value',def_params(i).default,...
                                'position', [name_x+name_dx+20,  y, name_dx, name_dy],...
                                'string', def_params(i).name, ...
                                'tag',num2str(def_params(i).group),...
                                'visible','off',...
                                'HorizontalAlignment', 'left');
                        else
                            h_value(i)=uicontrol('parent', h_fig, ...
                                'style', 'checkbox', ...
                                'units', 'pixels', ...
                                'Max',1,...
                                'Min',0,...
                                'value',0,...
                                'position', [name_x+name_dx+20,  y, name_dx, name_dy],...
                                'string', def_params(i).name, ...
                                'tag',num2str(def_params(i).group),...
                                'visible','off',...
                                'HorizontalAlignment', 'left');
                        end
                        y=y-name_dy-3;
                    % parameter type edit (default)
                    else
                        if iscell(def_params(i).default)
                            h_value(i)=uicontrol('parent', h_fig, ...
                                'style', 'popup', ...
                                'units', 'pixels', ...
                                'position', [name_x+name_dx+20,  y, name_dx, name_dy],...
                                'string', def_params(i).default, ...
                                'tag',num2str(def_params(i).group),...
                                'visible','off',...
                                'HorizontalAlignment', 'left');
                        else
                            h_value(i)=uicontrol('parent', h_fig, ...
                                'style', 'edit', ...
                                'units', 'pixels', ...
                                'position', [name_x+name_dx+20,  y, name_dx, name_dy],...
                                'string', '-', ...
                                'tag',num2str(def_params(i).group),...
                                'visible','off',...
                                'HorizontalAlignment', 'left');
                        end
                        y=y-name_dy-3;
                    end
                end
            end
        end
        
        % set group #1 visible
        for i=1:length(h_value)
            if(str2num(get(h_value(i),'tag')) == 1)
                if(~strcmpi(get(h_value(i),'style'), 'checkbox'))
                    set(h_name(i),'visible', 'on');
                end
                set(h_value(i),'visible', 'on');
            end
        end
        
        % generate title text
        h_title=uicontrol('parent', h_fig, ...
            'style', 'text', ...
            'units', 'pixels', ...
            'position', [name_x,  y, name_dx*2+10, name_dy],...
            'string', ['Parameters for application ''' upper(app_name) ''''], ...
            'HorizontalAlignment', 'center');
        ex=get(h_title,'extent'); dx=ex(3);dy=ex(4);
        set(h_title, 'position', [fig_x/2-dx/2-2,(wsize*23)+150, dx+4, dy+2]); 
        set(h_frame,  'position', [10, 40, fig_x-20,(wsize*23)+150]);
        set(h_fig, ...
            'position', [300, 100, fig_x, (wsize*23)+200], ...
            'visible', 'on');
        
        % store application data
        appdata=struct('app_name', app_name, 'h_value', h_value, 'h_name', h_name, 'grouppum', grouppum);
        setappdata(h_fig, 'appdata', appdata);
        appparamw('appparamw_current')

        drawnow, set(h_fig, 'color', col)  % correct matlab 'feature'
        
        
    case 'appparamw_current'
        h_fig=findobj(allchild(0), 'tag', 'Prowler_Application_Parameters_fig');
        appdata=getappdata(h_fig, 'appdata');
        app_name=appdata.app_name;
        h_value =appdata.h_value;
        params=feval([app_name '_params']);
        for i=1:length(params)
            curr_param_values{i}=sim_params('get_app', params(i).name);
        end    
        fill_edits(h_value, curr_param_values)
        
    case 'appparamw_default_pb'
        h_fig=findobj(allchild(0), 'tag', 'Prowler_Application_Parameters_fig');
        appdata=getappdata(h_fig, 'appdata');
        app_name=appdata.app_name;
        h_value =appdata.h_value;
        def_params=feval([app_name '_params']);
        for i=1:length(def_params)
            def_param_values{i}=def_params(i).default;
        end    
        fill_edits(h_value, def_param_values)

    case 'appparamw_apply_pb'
        h_fig=findobj(allchild(0), 'tag', 'Prowler_Application_Parameters_fig');
        appdata=getappdata(h_fig, 'appdata');
        app_name=appdata.app_name;
        h_value =appdata.h_value;
        def_params=feval([app_name '_params']);
        for i=1:length(def_params)
            if strcmp(get(h_value(i),'style'), 'popupmenu')
                set_param_values_i=popupstr(h_value(i));
            elseif strcmp(get(h_value(i),'style'), 'checkbox')
                set_param_values_i=num2str(get(h_value(i),'value'));
            else    
                set_param_values_i=get(h_value(i),'string');
            end
            if isnumeric(def_params(i).default)  % must be numeric
                set_param_values_i=str2num(set_param_values_i);
            end
            sim_params('set_app', def_params(i).name, set_param_values_i)
        end    
        
    case 'appparamw_close_pb'
        h_fig=findobj(allchild(0), 'tag', 'Prowler_Application_Parameters_fig');
        appparamw('appparamw_apply_pb')
        delete(h_fig)
    case 'appparamw_cancel_pb'
        h_fig=findobj(allchild(0), 'tag', 'Prowler_Application_Parameters_fig');
        delete(h_fig)
    
    % if you changed the group it will change the parameter uicontrols
    % form visible to invisible and back
    case 'appparamw_selectgroup_pum'
        h_fig=findobj(allchild(0), 'tag', 'Prowler_Application_Parameters_fig');
        appdata=getappdata(h_fig, 'appdata');
        app_name=appdata.app_name;
        h_value =appdata.h_value;
        h_name =appdata.h_name;
        grouppum = appdata.grouppum;
        selval = get(grouppum,'value');
        for i=1:length(h_value)
            if(str2num(get(h_value(i),'tag')) == selval)
                if(~strcmpi(get(h_value(i),'style'), 'checkbox'))
                    set(h_name(i),'visible', 'on');
                end
                set(h_value(i),'visible', 'on');
            else
                set(h_name(i),'visible', 'off');
                set(h_value(i),'visible', 'off');
            end
        end
    end
        


function fill_edits(h_value, values)

if length(h_value)~=length(values)
    error('Input parameters have different length.')
end

for i=1:length(h_value)
    value_i=values{i};
    if ~(ischar(value_i)|iscell(value_i))
        value_i=num2str(value_i); 
    end
    if strcmp(get(h_value(i), 'style'), 'popupmenu')
        % find string in popup's cell of strings
        c_popup=get(h_value(i), 'string');
        ii=1;
        valuesCell = cellstr(c_popup);
        while ii<=length(c_popup) & ~strcmp(valuesCell{ii}, value_i)
            ii=ii+1;
        end
        if ii>size(c_popup)
            error('Bad parameter value for popup')
        else
            set(h_value(i), 'value', ii)
        end
    elseif strcmp(get(h_value(i), 'style'), 'checkbox')
        set(h_value(i), 'value', str2num(value_i))
    else
        set(h_value(i), 'string', value_i)
    end
    
end




