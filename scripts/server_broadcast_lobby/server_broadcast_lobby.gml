function server_broadcast_lobby() {
    with (obj_server) {
        var b = buffer_create(64, buffer_grow, 1);
        buffer_write(b, buffer_u8, 3);
        buffer_write(b, buffer_u8, ds_map_size(names));
        var k = ds_map_find_first(names);
        while (!is_undefined(k)) {
            buffer_write(b, buffer_u16, k);
            buffer_write(b, buffer_string, names[? k]);
            k = ds_map_find_next(names, k);
        }
        for (var i = 0; i < ds_list_size(clients); i++) {
            network_send_packet(clients[| i], b, buffer_tell(b));
        }
        buffer_delete(b);
    }
}