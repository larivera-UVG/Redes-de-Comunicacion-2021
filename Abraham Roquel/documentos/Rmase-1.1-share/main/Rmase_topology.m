function [out_topology, out_mote_IDs]=topology(varargin);

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
% Last modified: Nov. 24, 2003  by YZ

persistent topology  mote_IDs
global ATTRIBUTES

if nargin<1, cmd='request';
else
    cmd=varargin{1};
end
  
if strcmpi(cmd, 'refresh')
    IDs = varargin{2};
    speed=varargin{3};
    
    for id=IDs
        i = find(mote_IDs==id);
        topology(i,:) = topology(i,:)+speed;        
    end
elseif strcmpi(cmd, 'init')
    ATTRIBUTES = [];
    useTopologyFile = sim_params('get_app', 'UseTopologyFile');
    if (isempty(useTopologyFile)) useTopologyFile = 0; end
    if (useTopologyFile)
        fileName = sim_params('get_app', 'TopologyFileName');
        [topology, mote_IDs] = feval(fileName, varargin);
    else
        [topology, mote_IDs] = topology_creator(varargin);
    end
end

out_topology=topology;
out_mote_IDs=mote_IDs;

for id=mote_IDs
    i=find(mote_IDs==id);
    ATTRIBUTES{id}.x = topology(i, 1);
    ATTRIBUTES{id}.y = topology(i, 2);
end

