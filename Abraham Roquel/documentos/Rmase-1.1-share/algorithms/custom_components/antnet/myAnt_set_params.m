function [param, i] = myAnt_set_params(param, i, groupID)

i=i+1;
param(i).name='delta_t';	%tiempo en segundos para envío de hormigas
param(i).default=0.01;                
param(i).group=groupID;

i=i+1;
param(i).name='w';			% # de muestras para calcular el mejor tt
param(i).default=10;                
param(i).group=groupID;


i=i+1;
param(i).name='varsigma';
param(i).default=0.01;                
param(i).group=groupID;


i=i+1;
param(i).name='c_w';		% parÃ¡metro para definir ventana de observaciÃ³n de w_max = 5*c_w / varsigma
param(i).default=1;            	    
param(i).group=groupID;

i=i+1;
param(i).name='alpha_p';	% parÃ¡metro para medir la importancia de eta_ij (medida de la cola en nodo i hacia j)
param(i).default=0.5;            	    
param(i).group=groupID;

i=i+1;
param(i).name='max_life';	% mÃ¡ximo nÃºmero de saltos de hormiga de forward antes de ser descartada
param(i).default=50;            	    
param(i).group=groupID;

i=i+1;
param(i).name='c1';			% peso de la calidad del trip time actual en comparaciÃ³n con Wbest para r_p
param(i).default=0.5;            	    
param(i).group=groupID;

i=i+1;
param(i).name='c2';			% peso de la calidad del trip time actual en comparaciÃ³n con el intervalo de confianza
param(i).default=0.5;            	    
param(i).group=groupID;

i=i+1;
param(i).name='v_i';			% parÃ¡metro para definir el intervalo de confiaza (mientras mÃ¡s cercano a 1, mÃ¡s grande)
param(i).default=0.9;            	    
param(i).group=groupID;
