function testplots

%lists={'geodest0', 'geodest2', 'geodest4', 'geodest6', 'geodest8'};
lists={'none0', 'none5', 'none10', 'none15'};
testdir='tests/';
tests = {'testgeohole'};
models = {'geohole_model'};
for i=1:length(models)
    prowler('Init');
    eval(models{i});
    [topology, mote_IDs]=prowler('GetTopologyInfo');
    num_node(i)=length(mote_IDs);
end


%peg
testlists{1} = lists;

metricsY = {'delays','throughput','succrate','energy'};
testsTime = {9};
resultdir = '/result0406';
for i=1:1
    for j=1:size(metricsY,2)
        getplots('time', metricsY{j}, testsTime{i}, strcat(testdir,tests{i},resultdir), testlists{i},tests{i},strcat(testdir,tests{i},resultdir,'/',metricsY{j}),num_node(i));
    end
end