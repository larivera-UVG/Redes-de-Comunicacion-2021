function abe_myfun()
   load('test_results.mat')
   figure;
   t_arr_depurado = t_arr(1:counter_arr);
   plot(t_arr_depurado, T_column_arr(:, 1:counter_arr));
   xlim([min(t_arr_depurado), max(t_arr_depurado)]);
   ylabel("$\tau$", 'Interpreter', 'Latex');
   xlabel("tiempo (s)");
   title("Cambio de la feromona en el tiempo");
end