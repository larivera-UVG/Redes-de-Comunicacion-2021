%
% function: gridPredictBeliefUniform.m
% ------------------------------------
% This function computes the predicted distribution after the stochastic
% isotropic diffusion. 
%
% Usage: [predictedBelief, numAlg, numTrans] = gridPredictBelief(crtBelief, dt, threshold, v_max);
%
%  crtBelief = 
%               mass: [Nx1 double] --> probability mass of non-trivial grids
%                  x: [Nx1 double] --> x position of non-trivial grids
%                  y: [Nx1 double]
%            display: [(x_max)x(y_max) double]
%              x_max: 50 --> number of grids
%              y_max: 50
%               mean: [1x2 double]
%                cov: [2x2 double]
%                 dx: [1x1 double] --> grid size
%                 dy: [1x1 double]
%
%
% Basically, each sample will wear a 'Gaussian hat' and we can compute 
% the mass smeared from each of the gaussians at any given point.
%
% Jaewon Shin, Oct 24, 2001
% Xerox PARC, CMA/SPL CoSense Project
%

function [predictedBelief, numAlg, numTrans] = gridPredictBeliefUniform(...
                crtBelief, dt, threshold, v_max)

            
% book-keeping
numAlg= 0;
numTrans= 0;

x_max = crtBelief.x_max; 
y_max = crtBelief.y_max;
dx = crtBelief.dx;
dr = ceil(dt * v_max/dx);

V = zeros(2*dr+1, 2*dr+1);
for i = 1:2*dr+1
    for j = 1:2*dr+1
        V(i,j) = norm([i j]-[dr+1 dr+1])<=dr;
    end
end
        
V = V/sum(V(:));

% Convolution!
% ------------
predictedBelief.display = conv2(crtBelief.display, V, 'same');


% First normalization before thresholding, this is for finding nontrivial 
% probability grid
%
predictedBelief.display = predictedBelief.display/sum(predictedBelief.display(:));

% Thresholding
% ------------
[predictedBelief.y predictedBelief.x] = find(predictedBelief.display>threshold);
predictedBelief.y= predictedBelief.y-1;
predictedBelief.x= predictedBelief.x-1;

% Second normalization after the threshold
% -----------------------------------------
predictedBelief.display = predictedBelief.display/sum(predictedBelief.display(:)); 

predictedBelief.mass = zeros(length(predictedBelief.x),1);
for a = 1:length(predictedBelief.x)
    predictedBelief.mass(a) = predictedBelief.display(predictedBelief.y(a)+1,...
        predictedBelief.x(a)+1);
end

predictedBelief.dx = crtBelief.dx;
predictedBelief.dy = crtBelief.dy;
predictedBelief.x_max = crtBelief.x_max;
predictedBelief.y_max = crtBelief.y_max;

% book-keeping
% first calculate the bounding box
index= find(crtBelief.mass > threshold);
xmin= min(crtBelief.x);
xmax= max(crtBelief.x);
ymin= min(crtBelief.y);
ymax= max(crtBelief.y);
boxsize= (ymax-ymin+1)* (xmax- xmin+1);
numAlg= numAlg+ boxsize* length(V(:)) *2;   % * and +
numAlg= numAlg+ boxsize*5;  % renormalization, thresholding, renormalization
