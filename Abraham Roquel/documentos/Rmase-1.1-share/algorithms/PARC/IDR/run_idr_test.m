function [hops, mses, sizes] = test(Number_of_Runs, N)

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

% Written by Lukas D. Kuhn, lukas.kuhn@parc.com
% Last modified: Dec. 22, 2003  by YZ

%N packets
hops = zeros(size(1:N));
mses = zeros(size(1:N));
sizes = zeros(size(1:N));
losts = zeros(size(1:Number_of_Runs));

for (inum=1:Number_of_Runs)
    prowler('Init');
    disp(['current run: ' num2str(inum)])
    
    prowler('StartSimulation');

    result = idrstats;
    
    disp(['hops: ' num2str(result.hops)])
    disp(['mses: ' num2str(result.mses)])
    disp(['sizes: ' num2str(result.sizes)])
    
    for (i=1:length(result.hops))
        
        if (hops(i) > 0)
            hops(i) = (hops(i)*(inum-1)+result.hops(i))/inum;
            mses(i) = (mses(i)*(inum-1)+result.mses(i))/inum;
            sizes(i) = (sizes(i)*(inum-1)+result.sizes(i))/inum;
        else
            hops(i) = result.hops(i);
            mses(i) = result.mses(i);
            sizes(i) = result.sizes(i);
        end
                  
    end  
    losts(inum) = N - length(result.hops);
    disp(['lost messages:', num2str(losts(inum))]); 
end


