function new_T = test_penalize_loss(old_T, destination, destinations_list, k, neighbor, neighbors_list)
new_T = old_T(:, :);                                                    % hacer una copia de la matriz de feromonas
target_destination_index = find(destinations_list == destination, 1);   % ubicar la columna de interes
target_neighbor_index = find(neighbors_list == neighbor, 1);            % ubicar la fila de interes
select_y = (neighbors_list == neighbor);                                % vectores de seleccion
select_x = ~ select_y;
old_column = old_T(:, target_destination_index);                        % valores antiguos de la columna
alpha_y = 1 - k;                                                        % factor de escala para el target
K = 1 - (alpha_y * old_column(target_neighbor_index));                  % factor de escala para el resto de filas
L = sum(old_column .* select_x);
alpha_x = K/L;
new_T(:, target_destination_index) = (alpha_y * (select_y .* old_column)) + (alpha_x * (select_x .* old_column));