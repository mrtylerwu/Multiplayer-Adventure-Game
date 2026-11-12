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
					
				case 5: // a player swung a tool: pass it on to everyone else
				    var swing_tool = buffer_read(buff, buffer_u8);
				    var swing_aim = buffer_read(buff, buffer_f32);
				    var swing_sweep = buffer_read(buff, buffer_s8);

				    var swb = buffer_create(16, buffer_grow, 1);
				    buffer_write(swb, buffer_u8, 6);
				    buffer_write(swb, buffer_u16, sender);   // who swung
				    buffer_write(swb, buffer_u8, swing_tool);
				    buffer_write(swb, buffer_f32, swing_aim);
				    buffer_write(swb, buffer_s8, swing_sweep);
				    for (var sw_i = 0; sw_i < ds_list_size(clients); sw_i++) {
				        var sw_c = clients[| sw_i];
				        if (sw_c != sender) network_send_packet(sw_c, swb, buffer_tell(swb));
				    }
				    buffer_delete(swb);
				    break;
					
				case 10: // a client is ready: send it everything on the ground
				    var k = ds_map_find_first(world_items);
				    while (!is_undefined(k)) {
				        var wb = buffer_create(32, buffer_grow, 1);
				        server_write_spawn(wb, k, world_items[? k]);
				        network_send_packet(sender, wb, buffer_tell(wb));
				        buffer_delete(wb);
				        k = ds_map_find_next(world_items, k);
				    }
					// Send all existing enemies to the newly ready client
					var ek = ds_map_find_first(world_enemies);
					while (!is_undefined(ek)) {
						var eb = buffer_create(32, buffer_grow, 1);
						server_write_enemy_spawn(eb, ek, world_enemies[? ek]);
						network_send_packet(sender, eb, buffer_tell(eb));
						buffer_delete(eb);
						ek = ds_map_find_next(world_enemies, ek);
						}

				    break;

				case 13: // pickup request
				    var req = buffer_read(buff, buffer_u32);
				    var w = world_items[? req];
				    if (!is_undefined(w)) {          // still there? first request wins
				        ds_map_delete(world_items, req);

				        // the requester gets the contents
				        var gb = buffer_create(32, buffer_grow, 1);
				        buffer_write(gb, buffer_u8, 14);
				        buffer_write(gb, buffer_string, w.item);
				        buffer_write(gb, buffer_u16, w.amount);
				        network_send_packet(sender, gb, buffer_tell(gb));
				        buffer_delete(gb);

				        // everyone removes the object
				        var rb = buffer_create(8, buffer_grow, 1);
				        buffer_write(rb, buffer_u8, 12);
				        buffer_write(rb, buffer_u32, req);
				        for (var m = 0; m < ds_list_size(clients); m++) {
				            network_send_packet(clients[| m], rb, buffer_tell(rb));
				        }
				        buffer_delete(rb);
				    }
				    break;

				case 15: // drop request
				    var ditem = buffer_read(buff, buffer_string);
				    var damt = buffer_read(buff, buffer_u16);
				    var dx = buffer_read(buff, buffer_f32);
				    var dy = buffer_read(buff, buffer_f32);
				    server_spawn_item(ditem, damt, dx, dy, true);
				    break;

                default: // unknown message, skip the rest of this packet
                    buffer_seek(buff, buffer_seek_start, size);
                    break;
            }
        }
        break;
}