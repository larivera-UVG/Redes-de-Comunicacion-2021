function v = pick_random_value_test(val_list, val_weights)
s = sum(val_weights);
val_probs = val_weights / s;    % normalizar los pesos
test_n = rand;					% numero aleatorio entre 0 y 1
k = 1; 							% apunta a la posicion de val_list a retornar
accum_sum = val_probs(k);		% valor para comparacion, suma acumulada
while test_n > accum_sum 		% vemos si la suma acumulada es menor que el numero aleatorio
	k = k + 1;
	accum_sum = accum_sum + val_probs(k);
end
v = val_list(k);

% vals = [1 2 3];
% probs = [0.5 0.3 0.2];
% i_count = zeros([1, max(size(vals))]);
% K = 1e6;

% for ii = 1 : K
% 	pos = pick_random_value_test(vals, probs);
% 	i_count(pos) = i_count(pos) + 1;
% end

% i_count_probs = i_count / K;
% i_count_probs