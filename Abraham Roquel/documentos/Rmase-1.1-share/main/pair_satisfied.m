function out = pair_satisfied(dis, div)

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

global SOURCES DESTINATIONS

[topology, mote_IDs] = prowler('GetTopologyInfo');

sources = find(SOURCES==1); %source IDs
destinations = find(DESTINATIONS==1); %destination IDs

out = 1;

for src = sources
    sidx = find(mote_IDs==src);
    for des = destinations
        didx = find(mote_IDs==des);
        out = is_pair(sidx, didx, dis, div);
        if (~out) break; end
    end
    if (~out) break; end
end

function out = is_pair(s, d, dis, div)

topology = prowler('GetTopologyInfo');

%find bounding box of topology

minx=min(topology(:,1));
maxx=max(topology(:,1));
miny=min(topology(:,2));
maxy=max(topology(:,2));
maxD = norm([maxx-minx, maxy-miny]);

ps = topology(s,:);
pd = topology(d,:);

ds = norm(ps-pd);

out = (ds <= maxD*(dis+div)) && (ds >= maxD*(dis-div));