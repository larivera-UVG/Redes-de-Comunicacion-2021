function varargout=info
% FLOOD application information file

% ***	
% ***	 Copyright 2002, Vanderbilt University. All rights reserved.
% ***
% ***    This program is distributed in the hope that it will be useful,
% ***    but WITHOUT ANY WARRANTY; without even the implied warranty of
% ***    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% ***
% ***

% Written by Gyula Simon, gyula.simon@vanderbilt.edu
% Last modified: Sep 19, 2002  by GYS

title1='Application FLOOD1D';
str1={  'This application illustrates the simple flooding algorithm.'; ...
        '';...
        'The sender mote transmits a message. Each mote receiving the';...
        'message retransmits it with probability p.' ;...
        'The value of p can be set in the ''Application Parameters''';...
        'window. The default value is p=0.5';...
        '';...
        'If p is too low, the flood dies out before every mote could';...
        'receive the message. If p it too high, the message is';...
        'retransmitted several times after every mote have received it,' ;...
        'thus causing an unnecessarily high settling time.';...
        '';...
        'The optimal value of p highly depends on topology.';...
        '';...
        'You can change the topology by editing the file FLOOD1D_TOPOLOGY.';...
        '';...
        'See also FLOOD2D.';...
        ''};
if nargout==0
    helpwin({ title1, str1}, 'Application Info')
else
    varargout={ title1, str1};
end