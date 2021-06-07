function testplots
lists={'gradfloodagg','backbone','mcbrflood','mcbrfloodaggdup'};
testdir='tests/';
tests = {'testsl'};
models = {'sl_model'};
for i=1:length(models)
    prowler('Init');
    eval(models{i});
    [topology, mote_IDs]=prowler('GetTopologyInfo');
    num_node(i)=length(mote_IDs);
end
%test_nums = cell2struct(num_nodes,models,1);


%sl
testlists{1} = lists;

metricsY = {'delays','throughput','succrate','energy','efficiency','lifetime'};
%metricsY = {'efficiency','lifetime'};
testsTime = {40};
resultdir = '/result0405';
for i=1:1
    for j=1:size(metricsY,2)
        getplots('time', metricsY{j}, testsTime{i}, strcat(testdir,tests{i},resultdir), testlists{i},tests{i},strcat(testdir,tests{i},resultdir,'/',metricsY{j}),num_node(i));
    end
end