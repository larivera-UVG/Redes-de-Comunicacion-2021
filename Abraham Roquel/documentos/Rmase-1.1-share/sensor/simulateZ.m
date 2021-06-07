% simulateZ:        simulate the sensor reading that crtSensor may get,
%                   without noise contamination
% usage: function [z]= simulateZ(crtSensor, target, distanceThreshold, A, sigma) 
% Copyright (c) 2002, Palo Alto Research Center
% All rights reserved. 
% 
% Author: Juan Liu (juan.liu@parc.com) 
% $Id:$

function [z]= simulateZ(crtSensor, target, distanceThreshold, A, sigma)

        
        distance = norm([crtSensor.pos-target]);
        alpha = crtSensor.alpha;
        switch crtSensor.kind 
        case 0, % Acoustic sensor
            if distance > distanceThreshold
                z = A/(distance^(alpha/2));
            else
                z = A/(distanceThreshold^(alpha/2));
            end
            z= z+ randn(size(z))* sigma;
            % z = A/(distance^(alpha/2));
            
        case 1, % PIR Sensor
            n = zeros(2,1);
            n(1) = crtSensor.normal(1);
            n(2) = crtSensor.normal(2);
            alpha1 = crtSensor.alpha1;
            alpha2 = crtSensor.alpha2;                
            
            maxRange = crtSensor.range;
            theta = crtSensor.theta;            
            pos = [crtSensor.pos];
            v = target';        
            if (1-1/(1+exp(-alpha1*(acos(((v-pos')/norm(v-pos'))'*n)-theta))))*...
                    1/(1+exp(-alpha2*(maxRange-norm(v-pos')))) > pirThreshold
                z = 1;
            else 
                z = 0;
            end
            
        case 2, % DOA sensor
            normalVec = target - crtSensor.pos;
            z= atan2(normalVec(2), normalVec(1));
            z= z+ randn(size(z))* (3/180*pi);
            % z = (target - crtSensor.pos)...
            %     /norm((target - crtSensor.pos));
            
        end
        