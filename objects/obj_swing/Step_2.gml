// obj_swing, End Step
if (!instance_exists(owner)) { instance_destroy(); exit; }

// first frame: read the settings for the chosen tool
if (!started) {
    started = true;
    var def = global.tool_list[tool];
    sprite_index = def.sprite;
    duration = def.swing_time;
    arc = def.swing_arc;
    reach = def.reach;
    tip = def.tip_angle;
    is_mine = (owner.object_index == obj_player);   // only your own swings can hit things
}

timer++;
var t = timer / duration;                 // 0 to 1 over the swing
var eased = 1 - power(1 - t, 3);          // fast start, slow finish

// the direction the tool points right now, sweeping through the arc
var dir = aim - sweep * arc / 2 + sweep * arc * eased;

// turn the sprite by the difference between that and where the art points
var sc = 1;                               // change this to scale the tool up or down
image_xscale = sc;
image_yscale = sweep * sc;
image_angle = dir - tip * sweep;

// the handle sits on a circle around the player's center, following them while they move
var cx = (owner.bbox_left + owner.bbox_right) / 2;
var cy = (owner.bbox_top + owner.bbox_bottom) / 2;
x = cx + lengthdir_x(reach, dir);
y = cy + lengthdir_y(reach, dir);

depth = owner.depth - 1;                  // in front of the player, even as their depth changes
image_alpha = (t < 0.7) ? 1 : 1 - (t - 0.7) / 0.3;

// ---- hits: other players, and trees and rocks ----
if (is_mine) {
    var can_hurt_players = (tool_power(tool, "player") > 0);
    var hits = ds_list_create();

    // check four spots from near the player out to the tip of the tool
    var steps = 4;
    for (var k = 1; k <= steps; k++) {
        var d = lerp(reach * 0.5, reach + blade_len, k / steps);
        var hx = cx + lengthdir_x(d, dir);
        var hy = cy + lengthdir_y(d, dir);
        if (can_hurt_players) collision_circle_list(hx, hy, hit_radius, obj_remote_player, false, true, hits, false);
        collision_circle_list(hx, hy, hit_radius, obj_resource, false, true, hits, false);
    }

    for (var i = 0; i < ds_list_size(hits); i++) {
        var hit_inst = hits[| i];
        if (ds_list_find_index(hit_ids, hit_inst) != -1) continue;   // one hit per swing
        ds_list_add(hit_ids, hit_inst);

        if (variable_instance_exists(hit_inst, "res_type")) {
            // a tree or rock: counts if this tool has any power against it
            if (hit_inst.net_id != -1 && tool_power(tool, hit_inst.res_type) > 0) {
                var rb = buffer_create(8, buffer_grow, 1);
                buffer_write(rb, buffer_u8, 19);
                buffer_write(rb, buffer_u32, hit_inst.net_id);
                buffer_write(rb, buffer_u8, tool);
                net_send_to_server(rb);
                buffer_delete(rb);
            }
        } else if (hit_inst.net_pid >= 0) {
            // another player
            hit_inst.hurt_timer = 10;   // red flash on your screen right away
            var hb = buffer_create(8, buffer_grow, 1);
            buffer_write(hb, buffer_u8, 16);
            buffer_write(hb, buffer_u16, hit_inst.net_pid);
            buffer_write(hb, buffer_u8, tool);
            net_send_to_server(hb);
            buffer_delete(hb);
        }
    }
    ds_list_destroy(hits);
}

if (timer >= duration) instance_destroy();