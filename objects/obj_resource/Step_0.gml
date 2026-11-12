if (shake_timer > 0) shake_timer--;
if (hp_max < 0 && res_type != "") hp_max = global.resource_db[$ res_type].hp;

// this only looks at YOUR player: are they close, and are they standing behind us?
near_player = false;
var fade_target = 1;
if (instance_exists(obj_player)) {
    var dist = point_distance(x, y, obj_player.x, obj_player.y);
    near_player = (dist <= show_range);

    if (dist < 300) {
        var sl = x - sprite_get_xoffset(sprite_index) * image_xscale;
        var st = y - sprite_get_yoffset(sprite_index) * image_yscale;
        var sr = sl + sprite_width;
        var sb = st + sprite_height;
        var behind = (obj_player.bbox_bottom <= y)
            && rectangle_in_rectangle(obj_player.bbox_left, obj_player.bbox_top, obj_player.bbox_right, obj_player.bbox_bottom, sl, st, sr, sb) != 0;
        if (behind) fade_target = 0.45;
    }
}
fade_alpha = lerp(fade_alpha, fade_target, 0.2);