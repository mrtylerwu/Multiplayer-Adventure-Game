// Create
target_x = x;
target_y = y;

net_pid = -1;
hp = 100;
hp_max = 100;

healths = ds_map_create();   // socket -> [hp, hp_max]