if (!global.base_gui_open) exit;
gui_layout();

var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);
var mask = global.base_mask;
var restored = (mask & 8) != 0;
var all_placed = (mask & 7) == 7;
var gold = make_colour_rgb(214, 178, 70);

// dim the game behind the panel
draw_set_alpha(0.5);
draw_set_color(c_black);
draw_rectangle(0, 0, gui_w, gui_h, false);

// the panel
draw_set_alpha(0.92);
draw_set_color(make_colour_rgb(28, 24, 20));
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, false);
draw_set_alpha(1);
draw_set_color(gold);
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, true);
draw_rectangle(panel_x + 1, panel_y + 1, panel_x + panel_w - 1, panel_y + panel_h - 1, true);

// title
draw_set_halign(fa_center);
draw_set_color(c_white);
draw_text_transformed(panel_x + panel_w / 2, panel_y + 20, "STARTER BASE", 1.5, 1.5, 0);
draw_text(panel_x + panel_w / 2, panel_y + 58, "Place the three totem pieces, then restore the totem.");

// the X button
var x_left = panel_x + panel_w - 44;
var x_top = panel_y + 12;
draw_set_color(point_in_rectangle(mx, my, x_left, x_top, x_left + 32, x_top + 32) ? c_red : c_gray);
draw_rectangle(x_left, x_top, x_left + 32, x_top + 32, false);
draw_set_color(c_white);
draw_rectangle(x_left, x_top, x_left + 32, x_top + 32, true);
draw_set_valign(fa_middle);
draw_text(x_left + 16, x_top + 16, "X");

// the four slots: three pieces, then the finished totem
for (var i = 0; i < 4; i++) {
    var sx = slot_x(i);
    var sy = slot_y();
    var filled = (i < 3) ? ((mask & (1 << i)) != 0) : restored;
    var hot = (i < 3) && point_in_rectangle(mx, my, sx, sy, sx + slot_size, sy + slot_size);

    draw_set_alpha(0.75);
    draw_set_color(hot ? c_gray : c_dkgray);
    draw_rectangle(sx, sy, sx + slot_size, sy + slot_size, false);
    draw_set_alpha(1);
    draw_set_color(filled ? gold : c_white);
    draw_rectangle(sx, sy, sx + slot_size, sy + slot_size, true);
    if (filled) draw_rectangle(sx + 1, sy + 1, sx + slot_size - 1, sy + slot_size - 1, true);

    var icon = (i < 3) ? "totem" + string(i + 1) : "totem";
    draw_item_icon(icon, sx + slot_size / 2, sy + slot_size / 2, slot_size - 20, filled ? 1 : 0.2);
}

// [piece] + [piece] + [piece] => [totem]
draw_set_color(c_white);
var sym_y = slot_y() + slot_size / 2;
draw_text_transformed(slot_x(0) + slot_size + slot_gap / 2, sym_y, "+", 2, 2, 0);
draw_text_transformed(slot_x(1) + slot_size + slot_gap / 2, sym_y, "+", 2, 2, 0);
draw_text_transformed(slot_x(2) + slot_size + slot_gap / 2, sym_y, "=>", 2, 2, 0);

// status line
var mid_x = panel_x + panel_w / 2;
var status_y = slot_y() + slot_size + 26;
draw_set_valign(fa_top);
if (restored) {
    draw_set_color(c_lime);
    draw_text(mid_x, status_y, "The totem is restored! Bring everyone to the extraction zone.");
} else if (gui_msg_timer > 0) {
    draw_set_color(c_yellow);
    draw_text(mid_x, status_y, gui_msg);
} else {
    draw_set_color(c_ltgray);
    var placed_count = ((mask & 1) > 0) + ((mask & 2) > 0) + ((mask & 4) > 0);
    draw_text(mid_x, status_y, "Pieces placed: " + string(placed_count) + " / 3     (click a slot to place that piece)");
}

// the RESTORE button, centered near the bottom
var b_left = btn_x();
var b_top = btn_y();
var can_press = all_placed && !restored;
var over = point_in_rectangle(mx, my, b_left, b_top, b_left + btn_w, b_top + btn_h);
draw_set_color(can_press ? (over ? make_colour_rgb(90, 210, 100) : make_colour_rgb(50, 160, 60)) : make_colour_rgb(70, 70, 70));
draw_rectangle(b_left, b_top, b_left + btn_w, b_top + btn_h, false);
draw_set_color(can_press ? c_white : c_gray);
draw_rectangle(b_left, b_top, b_left + btn_w, b_top + btn_h, true);
draw_set_valign(fa_middle);
draw_text_transformed(b_left + btn_w / 2, b_top + btn_h / 2, restored ? "RESTORED" : "RESTORE", 1.3, 1.3, 0);

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1);