% ComputeMutualInfo:    compute the mutual information for each sensor in 
%                       the neighborhood, and return the predicted likelihood
%                       of estimate p(Z_n|Z_1...n-1) to verification purpose
%                       For reference, see Cover & Thomas, 
%                       Elements of Information theory  
% Usage: [utility, z_likelihood, numAlg, numTrans] = ...
%           ComputeMutualInfo(predictedBelief, neighbors, ...
%                       distanceThreshold, pirThreshold)
% Copyright (c) 2002, Palo Alto Research Center
% All rights reserved. 
% 
% Author: Juan Liu (juan.liu@parc.com)
% Contributor:  Jim Reich (jim.reich@parc.com)
% $Id:$


function [utility, z_likelihood, numAlg, numTrans]= ComputeMutualInfo(crtBelief, neighbors, distanceThreshold)

% book-keeping
numAlg= 0;
numTrans= 0;

belief = crtBelief;
belief.mass = belief.mass/sum(belief.mass);     %alg(2)
numAlg= numAlg+ length(belief.mass)*2;
dx = belief.dx; 
dy = belief.dy;

numHypotheses = length(belief.x);
numNeighbors = length(neighbors);

MI= zeros(numNeighbors, 1);     % integrate over the joint density pzx
numAlgNeighbor = [];
numTransNeighbor = [];
for j=1: numNeighbors
    numAlgNeighbor(j)=0;
    numTransNeighbor(j)=0;
    
    % compute p(sufficient_x) from crtBelief.mass p(x)
    % sufficient_x is the sufficient statistic of x;
    % d(x- sensor) for acoustic amp sensors;  angle(x-sensor) for DOA
    % if a node has multiple sensors? use belief.mass
    px= belief.mass;
    
%     if (neighbors(j).numSensors ~= 1)
%         fprintf('number of sensors in a node must be 1. \n');     return;
%     end
%     
%     crtSensor= neighbors(j).sensor(1);
%     Ying: each neighbor only has one sensor.
    crtSensor = neighbors(j);
    switch (crtSensor.kind)
    case 0,     % acoustic amp sensor
        dist= sqrt((belief.x*dx- crtSensor.pos(1)).^2 + (belief.y*dy - crtSensor.pos(2)).^2);  
        % alg(7), trans(1)
        numAlgNeighbor(j)= numAlgNeighbor(j)+ length(belief.x)* 7;
        numTransNeighbor(j)= numTransNeighbor(j)+ length(belief.x);
        
        d_min= min(dist);   d_max= max(dist);
        if d_min < distanceThreshold,   d_min= distanceThreshold;     end
        z_min= crtSensor.LowA/(d_max^(crtSensor.alpha/2)) - 3* crtSensor.sigma;
        z_max= crtSensor.HighA/(d_min^(crtSensor.alpha/2)) + 3* crtSensor.sigma;
        % if z_min< 0,  z_min=0; end
        z_step= (z_max- z_min)/50;
    case 1,     % PIR sensor
        % do nothing
    case 2,     % DOA sensor
        z_min= -pi;  z_max= pi;
        z_step= (z_max-z_min)/50;
    end  
    z_sequence= (z_min:z_step:z_max-(1e-5))';      % column vector
    
    % compute p(z) from crtBelief.mass p(x)
    pzx= zeros(numHypotheses, length(z_sequence));
    p_z= zeros(size(z_sequence));
    for i=1: numHypotheses
        %crtSensor= neighbors(j).sensor(1);
        %Ying
        crtSensor= neighbors(j);
        [newLikelihood, numAlgCalcZ, numTransCalcZ]=  ...
            calculateLikelihoodZ(crtSensor, z_sequence, ...
            belief.x(i)*dx, belief.y(i)*dy, distanceThreshold); %alg(2)
        p_z_cond_x= newLikelihood; 
        numAlgNeighbor(j)= numAlgNeighbor(j)+ numAlgCalcZ + 2;
        numTransNeighbor(j)= numTransNeighbor(j) + numTransCalcZ;
        
        if (sum(p_z_cond_x)< 1e-10),  fprintf('all zero likelihood\n'); end   
        pzx(i, :) = p_z_cond_x'* belief.mass(i);    %alg(1)
        numAlgNeighbor(j)= numAlgNeighbor(j) + length(p_z_cond_x);
    end 
    p_z = sum(pzx, 1);      
    numAlgNeighbor(j)= numAlgNeighbor(j) + length(pzx(:));
    
    p_z = p_z(:)/sum(p_z);
    numAlgNeighbor(j)= numAlgNeighbor(j)+ 2*length(p_z);
    
    for iz= 1: length(z_sequence)
        prodMarginal(:, iz)= belief.mass * p_z(iz);
        numAlgNeighbor(j)= numAlgNeighbor(j)+ length(belief.mass);
    end
     
    pzx_vec= pzx(:)/sum(pzx(:));   %alg(2)
    numAlgNeighbor(j)= numAlgNeighbor(j)+ length(pzx(:))* 2;
    
    prod_vec= prodMarginal(:)/sum(prodMarginal(:)); %alg(2)
    numAlgNeighbor(j)= numAlgNeighbor(j)+ length(prodMarginal(:))* 2;
    
    index1 = find(pzx_vec > 1e-16);         %alg(1)
    index2 = find(prod_vec > 1e-16);        %alg(1)
    nonZeroIndex= intersect(index1, index2);
    MI(j)= sum(log(pzx_vec(nonZeroIndex) ...
        ./prod_vec(nonZeroIndex)) .* pzx_vec(nonZeroIndex));  %alg(2), trans(2)
    numAlgNeighbor(j)= numAlgNeighbor(j) + 2*length(pzx_vec)+ 2*length(nonZeroIndex);
    numTransNeighbor(j) = numTransNeighbor(j) + 2*length(nonZeroIndex);
    
    z_likelihood(j).z_sequence= z_sequence;
    z_likelihood(j).pz= p_z;
    
   
end
utility= MI; 
numAlg= numAlg+ sum(numAlgNeighbor);
numTrans= numTrans+ sum(numTransNeighbor);

        
