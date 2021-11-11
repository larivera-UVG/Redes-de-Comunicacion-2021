function marked_list = zeros_from_black_list_test(black_list, target_list)
% toma una lista negra con valores i, y otra lista negra con valores j
% devuelve una lista marked_list tal que las entradas con valor j = i para alguna i se hacen 0, de lo contrario 1
marked_list = zeros(size(target_list));	% ya se sabe el tamaño de la salida
for ii = 1 : max(size(target_list)) % ya se sabe cuántas iteraciones se van a tener
	lookup_value = target_list(ii);
	if isempty(find(black_list == lookup_value, 1)) % el elemento lookup_value no está en black_list, se puede quedar sin alteraciones
		marked_list(ii) = 1;
	end
end