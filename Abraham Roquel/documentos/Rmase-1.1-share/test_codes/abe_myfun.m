function abe_myfun()
   load('test_results.mat')
   figure;
   hold on
   t_arr_depurado = t_arr(1:counter_arr);
   T_arr_depurado = T_column_arr(:, 1:counter_arr);
   N_arr_depurado = N_column_arr(:, 1:counter_arr);
   last_N = N_arr_depurado(:, end);
   ylabel("$\tau (t)$", 'Interpreter', 'Latex');
   xlabel("tiempo (s)");
   title("Cambio de la feromona en el tiempo");
   xlim([min(t_arr_depurado), max(t_arr_depurado)]);
   ylim([0 1]);
   %yline(max(max(T_arr_depurado)));
	for ii = 1 : max(size(last_N))
		focus_val = last_N(ii);
		if focus_val ~= 0
			[row, col] = ind2sub(N_arr_depurado, find(N_arr_depurado == focus_val, 1));
			t_selected = t_arr_depurado(col : end);
			T_selected = T_arr_depurado(ii, col : end);
			plot(t_selected, T_selected, 'DisplayName', sprintf("%d", focus_val));
		end
	end
	ll = legend('Location', 'eastoutside');
	title(ll,'my title');
	%[leg,att] = legend('Location', 'eastoutside');
	%title(leg,'my title')
	%leg.Title.Visible = 'on';
end