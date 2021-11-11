function nh = next_hop_forward_ant_test(destination, neighors_list, T_matrix)
nh = pick_random_value(neighors_list, T_matrix(destination, :));