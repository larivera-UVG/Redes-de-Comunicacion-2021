function [v, x, y] = attribute(name)

%* Copyright (C) 2003 PARC Inc.  All Rights Reserved.
%*
%* Use, reproduction, preparation of derivative works, and distribution 
%* of this software is permitted, but only for non-commercial research 
%* or educational purposes. Any copy of this software or of any derivative 
%* work must include both the above copyright notice of PARC Incorporated 
%* and this paragraph. Any distribution of this software or derivative 
%* works must comply with all applicable United States export control laws. 
%* This software is made available AS IS, and PARC INCORPORATED DISCLAIMS 
%* ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE 
%* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
%* PURPOSE, AND NOTWITHSTANDING ANY OTHER PROVISION CONTAINED HEREIN, ANY 
%* LIABILITY FOR DAMAGES RESULTING FROM THE SOFTWARE OR ITS USE IS EXPRESSLY 
%* DISCLAIMED, WHETHER ARISING IN CONTRACT, TORT (INCLUDING NEGLIGENCE) 
%* OR STRICT LIABILITY, EVEN IF PARC INCORPORATED IS ADVISED OF THE 
%* POSSIBILITY OF SUCH DAMAGES. This notice applies to all files in this 
%* release (sources, executables, libraries, demos, and documentation).
%*/

% Written by Ying Zhang, yzhang@parc.com
% Last modified: Nov. 22, 2003  by YZ

global ATTRIBUTES

[topology, mote_IDs] = prowler('GetTopologyInfo');

minX = min(topology(:,1));
maxX = max(topology(:,1));
minY = min(topology(:,2));
maxY = max(topology(:,2));

dx = sim_params('get_app', 'Xdist');
dy = sim_params('get_app', 'Ydist');
ddx = sim_params('get_app', 'Xdensity');
ddy = sim_params('get_app', 'Ydensity');
dix = dx/ddx;
diy = dy/ddy;

x = minX:dix:maxX;
y = minY:diy:maxY;
v = Inf*ones(length(y), length(x));
for i=1:length(mote_IDs)
    x0 = topology(i,1);
    y0 = topology(i,2);
    ix = round((x0-minX)/dix+1);
    iy = round((y0-minY)/diy+1);
    try v(iy,ix)=eval(['ATTRIBUTES{', num2str(i), '}.', name]); catch v(iy,ix)=0; end
end

v_size = size(v);
if (v_size(1)>length(y)) y = minY:diy:(maxY+1);
end
if (v_size(2)>length(x)) x = minX:dix:(maxX+1);
end
    