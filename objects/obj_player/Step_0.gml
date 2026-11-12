// obj_player Step event
// Read input
var h = keyboard_check(ord("D")) - keyboard_check(ord("A"));
var v = keyboard_check(ord("S")) - keyboard_check(ord("W"));

// Normalize diagonal movement
var len = point_distance(0, 0, h, v);
if (len > 0) {
    h /= len;
    v /= len;
}

// ---- speed and stamina ----
var moving = can_move && (h != 0 || v != 0);

// running out of stamina locks sprinting until some comes back
if (staminaBar <= 0) exhausted = true;
if (staminaBar >= stamina_recover) exhausted = false;

var sprinting = keyboard_check(vk_shift) && moving && !exhausted;

current_speed = sprinting ? a_speed : move_speed;

// water has its own walking and running speeds
var feet_x = (bbox_left + bbox_right) / 2;
in_water = !world_land_at_px(feet_x, bbox_bottom);
if (in_water) current_speed = sprinting ? water_run_speed : water_walk_speed;

// drain while sprinting, otherwise refill (slower while moving)
if (sprinting) staminaBar -= stamina_drain;
else if (moving) staminaBar += stamina_regen_moving;
else staminaBar += stamina_regen_idle;
staminaBar = clamp(staminaBar, 0, stamina_max);

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
var left_off   = x - bbox_left;
var right_off  = bbox_right - x;
var top_off    = y - bbox_top;
var bottom_off = bbox_bottom - y;

x = clamp(x, edge_margin + left_off,  room_width  - edge_margin - right_off);
y = clamp(y, edge_margin + top_off,   room_height - edge_margin - bottom_off);

// Send position to the server
if ((!sent_start || x != last_x || y != last_y) && instance_exists(obj_client)) {
    sent_start = true;
    var b = buffer_create(16, buffer_grow, 1);
    buffer_write(b, buffer_u8, 1);
    buffer_write(b, buffer_f32, x);
    buffer_write(b, buffer_f32, y);
    network_send_packet(obj_client.socket, b, buffer_tell(b));
    buffer_delete(b);
}

if (damage_timer > 0)
{
    damage_timer -= 1 / room_speed;
}
    last_x = x;
    last_y = y;
}

// keep health in range, and tell the server whenever it changes
hp = clamp(hp, 0, hp_max);
if (hp != last_hp && instance_exists(obj_client)) {
    last_hp = hp;
    var hb = buffer_create(8, buffer_grow, 1);
    buffer_write(hb, buffer_u8, 7);
    buffer_write(hb, buffer_u16, hp);
    buffer_write(hb, buffer_u16, hp_max);
    net_send_to_server(hb);
    buffer_delete(hb);
}

// TEMPORARY test keys, delete once real damage exists: K = take 10, L = heal 10
//if (keyboard_check_pressed(ord("K"))) hp -= 10;
//if (keyboard_check_pressed(ord("L"))) hp += 10;
