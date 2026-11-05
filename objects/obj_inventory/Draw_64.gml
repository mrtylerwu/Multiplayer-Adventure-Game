if (!global.inv_open) exit;

var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);

// panel
draw_set_alpha(ui_alpha);
draw_set_color(c_black);
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, false);
draw_set_alpha(1);
draw_set_color(c_white);
draw_text(panel_x + pad, panel_y + 6, "Inventory");

// slots
for (var i = 0; i < array_length(global.inv_slots); i++) {
    var sx = slot_x(i);
    var sy = slot_y(i);

    // slot background (a bit brighter under the mouse)
    draw_set_alpha(i == hover_slot ? ui_alpha + 0.25 : ui_alpha);
    draw_set_color(c_dkgray);
    draw_rectangle(sx, sy, sx + slot_size, sy + slot_size, false);

    // slot outline
    draw_set_alpha(0.6);
    draw_set_color(c_white);
    draw_rectangle(sx, sy, sx + slot_size, sy + slot_size, true);

    // back to full alpha for icons and text
    draw_set_alpha(1);

    var s = global.inv_slots[i];
    if (is_struct(s)) {
        draw_item_icon(s.item, sx + slot_size / 2, sy + slot_size / 2, slot_size - 12, 1);
        if (s.count > 1) {
            draw_set_halign(fa_right);
            draw_set_valign(fa_bottom);
            draw_text(sx + slot_size - 4, sy + slot_size - 2, string(s.count));
            draw_set_halign(fa_left);
            draw_set_valign(fa_top);
        }
    }
}

// the stack you're dragging follows the mouse
/*if (drag_from != -1) {
    draw_item_icon(drag_item.item, mx, my, slot_size - 12, 0.9);
    draw_text(mx + 12, my + 12, string(drag_item.count));
}
// name tooltip when hovering a stack
else if (hover_slot != -1 && is_struct(global.inv_slots[hover_slot])) {
    draw_text(mx + 14, my + 14, global.item_db[$ global.inv_slots[hover_slot].item].name);
}*/

if (drag_from != -1) {
    draw_item_icon(drag_item.item, mx, my, slot_size - 12, 0.9);
    draw_text(mx + 12, my + 12, string(drag_item.count));
    if (!point_in_rectangle(mx, my, panel_x, panel_y, panel_x + panel_w, panel_y + panel_h)) {
        draw_text(mx + 12, my + 32, "Click: drop all   Right-click: drop 1");
    }
}