function varargout=info
% TTPSPAN application information file

% ***	
% ***	 Copyright 2002, Vanderbilt University. All rights reserved.
% ***
% ***    This program is distributed in the hope that it will be useful,
% ***    but WITHOUT ANY WARRANTY; without even the implied warranty of
% ***    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% ***
% ***

% Written by Gyula Simon, gyula.simon@vanderbilt.edu
% Last modified: Mar 24, 2003  by GYS

title1='Routing skeleton';
str1={  'This is a skeleton to build routing applications';...
        'You can select the mote layout and the application parameters.';...
        ''; ...
        'The example routing application is a geographical angle-based routing:';...
        ''; ...
        'Upon reception each node retransmits the message with a certain';...
        'probability if the receiving node is in the specified angle of';...
        'the transmitter.';...
        ''};
if nargout==0
    helpwin({ title1, str1}, 'Application Info')
else
    varargout={ title1, str1};
end
