// open / close
if (keyboard_check_pressed(ord("E"))) {
    global.inv_open = !global.inv_open;

    if (!global.inv_open && drag_from != -1) {   // closed while holding: put it back
        global.inv_slots[drag_from] = drag_item;
        drag_from = -1;
        drag_item = -1;
        held_by_button = false;
    }
    if (instance_exists(obj_player)) obj_player.can_move = !global.inv_open;
}
if (!global.inv_open) exit;

// layout, centered on screen
panel_w = global.inv_cols * (slot_size + pad) + pad;
panel_h = global.inv_rows * (slot_size + pad) + pad + 30;
panel_x = (display_get_gui_width() - panel_w) / 2;
panel_y = (display_get_gui_height() - panel_h) / 2;

var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);
var over_panel = point_in_rectangle(mx, my, panel_x, panel_y, panel_x + panel_w, panel_y + panel_h);

// which slot is the mouse over?
hover_slot = -1;
for (var i = 0; i < array_length(global.inv_slots); i++) {
    if (point_in_rectangle(mx, my, slot_x(i), slot_y(i), slot_x(i) + slot_size, slot_y(i) + slot_size)) {
        hover_slot = i;
        break;
    }
}

var holding = (drag_from != -1);

// LEFT PRESS
if (mouse_check_button_pressed(mb_left)) {
    if (!holding) {
        // pick up a stack
        if (hover_slot != -1 && is_struct(global.inv_slots[hover_slot])) {
            drag_from = hover_slot;
            drag_item = global.inv_slots[hover_slot];
            global.inv_slots[hover_slot] = -1;
            held_by_button = true;
        }
    } else if (!over_panel) {
        // already carrying it, clicked outside the panel: drop the whole stack
        drop_item(drag_item.item, drag_item.count);
        drag_from = -1;
        drag_item = -1;
    } else if (hover_slot != -1) {
        // already carrying it, clicked a slot: place it
        place_held(hover_slot);
    }
}

// LEFT RELEASE (only matters right after picking something up)
if (mouse_check_button_released(mb_left) && held_by_button) {
    held_by_button = false;
    if (drag_from != -1) {
        if (!over_panel) {
            drop_item(drag_item.item, drag_item.count);   // dragged out of the panel
            drag_from = -1;
            drag_item = -1;
        } else if (hover_slot != -1 && hover_slot != drag_from) {
            place_held(hover_slot);                       // classic drag and drop
        }
        // released on its own slot: that was a click, so it keeps following the cursor
    }
}

// RIGHT CLICK outside the panel: drop one
if (mouse_check_button_pressed(mb_right) && drag_from != -1 && !over_panel) {
    drop_item(drag_item.item, 1);
    drag_item.count -= 1;
    if (drag_item.count <= 0) {
        drag_from = -1;
        drag_item = -1;
        held_by_button = false;
    }
}