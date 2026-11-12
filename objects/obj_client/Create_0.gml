// Create
socket = network_create_socket(network_socket_tcp);
connect_result = network_connect_async(socket, global.join_ip, 6510);
remote_players = ds_map_create();
lobby = [];
connected = -1;
last_msg = "none";
async_count = 0;
last_type = -1;

world_pickups = ds_map_create();   // net_id -> the object showing it
pending_hp = ds_map_create();   // health that arrived before that player's character existed