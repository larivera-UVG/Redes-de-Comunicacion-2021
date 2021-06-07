function varargout=idrstats(varargin)
% PERMSTATS Performance statistics using the last simulation results
% [sys_stat, node_stat]=permstats

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

global IDR_HOPS
global IDR_MSES
global IDR_SIZES

avgHops = mean(IDR_HOPS);
if (length(IDR_HOPS)>1)
	stdHops = std(IDR_HOPS);
else
    stdHops = 0;
end
avgMse = mean(IDR_MSES);
if (length(IDR_MSES)>1)
    stdMse = std(IDR_MSES);
else
    stdMse = 0;
end
avgSize = mean(IDR_SIZES);
if (length(IDR_SIZES)>1)
	stdSize = std(IDR_SIZES);
else
    stdSize = 0;
end
MinInfoGain = sim_params('get_app', 'MinInfoGain');
if (isempty(MinInfoGain)) MinInfoGain = 0; end
if (MinInfoGain == 0)
    overall = avgMse+avgSize;
else
    overall = MinInfoGain*(avgHops+stdHops)+(avgMse+avgSize);
end

sys_stat = struct('avg_hops', avgHops, ...
                  'std_hops', stdHops, ...
                  'avg_mse', avgMse, ...
                  'std_mse', stdMse, ...
                  'avg_size', avgSize, ...
                  'std_size', stdSize, ...
                  'overall', overall, ...
                  'hops', IDR_HOPS, ...
                  'mses', IDR_MSES, ...
                  'sizes', IDR_SIZES);
if nargout==0
    disp(sys_stat)
else
    varargout={sys_stat};
end