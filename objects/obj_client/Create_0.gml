// Create
socket = network_create_socket(network_socket_tcp);
connect_result = network_connect_async(socket, global.join_ip, 6510);
remote_players = ds_map_create();   // player id -> their character in this game
world_pickups = ds_map_create();    // item id -> the item object in this game
resource_nodes = ds_map_create();   // tree/rock id -> the object in this game
pending_hp = ds_map_create();       // health that arrived before that player's character existed
lobby = [];
connected = -1;

// debug values: the old debug Draw GUI reads these. safe to delete along with it
last_msg = "none";
async_count = 0;
<<<<<<< HEAD
last_type = -1;

world_pickups = ds_map_create();   // net_id -> the object showing it
world_enemies = ds_map_create();   // enemy_id -> the enemy instance
pending_hp = ds_map_create();   // health that arrived before that player's character existed
=======
last_type = -1;
>>>>>>> origin/main
