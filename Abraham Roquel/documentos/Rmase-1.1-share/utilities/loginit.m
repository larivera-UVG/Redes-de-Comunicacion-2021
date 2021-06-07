% loginit(filename, logdata, debugFlag)

function logevent(varargin)

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

% Written by Guoliang Xing, gxing@parc.com
% Last modified: Nov. 22, 2003  by GX
% Modified by YZ, Jan. 5, 2005

global debugFlag
global logfd logdata

debugFlag = 1;
logdata = [];

if length(varargin)>=2
    logdata = varargin{2};
end
if length(varargin) >= 3
    debugFlag = varargin{3};
end

if (~debugFlag) return; end

if (~isempty(logfd))
    fids = fopen('all');
    index = find(fids==logfd);
    if (~isempty(index))
        fclose(logfd);
    end
end
logfd = fopen(varargin{1}, 'w');
        
