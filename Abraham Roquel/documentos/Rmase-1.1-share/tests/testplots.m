function testplots
lists={'gradfloodagg','mcbrflood','mcbrsearch','mcbrtree','nd','gridrouting','mintrouting','backbone','convcon1'};
testdir='tests/';
tests = {'testlis','testpeg','testsl','testrft','testosu'};
models = {'lis_model','peg_model','sl_model','rft_model','osu_model'};
for i=1:length(models)
    prowler('Init');
    eval(models{i});
    [topology, mote_IDs]=prowler('GetTopologyInfo');
    num_node(i)=length(mote_IDs);
end
%test_nums = cell2struct(num_nodes,models,1);

%lis
testlists{1} = {lists{[1:9]}};
%peg
testlists{2} = {lists{[1 2 3 4 6]}};
%sl
testlists{3} = {lists{[1:5 7:9]}};
%rft
testlists{4} = {lists{[1:8]}};
%osu
testlists{5} = {lists{[1:9]}};

metricsY = {'delays','throughput','succrate','energy','efficiency','lifetime'};
%metricsY = {'sent'};
testsTime = {20,4,20,10,3};
resultdir = '/result0619';
for i=1:5
    for j=1:size(metricsY,2)
        getplots('time', metricsY{j}, testsTime{i}, strcat(testdir,tests{i},resultdir), testlists{i},tests{i},strcat(testdir,tests{i},resultdir,'/',metricsY{j}),num_node(i));
    end
end