function [param, i] = sensor_set_params(param, i, groupID)

i=i+1;
param(i).name='DOASensorProb';            
param(i).default=0.3;                
param(i).group=groupID;

i=i+1;
param(i).name='BeliefDx';            
param(i).default=0.2;                
param(i).group=groupID;

i=i+1;
param(i).name='BeliefDy';            
param(i).default=0.2;                
param(i).group=groupID;

i=i+1;
param(i).name='MaxTargetSpeedBelieved';            
param(i).default=0.2;                
param(i).group=groupID;

i=i+1;
param(i).name='NearRange';            
param(i).default=0.5;                
param(i).group=groupID;

i=i+1;
param(i).name='FarRange';            
param(i).default=2.5;                
param(i).group=groupID;

i=i+1;
param(i).name='AngleStd';            
param(i).default=10;                
param(i).group=groupID;

i=i+1;
param(i).name='R_max';            
param(i).default=7;                
param(i).group=groupID;

i=i+1;
param(i).name='A_LO';            
param(i).default=0;                
param(i).group=groupID;

i=i+1;
param(i).name='A_HI';            
param(i).default=2;                
param(i).group=groupID;

i=i+1;
param(i).name='A';            
param(i).default=1;                
param(i).group=groupID;

i=i+1;
param(i).name='A_Sigma';            
param(i).default=0.02;                
param(i).group=groupID;

i=i+1;
param(i).name='TargetInit';            
param(i).default=[2.5, 0];                
param(i).group=groupID;

i=i+1;
param(i).name='TargetSpeed';            
param(i).default=[0, 0.1];                
param(i).group=groupID;

i=i+1;
param(i).name='RandTargetSpeed';            
param(i).default=0.05;                
param(i).group=groupID;
