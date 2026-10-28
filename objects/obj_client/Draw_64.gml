draw_text(10, 210, "Client connected: " + string(connected));
draw_text(10, 230, "Remote players: " + string(ds_map_size(remote_players)));
draw_text(10, 250, "Last msg from server: " + last_msg);
draw_text(10, 270, "Connect call returned: " + string(connect_result));
draw_text(10, 290, "Async events: " + string(async_count));
draw_text(10, 310, "Client async: " + string(async_count) + " type: " + string(last_type));