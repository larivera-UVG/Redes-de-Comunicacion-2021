% Q function used to compute the Pe for the 
% different modulation schemes

function result=Q(x)
result=0.5*erfc(x/sqrt(2));
