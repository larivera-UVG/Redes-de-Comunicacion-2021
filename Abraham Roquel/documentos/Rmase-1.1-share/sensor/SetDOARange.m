% SetDOARange: set DOA characteristics
% usage: function [thetaStd]= SetDOARange(NearRange, FarRange, R_max, AngleStd)
% NearRange, FarRange, R_max: range parameters, in meters
% AngleStd: working angle standard deviation, in degrees
% output:  lookup table, given r, find thetaStd(r)
%           thetaStd(r) is in radian
% 
% Copyright (c) 2002, Palo Alto Research Center
% All rights reserved. 
% 
% Author: Juan Liu (juan.liu@parc.com)
% Contributor:  Jim Reich (jim.reich@parc.com)
% $Id:$


function [r, thetaStd]= SetDOARange(NearRange, FarRange, R_max, AngleStd, d)

r=0:d:R_max;
d1= (180- AngleStd)/(NearRange/d);
nearIndex = find(r<=NearRange);
thetaStd(nearIndex)= 180- (nearIndex-1)* d1;
middleIndex = find((r>NearRange)&(r<=FarRange));
thetaStd(middleIndex)= AngleStd;
d2= (90- AngleStd)/((R_max- FarRange)/d);
farIndex = find(r>FarRange);
thetaStd(farIndex)= AngleStd+ d2*((farIndex-1)- (FarRange/d));  
thetaStd= thetaStd(1:length(r));
thetaStd= thetaStd'/360* (2*pi);      % radian
