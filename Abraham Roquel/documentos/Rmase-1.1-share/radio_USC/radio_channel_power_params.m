function param=params;
% same as application parameters

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

% Modified by Ying Zhang, yzhang@parc.com
% Last modified: Dec. 30, 2004

i=0;

%min_prr threshold, this is used also to determine the size of the interference
i=i+1;
param(i).name='MAC_PRR_THRESHOLD';
param(i).default=0.1;    

% -20:1:10, ...       % the range of powers that is available in db
i=i+1;
param(i).name='POWER_RNG';
param(i).default=[-20 -19 -15  -8  -5   0   4   6   8  10];    

%[5.3 6.9 7.1 7.1 7.1 7.4 7.4 7.4 7.6 7.6 7.9 7.9 8.2 8.4 8.7 8.9 9.4 9.6 9.7 10.2 10.4 11.8 12.8 12.8 13.8 14.8 15.8 16.8 20.0 22.1 26.7]
%current range in mA
i=i+1;
param(i).name='CURRENT_RNG';
param(i).default=[3.7 5.2 5.4 6.5 7.1 8.5 11.6 13.8 17.4 21.5];    

%default voltage
i=i+1;
param(i).name='VOLTAGE';
param(i).default=3;    
        
i=i+1;
param(i).name='POWER_RNG_INSTANCES';
param(i).default=10;    
     
i=i+1;
param(i).name='CURRENT_RECV';
param(i).default=7; 

i=i+1;
param(i).name='CURRENT_IDLE';
param(i).default=7; 

i=i+1;
param(i).name='CURRENT_SLEEP';
param(i).default=0.002; 