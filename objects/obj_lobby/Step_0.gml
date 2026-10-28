// Step
var idle = !instance_exists(obj_server) && !instance_exists(obj_client);
if (idle) global.join_ip = keyboard_string;

if (keyboard_check_pressed(vk_f1) && idle) {          // host
    global.join_ip = "127.0.0.1";
    instance_create_layer(0, 0, "Instances", obj_server);
    alarm[0] = 30;                                      // host's own client joins shortly after
}
if (keyboard_check_pressed(vk_f2) && !instance_exists(obj_client)) {   // join
    instance_create_layer(0, 0, "Instances", obj_client);
}
if (keyboard_check_pressed(vk_enter) && instance_exists(obj_server)) { // start
    with (obj_server) {
        var b = buffer_create(4, buffer_grow, 1);
        buffer_write(b, buffer_u8, 4);
        for (var i = 0; i < ds_list_size(clients); i++) network_send_packet(clients[| i], b, buffer_tell(b));
        buffer_delete(b);
    }
}