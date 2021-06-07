% computeMeanCovFromPmf.m:  compute the mean and covariance matrix given a 
%                           probability mass 
% usage: function [mean, Cov, edist] = computeMeanCovFromPmf(x, y, weights)
%
% Copyright (c) 2002, Palo Alto Research Center
% All rights reserved. 
% 
% Author: Jaewon Shin
% modified by: Juan Liu (juan.liu@parc.com) 
% $Id:$
 

function [mean, Cov, edist] = computeMeanCovFromPmf(x, y, weights)

mean = weights'*[x, y]; 
diff = [x, y]-repmat(mean, length(x),1);
Cov = zeros(2,2);
edist= 0;
if length(x) < 2
    Cov = eye(2);
else
    
    for i = 1:length(diff)
        Cov = Cov + weights(i)*(diff(i,:)'*diff(i,:));
        edist= edist + weights(i)* (diff(i, :) * diff(i,:)');
    end
    
end