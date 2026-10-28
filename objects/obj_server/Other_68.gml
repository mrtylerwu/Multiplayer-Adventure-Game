// obj_server, Async - Networking event
async_count++;
last_type = async_load[? "type"];

switch (async_load[? "type"]) {
    case network_type_connect:
        ds_list_add(clients, async_load[? "socket"]);
        show_debug_message("Client connected: " + string(async_load[? "socket"]));
        break;

    case network_type_disconnect:
	    var i = ds_list_find_index(clients, async_load[? "socket"]);
	    if (i != -1) ds_list_delete(clients, i);
	    ds_map_delete(names, async_load[? "socket"]);
	    server_broadcast_lobby();
	    break;
		
    case network_type_data:
		packets_received++;
        var buff = async_load[? "buffer"];
        var size = async_load[? "size"];
        var sender = async_load[? "id"];
        buffer_seek(buff, buffer_seek_start, 0);

        // TCP can bundle several messages into one packet, so read until the buffer is empty
        while (buffer_tell(buff) < size) {
            var msg_id = buffer_read(buff, buffer_u8);

            switch (msg_id) {
				case 0: // join
				    names[? sender] = buffer_read(buff, buffer_string);
				    server_broadcast_lobby();
				    break;
					
                case 1: // position
                    var px = buffer_read(buff, buffer_f32);
                    var py = buffer_read(buff, buffer_f32);

                    var out = buffer_create(16, buffer_grow, 1);
                    buffer_write(out, buffer_u8, 2);        // 2 = "another player moved"
                    buffer_write(out, buffer_u16, sender);  // who moved
                    buffer_write(out, buffer_f32, px);
                    buffer_write(out, buffer_f32, py);

                    for (var j = 0; j < ds_list_size(clients); j++) {
                        var c = clients[| j];
                        if (c != sender) network_send_packet(c, out, buffer_tell(out));
                    }
                    buffer_delete(out);
                    break;

                default: // unknown message, skip the rest of this packet
                    buffer_seek(buff, buffer_seek_start, size);
                    break;
            }
        }
        break;
}