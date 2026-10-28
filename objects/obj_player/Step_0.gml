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

if (can_move == true) {
    // Horizontal movement
    if (h != 0) {
        hit_h = instance_place(x + h * current_speed, y, all);
        if (hit_h == noone || !hit_h.solid) {
            x += h * current_speed;
        }
    }

    // Vertical movement
    if (v != 0) {
        hit_v = instance_place(x, y + v * current_speed, all);
        if (hit_v == noone || !hit_v.solid) {
            y += v * current_speed;
        }
    }
}

// Send position to the server
if (instance_exists(obj_client)) {
    var b = buffer_create(16, buffer_grow, 1);
    buffer_write(b, buffer_u8, 1);
    buffer_write(b, buffer_f32, x);
    buffer_write(b, buffer_f32, y);
    network_send_packet(obj_client.socket, b, buffer_tell(b));
    buffer_delete(b);
}