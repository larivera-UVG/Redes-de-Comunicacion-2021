function B = enter_new_row_test(A, N)
K = size(A, 1);			% filas en A
if K == 0
	B = ones([1, N]);	% al inicio toda la probabilidad esta concentrada
else
	new_prob = (1 / (K + 1));					% nueva probabilidad que tendra la fila nueva
	rem_prob = 1 - new_prob;					% probabilidad a la que deben ajustarse los elementos viejos de cada columna
	scale_per_column = rem_prob ./ sum(A, 1);	% factores de escalamiento de cada columna
	A_rescaled = scale_per_column .* A;
	new_row = new_prob * ones([1, N]);
	B = [A_rescaled; new_row];
end
