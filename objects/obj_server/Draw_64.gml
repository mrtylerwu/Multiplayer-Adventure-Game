draw_text(10, 340, "Server: clients = " + string(ds_list_size(clients)));
draw_text(10, 360, "Server: packets received = " + string(packets_received));
draw_text(10, 380, "Server socket: " + string(server));
draw_text(10, 400, "Async events: " + string(async_count));
draw_text(10, 420, "Server async: " + string(async_count) + " type: " + string(last_type));