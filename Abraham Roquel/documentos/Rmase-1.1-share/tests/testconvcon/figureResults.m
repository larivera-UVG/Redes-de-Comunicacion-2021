function figureResults(list, idx, figures, num)

res_mean = [];
res_std = [];
x_axis = [];
efficiency = [];
pridiction = [];

titles = {'Latency', 'Throughput', 'Success rate', 'Energy consumption', 'Energy efficiency', 'Lifetime Prediction'};
ylabels = {'latency (second)', 'throughput (packets/second)', 'success rate', 'energy consumption', 'energy efficiency', 'lifetime Prediction'};
metrics = [1,2,4,5,8,9];

maxUsed = 0;

for k=1:length(list)
    
	for i=1:length(idx)
        eval(['load tests/testconvcon/', list{k}, '/r', num2str(idx(i))]);
        res_mean(k,i,:) = mean(Stats');
        res_std(k,i,:) = std(Stats');
        efficiency{k,i} = Stats(7, :) .* Stats(4, :) ./ Stats(5, :);
        prediction{k,i} =  Stats(5, :) ./ num + sqrt(Stats(6, :));
        maxUsed = max(maxUsed, max(prediction{k,i}));
    end
    
    x_axis = [x_axis;idx];
end

for k=1:length(list)
    
	for i=1:length(idx)
        res_mean(k,i,8) = mean(efficiency{k,i});
        res_std(k,i,8) = std(efficiency{k,i});
        res_mean(k,i,9) = maxUsed - mean(prediction{k,i});
        res_std(k,i,9) = std(prediction{k,i});
    end
end

for j = figures

figure(j)
errorbar(x_axis', res_mean(:,:,metrics(j))', res_std(:,:,metrics(j))');
title(titles{j});
legend(list);
xlabel('delay coefficient');
ylabel(ylabels{j});

end

