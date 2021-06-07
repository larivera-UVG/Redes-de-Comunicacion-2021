%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%											
%   "Copyright (c) 2004 The University of Southern California"				
%   All rights reserved.								
%											
%   Permission to use, copy, modify, and distribute this script and its		
%   documentation for any purpose, without fee, and without written agreement is	
%   hereby granted, provided that the above copyright notice, the following		
%   two paragraphs and the author appear in all copies of this software.		
%											
%   NO REPRESENTATIONS ARE MADE ABOUT THE SUITABILITY OF THE SCRIPT FOR ANY		
%   PURPOSE. IT IS PROVIDED "AS IS" WITHOUT EXPRESS OR IMPLIED WARRANTY.		
%											
%   Neither the script developers, the Autonomous Network Research Group		
%   (ANRG), or USC, shall be liable for any damages suffered from using this		
%   software.										
%											
%   Author:		Marco Zuniga 
%   Director:   Prof. Bhaskar Krishnamachari
%   Autonomous Networks Research Group, University of Southern California
%   http://ceng.usc.edu/~anrg
%
%   Contact: marcozun@usc.edu
%   Date last modified:	2004/07/02						
%											
%   Anything following a "%" is treated as a comment.					
%											
%											
%   Description:									
%	
%   PRR generates the prr for a given distance
%
%   prr(d) generates the packet reception rate of "d" for the default parameters 
%           
%   The channel and radio parameters can be modified by adding other input
%   variables
%
%   Channel Parameters
%   ------------------
%   'n'         path loss exponent        (adimensional)
%   'sigma'     shadowing standard deviation (dB) 
%   'pld0'      close-in reference path-loss (dB)
%   'd0'        close-in reference distance   (m)
%
%   Radio Parameters
%   ----------------
%   'mod'       modulation         please see modulation options below
%   'enc'       encoding           please see encoding options below
%   'Pout'      tx output power             (dBm)
%   'Pn'        noise floor                 (dBm)
%   'frame'     frame length in bytes     (bytes)
%   'preamble'  preamble length in bytes  (bytes)   
%											
%   Modulation options
%   ------------------
%   ASK	    1 (Non Coherent Amplitude Shift Keying)	
%   NCASK	2 (Amplitude Shift Keying)
%   FSK	    3 (Non Coherent Frequency Shift Keying)
%   NCFSK	4 (Frequency Shift Keying)
%   BPSK	5 (Binary Phase Shift Keying)
%   DPSK	6 (Differential Phase Shift Keying)
%
%   Encoding options
%   ----------------
%   NRZ		    1 (No Return to Zero)
%   4B5B		2 (4-Bit Data Symbol, 5-Bit Code)
%   MANCHESTER  3 (Manchester)
%   SECDED	    4 (Single Error Detection Double Error Correction)
%
%   EXAMPLES
%
%   for 10m, modulation = FSK, encoding = SECDED, frame length = 50 bytes 
%       prr (10,'mod',3,'enc',4,'frame',50)
%
%   for output power = -9 dBm
%       prr (10,'Pout', -9)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function result = prr(d,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Default Channel Parameters 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PATH_LOSS_EXPONENT = 3.0;
SHADOWING_STANDARD_DEVIATION = 3.8;
PL_D0 = 55.0;
D0 = 1.0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Default Radio Parameters 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

MODULATION = 3;
ENCODING = 3;
OUTPUT_POWER = -7.0;
NOISE_FLOOR = -105.0;
PREAMBLE_LENGTH = 2;
FRAME_LENGTH = 50;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% New parameters defined by the user
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numInputs = length(varargin);

for i=1:2:numInputs
    [inVar] = deal(varargin{i+1});
    if ( strcmp(varargin(i),'n') )
        PATH_LOSS_EXPONENT = inVar;
    elseif ( strcmp(varargin(i),'sigma') )
        SHADOWING_STANDARD_DEVIATION = inVar;
    elseif ( strcmp(varargin(i),'pld0') )
        PL_D0 = inVar;
    elseif ( strcmp(varargin(i),'d0') )
        D0 = inVar;
    elseif ( strcmp(varargin(i),'mod') )
        MODULATION = inVar;
    elseif ( strcmp(varargin(i),'enc') )
        ENCODING = inVar;
    elseif ( strcmp(varargin(i),'Pout') )
        OUTPUT_POWER = inVar;
    elseif ( strcmp(varargin(i),'Pn') )
        NOISE_FLOOR = inVar;
    elseif ( strcmp(varargin(i),'frame') )
        FRAME_LENGTH = inVar;
    elseif ( strcmp(varargin(i),'preamble') )
        PREAMBLE_LENGTH = inVar;
    else
       	error('Error: wrong argument passed to function prr');
    end    
end

% some security checks
if(PATH_LOSS_EXPONENT < 0)
	error('Error: value of PATH_LOSS_EXPONENT must be positive');
end
if(SHADOWING_STANDARD_DEVIATION < 0)
	error('Error: value of SHADOWING_STANDARD_DEVIATION must be positive');
end
if(PL_D0 < 0)
	error('Error: value of PL_D0 must be positive');
end
if(D0 < 0)
	error('Error: value of D0 must be positive');
end
if(PREAMBLE_LENGTH < 0)
	error('Error: value of PREAMBLE_LENGTH must be positive');
end
if(FRAME_LENGTH < 0)
	error('Error: value of FRAME_LENGTH must be positive');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Obtain RSSI
%       use topology information and
%       channel parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% mean rssi decay dependent on distance 
avgDecay = OUTPUT_POWER - PL_D0 - (10*PATH_LOSS_EXPONENT*(log(d/D0)/log(10)));
rssi = avgDecay + randn * SHADOWING_STANDARD_DEVIATION;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Obtain Prob. of bit Error
%       use rssi and modulation chosen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

snr = (10^((rssi - NOISE_FLOOR)/10))/.64;   % division by .64 converts from Eb/No to RSSI
                                            % this is specific for each receiver see paper 
if (MODULATION == 1)    % NCASK
    pe = 0.5*( exp(-0.5*snr) + Q( sqrt(snr) ) );
elseif(MODULATION == 2) % ASK
    pe = Q( sqrt(snr/2) );
elseif(MODULATION == 3) % NCFSK
    pe = 0.5*exp(-0.5*snr);
elseif(MODULATION == 4) % FSK
    pe = Q( sqrt(snr) );
elseif(MODULATION == 5) % BPSK
    pe = Q( sqrt(2*snr) );
elseif(MODULATION == 6) % DPSK
    pe = 0.5*exp(-snr);
else
    error('MODULATION is not correct');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Obtain PRR
%   use prob. of error and encoding scheme
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

preseq = (1-pe)^(8*PREAMBLE_LENGTH);
if (ENCODING == 1)      % NRZ
    prr = preseq*((1-pe)^(8*(FRAME_LENGTH-PREAMBLE_LENGTH)));
elseif (ENCODING == 2)  % 4B5B
    prr = preseq*((1-pe)^(8*1.25*(FRAME_LENGTH-PREAMBLE_LENGTH)));
elseif (ENCODING == 3)  % MANCHESTER
    prr = preseq*((1-pe)^(8*2*(FRAME_LENGTH-PREAMBLE_LENGTH)));
elseif (ENCODING == 4)  % SECDED
    prr = ((preseq*((1-pe)^8)) + (8*pe*((1-pe)^7)))^((FRAME_LENGTH-PREAMBLE_LENGTH)*3);
else
    error('ENCODING is not correct');
end

result = prr;