% Written by         Dragan Petrovic      August 2002
%
% Usage:    [utility] = UtilityDistanceToMeanDOA(PosNode,BeliefX,BeliefY,Weights)
% INPUTS:   PosNode - [x,y] coordinates of node position
%           BeliefX - array of x positions of non-zero belief pixels
%           BeliefY - array of y positions of non-zero belief pixels
%           Weights - array of weights of non-zero belief pixels
% OUTPUT:   utility - scalar: utility of DOA sensor at position PosNode
%
% Here, utility is estimated to be simply the inverse of the distance between
% the sensor and the centroid of the belief cloud.
%
%
%Copyright (c) 2002 Palo Alto Research Center Incorporated. All Rights Reserved.
%
%Use or disclosure of this data is subject to the restriction in the
%README file of this software.


function [utility] = UtilityDistanceToMeanDOA(PosNode,BeliefX,BeliefY,Weights)

Mean = Weights'*[BeliefX, BeliefY];
utility = 1/sqrt(sum((PosNode-Mean).^2));