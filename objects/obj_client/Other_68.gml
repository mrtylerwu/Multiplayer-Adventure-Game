// obj_client, Async - Networking event
async_count++;
last_type = async_load[? "type"];

switch (async_load[? "type"]) {
    case network_type_non_blocking_connect:
    connected = async_load[? "succeeded"];
    if (connected) {
        var jb = buffer_create(32, buffer_grow, 1);
        buffer_write(jb, buffer_u8, 0);                    // 0 = join
        buffer_write(jb, buffer_string, global.player_name);
        network_send_packet(socket, jb, buffer_tell(jb));
        buffer_delete(jb);
    }
    break;

    case network_type_data:
        var buff = async_load[? "buffer"];
        var size = async_load[? "size"];
        buffer_seek(buff, buffer_seek_start, 0);

        while (buffer_tell(buff) < size) {
            var msg_id = buffer_read(buff, buffer_u8);
			last_msg = "msg " + string(msg_id);

            switch (msg_id) {
                case 2: // another player moved
				    var pid = buffer_read(buff, buffer_u16);
				    var px = buffer_read(buff, buffer_f32);
				    var py = buffer_read(buff, buffer_f32);

				    var inst = remote_players[? pid];
				    if (is_undefined(inst) || !instance_exists(inst)) {
				        inst = instance_create_layer(px, py, "Instances", obj_remote_player);
				        inst.net_pid = pid;
				        remote_players[? pid] = inst;
				        var ph = pending_hp[? pid];
				        if (!is_undefined(ph)) {
				            inst.hp = ph[0];
				            inst.hp_max = ph[1];
				        }
				    }
				    inst.target_x = px;
				    inst.target_y = py;
				    break;
	
				// inside the while/switch(msg_id), next to case 2
				case 3: // lobby list
				    var n = buffer_read(buff, buffer_u8);
				    lobby = [];
				    repeat (n) {
				        var lid = buffer_read(buff, buffer_u16);
				        var lname = buffer_read(buff, buffer_string);
				        array_push(lobby, { id: lid, name: lname });
				    }
				    break;

				case 4: // start game
				    global.world_seed = buffer_read(buff, buffer_u32);
				    world_generate(global.world_seed);
				    room_goto(rm_game);
				    break;
					
				case 6: // someone else swung a tool
				    var spid = buffer_read(buff, buffer_u16);
				    var stool = buffer_read(buff, buffer_u8);
				    var saim = buffer_read(buff, buffer_f32);
				    var ssweep = buffer_read(buff, buffer_s8);

				    var rp = remote_players[? spid];
				    if (!is_undefined(rp) && instance_exists(rp) && stool < array_length(global.tool_list)) {
				        var sw = instance_create_layer(rp.x, rp.y, "Instances", obj_swing);
				        sw.owner = rp.id;      // the swing follows that player's character
				        sw.tool = stool;
				        sw.aim = saim;
				        sw.sweep = ssweep;
				    }
				    break;
					
				case 8: // another player's health
				    var hpid = buffer_read(buff, buffer_u16);
				    var hhp = buffer_read(buff, buffer_u16);
				    var hmax = buffer_read(buff, buffer_u16);
				    var hinst = remote_players[? hpid];
				    if (!is_undefined(hinst) && instance_exists(hinst)) {
				        hinst.hp = hhp;
				        hinst.hp_max = hmax;
				    } else {
				        pending_hp[? hpid] = [hhp, hmax];
				    }
				    break;
					
				case 11: // an item appeared on the ground
				    var sid = buffer_read(buff, buffer_u32);
				    var sitem = buffer_read(buff, buffer_string);
				    var samt = buffer_read(buff, buffer_u16);
				    var sx = buffer_read(buff, buffer_f32);
				    var sy = buffer_read(buff, buffer_f32);

				    if (room == rm_game && !ds_map_exists(world_pickups, sid)) {
				        var inst = instance_create_layer(sx, sy, "Instances", global.item_db[$ sitem].obj);
				        inst.net_id = sid;
				        inst.amount = samt;
				        world_pickups[? sid] = inst;
				    }
				    break;

				case 12: // an item was picked up by someone
				    var rid = buffer_read(buff, buffer_u32);
				    var rinst = world_pickups[? rid];
				    if (!is_undefined(rinst) && instance_exists(rinst)) {
				        with (rinst) instance_destroy();
				    }
				    ds_map_delete(world_pickups, rid);
				    break;

				case 14: // the server says: this pickup is yours
				    var gitem = buffer_read(buff, buffer_string);
				    var gamt = buffer_read(buff, buffer_u16);
				    var gleft = inventory_add(gitem, gamt);
				    if (gleft > 0) drop_item(gitem, gleft);   // bag filled up in the meantime: drop the rest
				    break;

                default:
                    buffer_seek(buff, buffer_seek_start, size);
                    break;
            }
        }
        break;
}