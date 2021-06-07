function [param, i] = layer_set_params(param, i, gId)

%Routing Layers: add your routing layers here
% i=i+1;
% param(i).name='fault';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';

i=i+1;
param(i).name='mac';
param(i).default=1;
param(i).group=gId;
param(i).type='checkbox';

% i=i+1;
% param(i).name='duty_cycle';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';

i=i+1;
param(i).name='transmit_queue';
param(i).default=0;
param(i).group=gId;
param(i).type='checkbox';

i=i+1;
param(i).name='aggregate_queue';
param(i).default=0;
param(i).group=gId;
param(i).type='checkbox';

i=i+1;
param(i).name='transmit_duplicate';
param(i).default=0;
param(i).group=gId;
param(i).type='checkbox';

i=i+1;
param(i).name='max_hops';
param(i).default=0;
param(i).group=gId;
param(i).type='checkbox';

i=i+1;
param(i).name='mcbr_credit';
param(i).default=0;
param(i).group=gId;
param(i).type='checkbox';

i=i+1;
param(i).name='neighborhood';
param(i).default=0;
param(i).group=gId;
param(i).type='checkbox';

% i=i+1;
% param(i).name='multipower_neighbor';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';

% i=i+1;
% param(i).name='sensor';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';

% i=i+1;
% param(i).name='SD';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';

% i=i+1;
% param(i).name='ack_retransmit';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';

i=i+1;
param(i).name='confirm_transmit';
param(i).default=0;
param(i).group=gId;
param(i).type='checkbox';

i=i+1;
param(i).name='check_duplicate';
param(i).default=0;
param(i).group=gId;
param(i).type='checkbox';

i=i+1;
param(i).name='delay_transmit';
param(i).default=0;
param(i).group=gId;
param(i).type='checkbox';

i=i+1;
param(i).name='spantree';
param(i).default=1;
param(i).group=gId;
param(i).type='checkbox';

% i=i+1;
% param(i).name='flood';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';

% i=i+1;
% param(i).name='backbone';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';
% 
% i=i+1;
% param(i).name='grid_routing';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';
% 
% i=i+1;
% param(i).name='routing2Dmany';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';
% 
% i=i+1;
% param(i).name='flood2Dgrad';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';
% 
% i=i+1;
% param(i).name='mint_routing';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';
% 
% i=i+1;
% param(i).name='nd_hood';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';
% 
% i=i+1;
% param(i).name='nd_broker';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';

i=i+1;
param(i).name='aodv_routing';
param(i).default=0;
param(i).group=gId;
param(i).type='checkbox';

% i=i+1;
% param(i).name='ant_routing';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';

i=i+1;
param(i).name='mcbr_tree';
param(i).default=0;
param(i).group=gId;
param(i).type='checkbox';

i=i+1;
param(i).name='mcbr_search';
param(i).default=0;
param(i).group=gId;
param(i).type='checkbox';

i=i+1;
param(i).name='mcbr_flood';
param(i).default=0;
param(i).group=gId;
param(i).type='checkbox'; 

i=i+1;
param(i).name='mcbr_ant';
param(i).default=0;
param(i).group=gId;
param(i).type='checkbox';

i=i+1;
param(i).name='mcbr_smart_ant';
param(i).default=0;
param(i).group=gId;
param(i).type='checkbox';

i=i+1;
param(i).name='mcbr_flood_ant';
param(i).default=0;
param(i).group=gId;
param(i).type='checkbox';


i=i+1;
param(i).name='converge_control';
param(i).default=0;
param(i).group=gId;
param(i).type='checkbox';

% i=i+1;
% param(i).name='converge_inward';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';
% 
% i=i+1;
% param(i).name='converge_inwardN';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';

% 
% i=i+1;
% param(i).name='converge_tree';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';
% 
% i=i+1;
% param(i).name='converge_send';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';

% i=i+1;
% param(i).name='converge_TDMA';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';

% i=i+1;
% param(i).name='idr_local';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';
% 
% i=i+1;
% param(i).name='idr_remote';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';
% 
% i=i+1;
% param(i).name='dsdv_pc_routing';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';
% 
% i=i+1;
% param(i).name='multipower_hello';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';

i=i+1;
param(i).name='init_hello';
param(i).default=0;
param(i).group=gId;
param(i).type='checkbox';

i=i+1;
param(i).name='init_backward';
param(i).default=0;
param(i).group=gId;
param(i).type='checkbox';

% i=i+1;
% param(i).name='idr_stats';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';
% 
% i=i+1;
% param(i).name='query_comb';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';
% 
% i=i+1;
% param(i).name='app_query';
% param(i).default=0;
% param(i).group=gId;
% param(i).type='checkbox';
