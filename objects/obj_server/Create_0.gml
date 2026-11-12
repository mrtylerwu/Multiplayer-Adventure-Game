server = network_create_server(network_socket_tcp, 6510, 8);
clients = ds_list_create();
names = ds_map_create();          // socket -> player name
positions = ds_map_create();      // socket -> [x, y]
healths = ds_map_create();        // socket -> [hp, hp_max]
world_items = ds_map_create();    // items lying on the ground
next_item_id = 1;
resources = ds_map_create();      // trees and rocks: net_id -> { type, x, y, hp }
res_gone = ds_list_create();      // ids of trees and rocks that were cut down

// debug counters: the old debug Draw GUI reads these. safe to delete along with it
packets_received = 0;
async_count = 0;
last_type = -1;