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
                    buffer_write(swb, buffer_u8, 6);
                    buffer_write(swb, buffer_u16, sender);
                    buffer_write(swb, buffer_u8, swing_tool);
                    buffer_write(swb, buffer_f32, swing_aim);
                    buffer_write(swb, buffer_s8, swing_sweep);
                    for (var sw_i = 0; sw_i < ds_list_size(clients); sw_i++) {
                        var sw_c = clients[| sw_i];
                        if (sw_c != sender) network_send_packet(sw_c, swb, buffer_tell(swb));
                    }
                    buffer_delete(swb);
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

                case 10: // a client finished loading rm_game: send it everything that's already happened
                    // items on the ground
                    var it_k = ds_map_find_first(world_items);
                    while (!is_undefined(it_k)) {
                        var it_b = buffer_create(32, buffer_grow, 1);
                        server_write_spawn(it_b, it_k, world_items[? it_k]);
                        network_send_packet(sender, it_b, buffer_tell(it_b));
                        buffer_delete(it_b);
                        it_k = ds_map_find_next(world_items, it_k);
                    }

                    // where every other player is
                    var ps_k = ds_map_find_first(positions);
                    while (!is_undefined(ps_k)) {
                        if (ps_k != sender) {
                            var ps_v = positions[? ps_k];
                            var ps_b = buffer_create(16, buffer_grow, 1);
                            buffer_write(ps_b, buffer_u8, 2);
                            buffer_write(ps_b, buffer_u16, ps_k);
                            buffer_write(ps_b, buffer_f32, ps_v[0]);
                            buffer_write(ps_b, buffer_f32, ps_v[1]);
                            network_send_packet(sender, ps_b, buffer_tell(ps_b));
                            buffer_delete(ps_b);
                        }
                        ps_k = ds_map_find_next(positions, ps_k);
                    }

                    // everyone's health
                    var hl_k = ds_map_find_first(healths);
                    while (!is_undefined(hl_k)) {
                        if (hl_k != sender) {
                            var hl_v = healths[? hl_k];
                            var hl_b = buffer_create(16, buffer_grow, 1);
                            buffer_write(hl_b, buffer_u8, 8);
                            buffer_write(hl_b, buffer_u16, hl_k);
                            buffer_write(hl_b, buffer_u16, hl_v[0]);
                            buffer_write(hl_b, buffer_u16, hl_v[1]);
                            network_send_packet(sender, hl_b, buffer_tell(hl_b));
                            buffer_delete(hl_b);
                        }
                        hl_k = ds_map_find_next(healths, hl_k);
                    }

                    // trees and rocks that are already damaged or cut down
                    server_send_resource_state(sender);
				    server_send_base_state(sender);   // BASE: what's already placed
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

				                // the main drop
				                var hr_amt = irandom_range(hr_def.drop_min, hr_def.drop_max);
				                server_spawn_item(hr_def.drop_item, hr_amt, hr_res.x + irandom_range(-24, 24), hr_res.y + irandom_range(0, 24), true);

				                // the bonus drop, if this resource has one (only some of the time)
				                if (variable_struct_exists(hr_def, "bonus_item") && random(1) < hr_def.bonus_chance) {
				                    var hr_bonus = irandom_range(hr_def.bonus_min, hr_def.bonus_max);
				                    if (hr_bonus > 0) {
				                        server_spawn_item(hr_def.bonus_item, hr_bonus, hr_res.x + irandom_range(-24, 24), hr_res.y + irandom_range(0, 24), true);
				                    }
				                }
				            }
				            server_broadcast(hr_b);
				            buffer_delete(hr_b);
				        }
				    }
				    break;					
					
				case 22: // TOTEM: someone holds the complete totem, so tell everyone
				    var win_b = buffer_create(4, buffer_grow, 1);
				    buffer_write(win_b, buffer_u8, 23);
				    server_broadcast(win_b);
				    buffer_delete(win_b);
				    break;
					
				case 24: // BASE: a player wants to put a totem piece in an assembly slot
				    var bd_slot = buffer_read(buff, buffer_u8);
				    var bd_piece = buffer_read(buff, buffer_u8);
				    var bd_pos = positions[? sender];

				    var bd_ok = (bd_slot >= 0 && bd_slot < 3 && bd_piece >= 1 && bd_piece <= 3
				        && base_slots[bd_slot] == 0 && !base_restored
				        && !is_undefined(bd_pos) && point_distance(bd_pos[0], bd_pos[1], base_x, base_y) <= 500);
				    if (bd_ok) {
				        for (var bd_i = 0; bd_i < 3; bd_i++) {
				            if (base_slots[bd_i] == bd_piece) bd_ok = false;     // each piece can only be in the base once
				        }
				    }

				    if (bd_ok) {
				        base_slots[bd_slot] = bd_piece;
				        server_send_base_state();                                // everyone sees it
				    } else {
				        var bd_b = buffer_create(4, buffer_grow, 1);             // not accepted: send the piece back
				        buffer_write(bd_b, buffer_u8, 25);
				        buffer_write(bd_b, buffer_u8, bd_piece);
				        network_send_packet(sender, bd_b, buffer_tell(bd_b));
				        buffer_delete(bd_b);
				        server_send_base_state(sender);                          // and correct their screen
				    }
				    break;

				case 27: // BASE: a player pressed Assemble
				    var as_pos = positions[? sender];
				    var as_have = [false, false, false, false];
				    for (var as_i = 0; as_i < 3; as_i++) {
				        if (base_slots[as_i] >= 1 && base_slots[as_i] <= 3) as_have[base_slots[as_i]] = true;
				    }
				    if (!base_restored && as_have[1] && as_have[2] && as_have[3]
				        && !is_undefined(as_pos) && point_distance(as_pos[0], as_pos[1], base_x, base_y) <= 500) {
				        base_slots = [0, 0, 0];          // the three pieces are used up
				        base_restored = true;            // the totem has been assembled
				        base_output = true;              // and it's waiting in the fourth slot
				        server_send_base_state();
				    }
				    break;
					
				case 28: // BASE: a player takes the finished totem
				    var tk_pos = positions[? sender];
				    if (base_output && !is_undefined(tk_pos) && point_distance(tk_pos[0], tk_pos[1], base_x, base_y) <= 500) {
				        base_output = false;

				        var tk_b = buffer_create(4, buffer_grow, 1);   // only the player who clicked first gets it
				        buffer_write(tk_b, buffer_u8, 29);
				        network_send_packet(sender, tk_b, buffer_tell(tk_b));
				        buffer_delete(tk_b);

				        server_send_base_state();                      // the fourth slot empties for everyone
				    }
				    break;
					
                default: // unknown message: skip the rest of this packet
                    buffer_seek(buff, buffer_seek_start, size);
                    break;
            }
        }
        break;
}