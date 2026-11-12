// Step
var idle = !instance_exists(obj_server) && !instance_exists(obj_client);

if (idle) {
    // Tab switches between the two boxes
    if (keyboard_check_pressed(vk_tab)) {
        if (field == 0) name_text = keyboard_string; else ip_text = keyboard_string;
        field = 1 - field;
        keyboard_string = (field == 0) ? name_text : ip_text;
    }
    // whatever is typed goes into the active box (names are capped at 12 letters)
    if (field == 0) {
        if (string_length(keyboard_string) > 12) keyboard_string = string_copy(keyboard_string, 1, 12);
        name_text = keyboard_string;
    } else {
        ip_text = keyboard_string;
    }
    global.join_ip = ip_text;
}

// F1 = host
if (keyboard_check_pressed(vk_f1) && idle) {
    global.player_name = (string_length(name_text) > 0) ? name_text : "Player" + string(irandom_range(100, 999));
    global.join_ip = "127.0.0.1";
    instance_create_layer(0, 0, "Instances", obj_server);
    alarm[0] = 30;   // the host's own client joins shortly after
}

// F2 = join
if (keyboard_check_pressed(vk_f2) && idle) {
    global.player_name = (string_length(name_text) > 0) ? name_text : "Player" + string(irandom_range(100, 999));
    instance_create_layer(0, 0, "Instances", obj_client);
}

// Enter = start (host only)
if (keyboard_check_pressed(vk_enter) && instance_exists(obj_server)) {
    global.world_seed = irandom(999999);
    world_generate(global.world_seed);   // 1) build the island first
    server_init_world();	// 2) then place the starting items on it
	server_init_enemies(); // 2) Spawn Enemies

    with (obj_server) {                  // 3) tell everyone to start, including the seed
        var b = buffer_create(8, buffer_grow, 1);
        buffer_write(b, buffer_u8, 4);
        buffer_write(b, buffer_u32, global.world_seed);
        for (var i = 0; i < ds_list_size(clients); i++) network_send_packet(clients[| i], b, buffer_tell(b));
        buffer_delete(b);
    }
}