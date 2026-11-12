draw_self();
if (view_current == 1) {
    draw_set_color(c_lime);
    draw_circle(x, y, 200, false);
    draw_set_color(c_white);
}

var nm = my_player_name();
var tx = (bbox_left + bbox_right) / 2;
draw_set_halign(fa_center);
draw_set_color(c_black);
draw_text(tx + 1, bbox_top - 34, nm);
draw_set_color(c_white);
draw_text(tx, bbox_top - 35, nm);
draw_set_halign(fa_left);