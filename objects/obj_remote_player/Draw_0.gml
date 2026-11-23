image_blend = (hurt_timer > 0) ? c_red : c_white;
draw_self();
image_blend = c_white;

if (view_current == 0) {
    var nm = player_name_for(net_pid);
    var tx = (bbox_left + bbox_right) / 2;
    draw_set_halign(fa_center);
    draw_set_color(c_black);
    draw_text(tx + 1, bbox_top - 19, nm);
    draw_set_color(c_white);
    draw_text(tx, bbox_top - 20, nm);
    draw_set_halign(fa_left);
} else if (view_current == 1) {
    // minimap marker: yellow = teammates
    var mm_s = view_wport[1] / camera_get_view_width(view_camera[1]);
    draw_set_color(c_black);
    draw_circle(x, y, 5 / mm_s, false);
    draw_set_color(c_yellow);
    draw_circle(x, y, 3 / mm_s, false);
    draw_set_color(c_white);
}