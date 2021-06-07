function used = energyModel(type, data, interval)

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

% Written by Guoliang Xing
% Last modified: Dec. 30, 2004  by YZ
global ID t
global ATTRIBUTES

%default
used = 0;

currents= sim_params('get_radio', 'CURRENT_RNG');
voltage= sim_params('get_radio', 'VOLTAGE');
if (isempty(voltage)) voltage = 1; end
ci = sim_params('get_radio', 'CURRENT_IDLE');
if (isempty(ci)) ci = 0; end
pi = voltage*ci;

bittime = sim_params('get', 'BIT_TIME');
default_pkt_length = sim_params('get', 'MAC_PACKET_LENGTH');

switch type
case 'sent'
    try length = data.data.length; catch length = default_pkt_length; end %total bits   
    if (isempty(currents)) ptx = data.signal_strength*voltage;
    else ptx = currents(data.signal_strength)*voltage; end
    
    used = ptx*length + pi*(interval-length);
    
case 'received'
    try length = data.data.length; catch length = default_pkt_length; end %total bits
    pr = sim_params('get_radio', 'CURRENT_RECV');
    if (isempty(pr)) pr = 0; end
    prx = voltage*pr;
    
    used = prx*length + pi*(interval-length);
    
case 'sleep'
    ps = sim_params('get_radio', 'CURRENT_SLEEP');
    if (isempty(ps)) ps = 0; end
    used = interval*voltage*ps;
    
case 'idle'
    used = interval*pi;
end

used = used*bittime;
