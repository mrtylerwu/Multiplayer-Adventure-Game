server = network_create_server(network_socket_tcp, 6510, 8);
clients = ds_list_create();
packets_received = 0;
async_count = 0;
last_type = -1;
names = ds_map_create();

world_items = ds_map_create();   // net_id -> { item, amount, x, y }
next_item_id = 1;

// Enemy tracking
world_enemies = ds_map_create();
next_enemy_id = 1;

// Enemy spawning settings
max_enemies = 10;
positions = ds_map_create();   // socket -> [x, y], where each player last was
healths = ds_map_create();   // socket -> [hp, hp_max]
