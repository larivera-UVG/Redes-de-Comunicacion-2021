% Written by         Dragan Petrovic      August 2002
%
% Usage:    [utility] = UtilityAmpInverseD(PosNode,BeliefX,BeliefY,Weights)
% INPUTS:   PosNode - [x,y] coordinates of node position
%           BeliefX - array of x positions of non-zero belief pixels
%           BeliefY - array of y positions of non-zero belief pixels
%           Weights - array of weights of non-zero belief pixels
% OUTPUT:   utility - scalar: utility of amplitude sensor at position PosNode
%
%
%Copyright (c) 2002 Palo Alto Research Center Incorporated. All Rights Reserved.
%
%Use or disclosure of this data is subject to the restriction in the
%README file of this software.



function [utility] = UtilityAmpInverseD(PosNode,BeliefX,BeliefY,Weights)

D = sqrt((PosNode(1)-BeliefX).^2+(PosNode(2)-BeliefY).^2);
D(find(D<1))=1;
utility = sum(Weights./D);