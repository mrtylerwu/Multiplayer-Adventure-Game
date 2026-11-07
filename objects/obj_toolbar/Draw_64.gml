// Draw GUI
update_layout();
var n = array_length(global.tool_list);

for (var i = 0; i < n; i++) {
    var sx = bar_x + i * (slot_size + gap);
    var sel = (i == global.tool_selected);

    // box
    draw_set_alpha(sel ? 0.55 : 0.35);
    draw_set_color(c_black);
    draw_rectangle(sx, bar_y, sx + slot_size, bar_y + slot_size, false);

    // border (gold and doubled when selected)
    draw_set_alpha(1);
    draw_set_color(sel ? c_yellow : c_white);
    draw_rectangle(sx, bar_y, sx + slot_size, bar_y + slot_size, true);
    if (sel) draw_rectangle(sx + 1, bar_y + 1, sx + slot_size - 1, bar_y + slot_size - 1, true);

    // icon (tilted 45 degrees so it reads as a held tool) and the key number
    draw_set_color(c_white);
    draw_sprite_fit(global.tool_list[i].sprite, sx + slot_size / 2, bar_y + slot_size / 2, slot_size - 14, 1, 0);
    draw_text(sx + 5, bar_y + 3, string(i + 1));
}

// name of the held tool above the bar (nothing when your hands are empty)
if (global.tool_selected != -1) {
    draw_set_halign(fa_center);
    draw_text(display_get_gui_width() / 2, bar_y - 24, global.tool_list[global.tool_selected].name);
    draw_set_halign(fa_left);
}