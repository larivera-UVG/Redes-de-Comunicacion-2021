% Written by         Dragan Petrovic      August 2002
%
% Usage:    [utility] = UtilityEllipseSampled(PosNode,sensorKind,PosExit,a2,belief,delta,percentDOA);
% INPUTS:   PosNode - [x,y] position of sensor node at one focus of ellipse
%           sensorKind - amplitude or DOA sensor
%           PosExit - array: [x,y] coordinates of exit point at other focus of ellipse
%           a2 - scalar: maximum distance that may be traversed before exit is reached
%           belief - current belief
%           delta - scalar: average distance between neighboring nodes
%           percentDOA - scalar: ratio of DOA nodes to all nodes in network
%
% OUTPUT:   utility - scalar:  utility of ellipse
%
%
%Copyright (c) 2002 Palo Alto Research Center Incorporated. All Rights Reserved.
%
%Use or disclosure of this data is subject to the restriction in the
%README file of this software.



function [utility] = UtilityEllipseSampled(PosNode,sensorKind,PosExit,a2,belief,delta,percentDOA)

if (PosNode(1)==PosExit(1))&(PosNode(2)==PosExit(2)),
    utility = 1;
    return
end

belief.mass = belief.mass/sum(belief.mass);

c2 = sqrt(sum((PosNode-PosExit).^2));   %distance between the foci of the ellipse
a = a2/2;
c = c2/2;
b = sqrt(a^2 - c^2);    %half the length of the semiminor axis
Center = (PosNode+PosExit)/2;
if (PosExit(1)==PosNode(1))
    Major1 = Center + [0 a];
    Major2 = Center - [0 a];
    Minor1 = Center + [b 0];
	Minor2 = Center - [b 0];
else
	slope = (PosExit(2)-PosNode(2))/(PosExit(1)-PosNode(1));    %slope of semimajor axis
	if (slope)
		deltaX = sqrt(a^2/(1+slope^2));
		deltaY = sqrt(a^2/(1+1/slope^2));
		Major1 = Center + [deltaX deltaY];
		Major2 = Center - [deltaX deltaY];
		slope = -1/slope;
		deltaX = sqrt(b^2/(1+slope^2));
		deltaY = sqrt(b^2/(1+1/slope^2));
		Minor1 = Center + [-deltaX deltaY];
		Minor2 = Center + [deltaX -deltaY];
	else
        Major1 = Center + [a 0];
		Major2 = Center - [a 0];
        Minor1 = Center + [0 b];
		Minor2 = Center - [0 b];
	end
end

BeliefX = belief.x*belief.dx;
BeliefY = belief.y*belief.dy;
Weights = belief.mass;

Utility(1) = UtilityLineSampled(PosNode,Major1,delta,BeliefX,BeliefY,Weights,percentDOA);
Utility(2) = UtilityLineSampled(PosExit,Major2,delta,BeliefX,BeliefY,Weights,percentDOA);
Utility(3) = UtilityLineSampled(PosNode,Minor1,delta,BeliefX,BeliefY,Weights,percentDOA) + ...
             UtilityLineSampled(PosExit,Minor1,delta,BeliefX,BeliefY,Weights,percentDOA);
Utility(4) = UtilityLineSampled(PosNode,Minor2,delta,BeliefX,BeliefY,Weights,percentDOA) + ...
             UtilityLineSampled(PosExit,Minor2,delta,BeliefX,BeliefY,Weights,percentDOA);
numSamples = floor(a2/delta);

utility = max(Utility);