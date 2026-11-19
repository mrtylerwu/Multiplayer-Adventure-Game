if (sprite_index == -1) exit;

// DEBUG: tells us which object has no sprite (delete once it works)
if (sprite_index == -1) {
    if (!variable_global_exists("struct_warned")) {
        global.struct_warned = true;
        show_message("No sprite on: " + object_get_name(object_index) + " at " + string(round(x)) + ", " + string(round(y)));
    }
    exit;
}

// the whole drawn picture, not just the solid footprint
var sl = x - sprite_get_xoffset(sprite_index) * image_xscale;
var st = y - sprite_get_yoffset(sprite_index) * image_yscale;
var sr = sl + sprite_width;
var sb = st + sprite_height;

near_me = false;
hover_me = false;
var fade_target = 1;

if (instance_exists(obj_player)) {
    near_me = (distance_to_object(obj_player) <= interact_range);
    hover_me = point_in_rectangle(mouse_x, mouse_y, sl, st, sr, sb);

    // see-through when YOUR player stands behind it
    if (can_fade && point_distance(x, y, obj_player.x, obj_player.y) < 500) {
        var behind = (obj_player.bbox_bottom <= y)
            && rectangle_in_rectangle(obj_player.bbox_left, obj_player.bbox_top, obj_player.bbox_right, obj_player.bbox_bottom, sl, st, sr, sb) != 0;
        if (behind) fade_target = 0.45;
    }
}
fade_alpha = lerp(fade_alpha, fade_target, 0.2);