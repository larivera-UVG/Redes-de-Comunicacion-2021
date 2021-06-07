%  calculateLikelihoodZ:    Calculate the real likelihood for 
%                           microphone/PIR/DOA sensors
%
%  usage:  [likelihood] = calculateLikelihoodZ(crtLeader, z_sequence, ...
%                           x, y, distanceThreshold)
% input:
%   crtSensor  
%   z_sequence          vector of measuremant values
%   x                   x values: PHYSICAL LOCATION !!!
%   y                   y values: PHYSICAL LOCATION !!!
%   distanceThreshold   where to clip!
%
% output:
%   likelihood    likelihood values of p(z|x) as a function of z
%
% Copyright (c) 2002, Palo Alto Research Center
% All rights reserved. 
% 
% Author: Juan Liu (juan.liu@parc.com) 
% $Id:$





function [likelihood, numAlg, numTrans] = calculateLikelihoodZ(crtSensor, z, x, y, distanceThreshold)

%book-keeping
numAlg= 0;
numTrans= 0;

SensorPos = crtSensor.pos;    % PHYSICAL LOCATION!      
switch crtSensor.kind
case 0, % Microsphone
    
    % Parameters for acoustic sensors
    sigma = crtSensor.sigma;    
    alpha = crtSensor.alpha;
    LowA = crtSensor.LowA;
    HighA = crtSensor.HighA;
    DeltaA = HighA - LowA;
    
    r = sqrt((x-SensorPos(1))^2 + (y- SensorPos(2))^2);   % alg(5), trans(1), r is a scalar
    if r< distanceThreshold,    r= distanceThreshold;   end    %alg(1)
    
    D = [sigma.^2 .* r.^alpha];   % D is a scalar, alg(1)
    B = z./(sigma.^2.*r.^(alpha/2));        % alg(1)
    C = z.^2./sigma.^2 - B.^2 .* D;         % alg(5)  
    likelihood= sqrt(D).*exp(-.5.*C)./(DeltaA * prod(sigma)) ...
      .*( erfc((LowA- B.*D)./sqrt(2*D)) -erfc((HighA - B.*D)./sqrt(2*D)));
    % alg(8), trans(3)
  
    numAlg= numAlg+ (8+ 1+ 5)*length(z);
    numTrans= numTrans + 3*length(z);
    
case 1, % PIR sensor
    % Parameters for PIR sensors
    alpha1 = crtSensor.alpha1; 
    alpha2 = crtSensor.alpha2; 
    maxRange = crtSensor.range; 
    theta = crtSensor.theta;    
    
    n = zeros(2,1);
    n(1) = crtSensor.normal(1);
    n(2) = crtSensor.normal(2);
    
    % Ugly (but fast!) vectorization
    % ------------------------------
    %
    v = [x;y];
    temp = v- SensorPos;
    temp_norm = [sqrt(temp(1,:).^2+temp(2,:).^2)] ;
    temp_norm2 = [temp_norm; temp_norm];
    
    likelihood = (1-1./(1+exp(-alpha1*(sum(acos(((temp)./temp_norm2).*repmat(n, 1, length(x))))-theta)))).*...
        1./(1+exp(-alpha2*(maxRange-temp_norm)));
    % FIXME- need book-keeping here. 
    
    likelihood = likelihood/max(likelihood(:));
    if z == 1 % If the PIR sensor report something
        ;
    else % If the PIR sensor report nothing, we can still assume that 
        % there is a target since the sensor has been queried by a cluster head.
        likelihood = 1-likelihood;
    end
    
case 2, % DOA sensor
    % Parameters for PIR sensors
    % alpha1 = crtSensor.alpha1; 
    % alpha2 = crtSensor.alpha2; 
    % maxRange = crtSensor.range; 
    thetaStd= crtSensor.theta;    
    
    distx= x- SensorPos(1);
    disty= y- SensorPos(2);
    distr = sqrt(distx.^2 + disty.^2);
    ang = atan2(disty, distx);      % all scalar operations
   
    d_ang= ang- z;      % alg(1)
    index1= find(d_ang > pi);   %alg(1)
    d_ang(index1)= 2*pi- d_ang(index1);  %alg(1)
    index2= find(d_ang < -pi);  %alg(1)
    d_ang(index2)= 2*pi+ d_ang(index2);  %alg(0)
   
    rindex= floor(distr) + 1;
    if (rindex>length(thetaStd)), rindex= length(thetaStd); end
    std_list= thetaStd(rindex);
    std_list= reshape(std_list, size(ang));
    % std_list= 5/360*(2*pi);
    likelihood= 1./sqrt(2*pi*std_list.^2) .* exp(-(d_ang).^2 ./ (2* std_list.^2));  %alg(3), trans(1)
    numAlg= numAlg+ length(z) * 3;
    numTrans= numTrans + length(z)*1;
end

