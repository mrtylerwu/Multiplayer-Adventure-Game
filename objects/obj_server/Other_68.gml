async_count++;                                   // debug, safe to delete
last_type = async_load[? "type"];

switch (async_load[? "type"]) {
    case network_type_connect:
        ds_list_add(clients, async_load[? "socket"]);
        break;

    case network_type_disconnect:
        var dc_i = ds_list_find_index(clients, async_load[? "socket"]);
        if (dc_i != -1) ds_list_delete(clients, dc_i);
        ds_map_delete(names, async_load[? "socket"]);
        ds_map_delete(positions, async_load[? "socket"]);
        ds_map_delete(healths, async_load[? "socket"]);
        server_broadcast_lobby();
        break;

    case network_type_data:
        packets_received++;
        var buff = async_load[? "buffer"];
        var size = async_load[? "size"];
        var sender = async_load[? "id"];
        buffer_seek(buff, buffer_seek_start, 0);

        // one packet can hold several messages, so read until it's empty
        while (buffer_tell(buff) < size) {
            var msg_id = buffer_read(buff, buffer_u8);

            switch (msg_id) {

                case 0: // a player joined the lobby (name)
                    names[? sender] = buffer_read(buff, buffer_string);
                    server_broadcast_lobby();
                    break;

                case 1: // a player moved: remember it and tell everyone else
                    var px = buffer_read(buff, buffer_f32);
                    var py = buffer_read(buff, buffer_f32);
                    positions[? sender] = [px, py];

                    var out = buffer_create(16, buffer_grow, 1);
                    buffer_write(out, buffer_u8, 2);
                    buffer_write(out, buffer_u16, sender);
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
				    buffer_write(swb, buffer_u8, 8);
				    buffer_write(swb, buffer_u16, sender);
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

					var pk = ds_map_find_first(positions);
				    while (!is_undefined(pk)) {
				        if (pk != sender) {
				            var ppos = positions[? pk];
				            var pb = buffer_create(16, buffer_grow, 1);
				            buffer_write(pb, buffer_u8, 2);        // same message as "another player moved"
				            buffer_write(pb, buffer_u16, pk);
				            buffer_write(pb, buffer_f32, ppos[0]);
				            buffer_write(pb, buffer_f32, ppos[1]);
				            network_send_packet(sender, pb, buffer_tell(pb));
				            buffer_delete(pb);
				        }
				        pk = ds_map_find_next(positions, pk);
					}
					var hk = ds_map_find_first(healths);
					while (!is_undefined(hk)) {
					    if (hk != sender) {
					        var hv = healths[? hk];
					        var hb2 = buffer_create(16, buffer_grow, 1);
					        buffer_write(hb2, buffer_u8, 8);
					        buffer_write(hb2, buffer_u16, hk);
					        buffer_write(hb2, buffer_u16, hv[0]);
					        buffer_write(hb2, buffer_u16, hv[1]);
					        network_send_packet(sender, hb2, buffer_tell(hb2));
					        buffer_delete(hb2);
					    }
					    hk = ds_map_find_next(healths, hk);
					}
					// Send existing resource states to the newly connected client
					server_send_resource_state(sender);
				    break;

                case 7: // a player's health changed: remember it and tell everyone else
                    var h7_hp = buffer_read(buff, buffer_u16);
                    var h7_max = buffer_read(buff, buffer_u16);
                    healths[? sender] = [h7_hp, h7_max];

                    var h7_b = buffer_create(16, buffer_grow, 1);
                    buffer_write(h7_b, buffer_u8, 8);
                    buffer_write(h7_b, buffer_u16, sender);
                    buffer_write(h7_b, buffer_u16, h7_hp);
                    buffer_write(h7_b, buffer_u16, h7_max);
                    for (var h7_i = 0; h7_i < ds_list_size(clients); h7_i++) {
                        var h7_c = clients[| h7_i];
                        if (h7_c != sender) network_send_packet(h7_c, h7_b, buffer_tell(h7_b));
                    }
                    buffer_delete(h7_b);
                    break;

                case 13: // a player wants to pick up an item
                    var req = buffer_read(buff, buffer_u32);
                    var pk_item = world_items[? req];
                    if (!is_undefined(pk_item)) {              // still there? the first request wins
                        ds_map_delete(world_items, req);

                        var gb = buffer_create(32, buffer_grow, 1);   // the requester gets the contents
                        buffer_write(gb, buffer_u8, 14);
                        buffer_write(gb, buffer_string, pk_item.item);
                        buffer_write(gb, buffer_u16, pk_item.amount);
                        network_send_packet(sender, gb, buffer_tell(gb));
                        buffer_delete(gb);

                        var rmb = buffer_create(8, buffer_grow, 1);   // everyone removes the object
                        buffer_write(rmb, buffer_u8, 12);
                        buffer_write(rmb, buffer_u32, req);
                        server_broadcast(rmb);
                        buffer_delete(rmb);
                    }
                    break;

                case 15: // a player dropped an item
                    var ditem = buffer_read(buff, buffer_string);
                    var damt = buffer_read(buff, buffer_u16);
                    var dx = buffer_read(buff, buffer_f32);
                    var dy = buffer_read(buff, buffer_f32);
                    server_spawn_item(ditem, damt, dx, dy, true);
                    break;

                case 16: // a player says they hit another player
                    var atk_victim = buffer_read(buff, buffer_u16);
                    var atk_tool = buffer_read(buff, buffer_u8);
                    var atk_dmg = tool_power(atk_tool, "player");

                    var pos_a = positions[? sender];
                    var pos_v = positions[? atk_victim];

                    // a damaging tool, a real connected victim, and the two really are close together
                    if (atk_dmg > 0 && atk_victim != sender && ds_list_find_index(clients, atk_victim) != -1
                        && !is_undefined(pos_a) && !is_undefined(pos_v)
                        && point_distance(pos_a[0], pos_a[1], pos_v[0], pos_v[1]) <= 220) {
                        var dmb = buffer_create(8, buffer_grow, 1);
                        buffer_write(dmb, buffer_u8, 17);
                        buffer_write(dmb, buffer_u16, atk_dmg);
                        network_send_packet(atk_victim, dmb, buffer_tell(dmb));
                        buffer_delete(dmb);
                    }
                    break;

                case 19: // a player hit a tree or rock
                    var hr_id = buffer_read(buff, buffer_u32);
                    var hr_tool = buffer_read(buff, buffer_u8);
                    var hr_res = resources[? hr_id];
                    var hr_pos = positions[? sender];

                    if (!is_undefined(hr_res) && !is_undefined(hr_pos)) {
                        var hr_def = global.resource_db[$ hr_res.type];
                        var hr_power = tool_power(hr_tool, hr_res.type);   // 0 if this tool can't harm it
                        if (hr_power > 0 && point_distance(hr_pos[0], hr_pos[1], hr_res.x, hr_res.y) <= 260) {
                            hr_res.hp -= hr_power;
                            var hr_b = buffer_create(16, buffer_grow, 1);
                            if (hr_res.hp > 0) {
                                buffer_write(hr_b, buffer_u8, 20);              // new health, for everyone
                                buffer_write(hr_b, buffer_u32, hr_id);
                                buffer_write(hr_b, buffer_f32, hr_res.hp);
                            } else {
                                buffer_write(hr_b, buffer_u8, 21);              // gone, for everyone
                                buffer_write(hr_b, buffer_u32, hr_id);
                                ds_map_delete(resources, hr_id);
                                ds_list_add(res_gone, hr_id);
                                var hr_amt = irandom_range(hr_def.drop_min, hr_def.drop_max);
                                server_spawn_item(hr_def.drop_item, hr_amt, hr_res.x + irandom_range(-24, 24), hr_res.y + irandom_range(0, 24), true);
                            }
                            server_broadcast(hr_b);
                            buffer_delete(hr_b);
                        }
                    }
                    break;

                default: // unknown message: skip the rest of this packet
                    buffer_seek(buff, buffer_seek_start, size);
                    break;
            }
        }
        break;
}