% Written by         Dragan Petrovic      August 2002
%
% Usage:    [utility] = UtilityLineSampled(Pos1,Pos2,delta,BeliefX,BeliefY,Weights,percentDOA);
% INPUTS:   Pos1 - [x,y] position of one endpoint of line segment
%           Pos2 - [x,y] position of other endpoint of line segment
%           delta - scalar: average distance between neighboring nodes
%           BeliefX - array of x positions of non-zero belief pixels
%           BeliefY - array of y positions of non-zero belief pixels
%           Weights - array of weights of non-zero belief pixels
%           percentDOA - scalar: ratio of DOA nodes to all nodes in network
%
% OUTPUT:   utility - scalar:  utility of line segment
%
%
%Copyright (c) 2002 Palo Alto Research Center Incorporated. All Rights Reserved.
%
%Use or disclosure of this data is subject to the restriction in the
%README file of this software.



function [utility] = UtilityLineSampled(Pos1,Pos2,delta,BeliefX,BeliefY,Weights,percentDOA)

segmentLength = sqrt(sum((Pos2-Pos1).^2));
numSamples = segmentLength/delta;
if (numSamples>0)
    Delta = (Pos2-Pos1)/numSamples;
	numSamples = floor(numSamples);
end

utility = 0;
for i=1:numSamples
    SamplePos = Pos1+Delta*i;
    utilityAmp = UtilityAmpInverseD(SamplePos,BeliefX,BeliefY,Weights);
    utilityDOA = UtilityDistanceToMeanDOA(SamplePos,BeliefX,BeliefY,Weights);
    utility = utility + percentDOA*utilityDOA + (1-percentDOA)*utilityAmp;
end

%scaling h
%if numSamples>0,
%   utility = utility/numSamples;
%end