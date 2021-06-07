function testplots

lists={'nocontrol','credit1','credit','credit2','credit25'};
testdir='tests/';
tests = {'testcredit'};
models = {'credit_model'};
for i=1:length(models)
    prowler('Init');
    eval(models{i});
    [topology, mote_IDs]=prowler('GetTopologyInfo');
    num_node(i)=length(mote_IDs);
end


%peg
testlists{1} = lists;

metricsY = {'delays','throughput','succrate','energy'};
testsTime = {10};
resultdir = '/result0407';
for i=1:1
    for j=1:size(metricsY,2)
        getplots('time', metricsY{j}, testsTime{i}, strcat(testdir,tests{i},resultdir), testlists{i},tests{i},strcat(testdir,tests{i},resultdir,'/',metricsY{j}),num_node(i));
    end
end