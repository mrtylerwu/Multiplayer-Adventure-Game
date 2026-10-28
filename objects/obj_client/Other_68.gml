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
				        remote_players[? pid] = inst;
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
				    room_goto(rm_game);
				    break;

                default:
                    buffer_seek(buff, buffer_seek_start, size);
                    break;
            }
        }
        break;
}