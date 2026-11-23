if (view_current == 1) {
    if (map_visible) {
        var mm_s = view_wport[1] / camera_get_view_width(view_camera[1]);
        draw_set_color(c_black);
        draw_circle(x, y, 5 / mm_s, false);
        draw_set_color(c_aqua);
        draw_circle(x, y, 4 / mm_s, false);
        draw_set_color(c_black);
        draw_circle(x, y, 1.5 / mm_s, false);
        draw_set_color(c_white);
    }
    exit;
}

var restored = variable_global_exists("base_restored") && global.base_restored;
var glow = 1;   // constant, so it doesn't fade in and out
draw_sprite_ext(sprite_index, 0, x, y, zone_scale, zone_scale, 0, restored ? make_colour_rgb(160, 255, 180) : c_white, glow);

// how many players are inside right now
var here = 0;
var total = 1;
if (instance_exists(obj_player) && point_distance(x, y, obj_player.x, obj_player.y) <= EXTRACT_RADIUS) here++;
for (var i = 0; i < instance_number(obj_remote_player); i++) {
    var rp = instance_find(obj_remote_player, i);
    total++;
    if (point_distance(x, y, rp.x, rp.y) <= EXTRACT_RADIUS) here++;
}

var label = "EXTRACTION  " + string(here) + " / " + string(total);
var label2 = restored ? "Everyone get inside!" : "Restore the totem first";
draw_set_halign(fa_center);
draw_set_color(c_black);
draw_text(x + 1, y - EXTRACT_RADIUS - 39, label);
draw_text(x + 1, y - EXTRACT_RADIUS - 19, label2);
draw_set_color(c_white);
draw_text(x, y - EXTRACT_RADIUS - 40, label);
draw_text(x, y - EXTRACT_RADIUS - 20, label2);
draw_set_halign(fa_left);