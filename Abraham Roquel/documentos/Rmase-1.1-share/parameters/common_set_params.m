function [param, i] = common_set_params(param, i, gId)

%Routing Parameters: common
i=i+1;
param(i).name='Promiscuous';              
param(i).default=0;              
param(i).group=gId;
param(i).type='checkbox';

%for max_hops
i=i+1;
param(i).name='MaxHops';              
param(i).default=inf;              
param(i).group=gId;

%for aggregate_queue
i=i+1;
param(i).name='AggregatePackets';
param(i).default=4;
param(i).group=gId;

i=i+1;
param(i).name='AggregateTimeout';
param(i).default=10000;
param(i).group=gId;

%for confirm_transmit
i=i+1;
param(i).name='TransTimeout';
param(i).default=3500; %bittime
param(i).group=gId;

%for delay_transmit
i=i+1;
param(i).name='MinDelay';                  
param(i).default=0;      %bittime     
param(i).group=gId;

i=i+1;
param(i).name='RandOff';                   
param(i).default=1000;      %bittime     
param(i).group=gId;

i=i+1;
param(i).name='ProbFunc';                   
param(i).default='1/c';      %bittime     
param(i).group=gId;

%for init_hellow, init_backward
i=i+1;
param(i).name='InitNofTimes';                    
param(i).default=3;                
param(i).group=gId;

i=i+1;
param(i).name='InitInterval';                    
param(i).default=20000;        %bittime        
param(i).group=gId;

%for ack_retransmit
i=i+1;
param(i).name='Retries';
param(i).default=8;
param(i).group=gId;

i=i+1;
param(i).name='AckTimeout';
param(i).default=0.15;
param(i).group=gId;

i=i+1;
param(i).name='RandAckTimeout';
param(i).default=0.1;
param(i).group=gId;

i=i+1;
param(i).name='AckSize';
param(i).default=96;
param(i).group=gId;
%end of ack_retransmit

%for mcbr func
i=i+1;
param(i).name='DestFunc';
param(i).default='none';
param(i).group=gId;
param(i).type='popupmenu';
param(i).data=char('none', 'geo_dest');

i=i+1;
param(i).name='CostFunc';
param(i).default='none';
param(i).group=gId;
param(i).type='popupmenu';
param(i).data=char('none', 'energy_cost');