// the win: the totem is restored, and every connected player is inside the extraction zone
if (game_won || (base_mask & 8) == 0) exit;

extract_timer++;
if (extract_timer < 10) exit;         // checks about 6 times a second
extract_timer = 0;

var n = ds_list_size(clients);
if (n == 0) exit;

var all_here = true;
for (var i = 0; i < n; i++) {
    var p = positions[? clients[| i]];
    if (is_undefined(p) || point_distance(p[0], p[1], extract_x, extract_y) > EXTRACT_RADIUS) {
        all_here = false;
        break;
    }
}

if (all_here) {
    game_won = true;
    var wb = buffer_create(4, buffer_grow, 1);
    buffer_write(wb, buffer_u8, 23);   // the same "everyone wins" message the old totem win used
    server_broadcast(wb);
    buffer_delete(wb);
}