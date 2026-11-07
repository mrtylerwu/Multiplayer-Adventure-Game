// obj_player Step event
// Read input
var h = keyboard_check(ord("D")) - keyboard_check(ord("A"));
var v = keyboard_check(ord("S")) - keyboard_check(ord("W"));

move_speed = 5;        // normal walking speed (pixels per frame)
a_speed = 7;           // sprint speed (while holding shift)
current_speed = move_speed;
staminaBar = 100;      // sprint only works while this is above 0
can_move = true;

// Normalize diagonal movement
var len = point_distance(0, 0, h, v);
if (len > 0) {
    h /= len;
    v /= len;
}

current_speed = move_speed;
if (keyboard_check(vk_shift) and staminaBar > 0) {
    current_speed = a_speed;
}

// water slows you down by half (tested at the player's feet)
var feet_x = (bbox_left + bbox_right) / 2;
in_water = !world_land_at_px(feet_x, bbox_bottom);
if (in_water) {
    var running = keyboard_check(vk_shift) and staminaBar > 0;   // same condition as your sprint check
    current_speed = running ? water_run_speed : water_walk_speed;
}


if (can_move == true) {
    // Horizontal movement
	if (h != 0) {
	    var dx = h * current_speed;
	    hit_h = instance_place(x + dx, y, all);
	    if ((hit_h == noone || !hit_h.solid) && bbox_left + dx >= 0 && bbox_right + dx < room_width) {
	        x += dx;
	    }
	}

	// Vertical movement
	if (v != 0) {
	    var dy = v * current_speed;
	    hit_v = instance_place(x, y + dy, all);
	    if ((hit_v == noone || !hit_v.solid) && bbox_top + dy >= 0 && bbox_bottom + dy < room_height) {
	        y += dy;
	    }
	}
}

// keep the player inside the map, with a margin before the true edge
var left_off   = x - bbox_left;     // distance from the player's origin to each side of the hitbox
var right_off  = bbox_right - x;
var top_off    = y - bbox_top;
var bottom_off = bbox_bottom - y;

x = clamp(x, edge_margin + left_off,  room_width  - edge_margin - right_off);
y = clamp(y, edge_margin + top_off,   room_height - edge_margin - bottom_off);


// Send position to the server
if ((x != last_x || y != last_y) && instance_exists(obj_client)) {
    var b = buffer_create(16, buffer_grow, 1);
    buffer_write(b, buffer_u8, 1);
    buffer_write(b, buffer_f32, x);
    buffer_write(b, buffer_f32, y);
    network_send_packet(obj_client.socket, b, buffer_tell(b));
    buffer_delete(b);
    last_x = x;
    last_y = y;
}