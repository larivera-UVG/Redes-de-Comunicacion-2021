% calculateLikelihoodGeneral:   Calculate the real likelihood for 
%                               microphone/PIR/DOA sensors
%
% usage:    [likelihood, numAlg, numTrans] = calculateLikelihoodGeneral(
%                                crtLeader, z, [crtBelief.x]'*dx, 
%                                [crtBelief.y]'*dy, distanceThreshold)
%
% input
% -----
%   crtSensor     sensor struct 
%		crtSensor.{kind, sigma, alpha, LowA, HighA, alpha1, alpha2, theta, range, normal}
%						
%   z                   row of amplitude readings at each mic
%                       or 0/1 for PIR sensor
%   x                   row of x values: PHYSICAL LOCATION !!!
%   y                   row of y values: PHYSICAL LOCATION !!!
%   distanceThreshold   where to clip!
%
% output
% -------
%   likelihood      likelihood values
%   numAlg          number of algebraic operations
%   numTrans        number of transcendental operations
% 
% Jaewon Shin, Nov 2, 2001, PARC, CMA/SPL CoSense Project
% modified by Juan Liu, June 2002
% $Id:$

function [likelihood, numAlg, numTrans] = calculateLikelihoodGeneral(...
        crtSensor, z, x, y, distanceThreshold, d)


numAlg=0;
numTrans=0;

% Current sensor position
% -----------------------
pos = crtSensor.pos; % PHYSICAL LOCATION!      
switch crtSensor.kind
case 0, % Microsphone
    
    % Parameters for acoustic sensors
    sigma = crtSensor.sigma;    
    alpha = crtSensor.alpha;
    LowA = crtSensor.LowA;
    HighA = crtSensor.HighA;
    DeltaA = HighA - LowA;
    % measurement.
    
    % Ugly (but fast!) vectorization
    % ------------------------------
    r = sqrt(sum(([x' y'] - repmat(pos, [length(x) 1])).^2, 2));  %alg(5), trans(1)
    closeToSensorIndex = find(r <= distanceThreshold);  %alg(1)
    r(closeToSensorIndex) = distanceThreshold;   %alg(1)
    % book-keeping: 
    numAlg= numAlg + length(x)* 6 + length(closeToSensorIndex)*1;    
    numTrans= numTrans + length(x);   
    
    D = [sigma.^2 .* r.^alpha];   %alg(2)
    B = z./(sigma.^2.*r.^(alpha/2));        %trans(1), ./
    C = z.^2./sigma.^2 - B.^2 .* D;         %alg(3)
    likelihood =  sqrt(D).*exp(-.5.*C)./(DeltaA * prod(sigma)) ...
      .*( erfc((LowA- B.*D)./sqrt(2*D)) -erfc((HighA - B.*D)./sqrt(2*D)));
    %alg(10), Trans(6)
    likelihood = likelihood';
    
    % book-keeping:
    numAlg= numAlg+ length(r)* (2+3+10);
    numTrans= numTrans+ length(r)*(6+1);
    
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
    temp = v-repmat(pos', 1, length(x));   %alg(2)
    temp_norm = [sqrt(temp(1,:).^2+temp(2,:).^2)] ;  %alg(3), trans(1)
    temp_norm2 = [temp_norm; temp_norm];
    
    likelihood = (1-1./(1+exp(-alpha1*(sum(acos(((temp)./temp_norm2)...
        .*repmat(n, 1, length(x))))-theta)))).*...
        1./(1+exp(-alpha2*(maxRange-temp_norm)));  %alg(11), trans(3)
    likelihood = likelihood/max(likelihood(:));  %alg(2)
    %book-keeping
    numAlg= numAlg+ 13*length(x);
    numTrans= numTrans+ 2*length(x);
    
    if z == 1 % If the PIR sensor report something
        ;
    else % If the PIR sensor report nothing, we can still assume that 
        % there is a target since the sensor has been queried by a cluster head.
        likelihood = 1-likelihood;
        numAlg= numAlg+length(likelihood);
    end
    
case 2, % DOA sensor
    % Parameters for PIR sensors
    % alpha1 = crtSensor.alpha1; 
    % alpha2 = crtSensor.alpha2; 
    % maxRange = crtSensor.range; 
    thetaStd= crtSensor.theta;    
    normAng= z;
    
    % Ugly (but fast!) vectorization
    % ------------------------------
    distx= x- pos(1);       %alg(1)
    disty= y- pos(2);       %alg(1)
    distr = sqrt(distx.^2 + disty.^2);  %alg(3), trans(1)
    ang = atan2(disty, distx);  %trans(1)
   
    d_ang= ang- normAng;    %alg(1)
    index1= find(d_ang > pi);       %alg(1)
    d_ang(index1)= 2*pi- d_ang(index1);     %alg(1)
    index2= find(d_ang < -pi);      %alg(1)
    d_ang(index2)= 2*pi+ d_ang(index2);     %alg(0) --combined with index1, less than alg(1)
   
    rindex= floor(distr/d) + 1;   
    clipIndex= find(rindex>length(thetaStd));
    rindex(clipIndex)= length(thetaStd); 
    
    std_list= thetaStd(rindex);
    std_list= reshape(std_list, size(ang));     
    % std_list= 5/360*(2*pi);
    likelihood= 1./sqrt(2*pi*std_list.^2) .* exp(-(d_ang).^2 ./ (2* std_list.^2));
    %alg(6), trans(4)
    % book-keeping
    numAlg= numAlg+ (5+4+6)* length(x);
    numTrans= numTrans+ (2+4)*length(x);
end