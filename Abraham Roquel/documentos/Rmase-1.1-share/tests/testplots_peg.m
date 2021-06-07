function testplots
%lists={'gridrouting','gradfloodagg','aodv','mcbrtree','mcbrsearch','mcbrflood'};
%lists={'gradflood','mcbrflood','gridrouting'};
lists={'gradflood','gridrouting','gridroutingdup','mcbrfloodsqrt'};
%lists={'mcbrfloods','mcbrflood','mcbrfloodsqrt','mcbrflood1','mcbrfloodsdup','mcbrflooddup','mcbrfloodsqrtdup','mcbrflood1dup'};
testdir='tests/';
tests = {'testpeg'};
models = {'peg_model'};
for i=1:length(models)
    prowler('Init');
    eval(models{i});
    [topology, mote_IDs]=prowler('GetTopologyInfo');
    num_node(i)=length(mote_IDs);
end


%peg
testlists{1} = lists;

metricsY = {'delays','throughput','succrate','energy','efficiency','lifetime'};
testsTime = {20};
%resultdir = '/qosr_test';
resultdir = '/result0405';
for i=1:1
    for j=1:size(metricsY,2)
        getplots('time', metricsY{j}, testsTime{i}, strcat(testdir,tests{i},resultdir), testlists{i},tests{i},strcat(testdir,tests{i},resultdir,'/',metricsY{j}),num_node(i));
    end
end