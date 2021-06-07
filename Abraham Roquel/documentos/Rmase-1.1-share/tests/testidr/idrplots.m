function idrplots(name, dir, list, r)

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

symbols = {'bo-', 'gx-', 'r+:', 'c*-.', 'ms--', 'ys-','ks-','bs-','r*--','gd-'};

plotstring = [];
legendstring = [];
for i=1:length(list)
    res = load([dir, '/', list{i}, '.txt']);
    hops(:, i) = res(:, 1);
    mses(:, i) = res(:, 2);
    sizes(:, i) = res(:, 3);
    errs(:,i) = mses(:,i)+sizes(:,i)/3;
    overall(:,i) = errs(:,i)+r*hops(:,i);
    plotstring = [plotstring, '1:', num2str(size(hops, 1)), ', ', name, '(:, ', num2str(i), '), ', '''', symbols{i}, ''''];
    legendstring = [legendstring, '''', list{i}, ''''];
    
    if (i<length(list)) 
        plotstring = [plotstring, ', '];
        legendstring = [legendstring, ', '];
    end   
end

disp(['plot(', plotstring, ')'])
eval(['plot(', plotstring, ')']);
eval(['legend(', legendstring, ')']);
xlabel('Number of packets');
ylabel(name);

