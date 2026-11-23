// closed while carrying a stack (E, Esc or the X on the base screen): put it away
if (!global.inv_open && drag_from != -1) {
    if (drag_from >= 0) {
        global.inv_slots[drag_from] = drag_item;                          // goes back where it came from
    } else {
        var back_left = inventory_add(drag_item.item, drag_item.count);   // came from the base: into the bag
        if (back_left > 0) drop_item(drag_item.item, back_left);
    }
    drag_from = -1;
    drag_item = -1;
    held_by_button = false;
}

// E opens and closes the inventory. on the base screen it closes the whole screen
if (keyboard_check_pressed(ord("E"))) {
    if (global.base_gui_open) {
        base_close_gui();
    } else {
        global.inv_open = !global.inv_open;
        if (instance_exists(obj_player)) obj_player.can_move = !global.inv_open;
    }
}
if (!global.inv_open) exit;

// layout, centered on screen. on the base screen the inventory slides left to make room for the assembly panel
panel_w = global.inv_cols * (slot_size + pad) + pad;
panel_h = global.inv_rows * (slot_size + pad) + pad + 30;
var total_w = panel_w;
if (global.base_gui_open) total_w += global.asm_gap + global.asm_w;
panel_x = (display_get_gui_width() - total_w) / 2;
panel_y = (display_get_gui_height() - panel_h) / 2;
if (global.base_gui_open) {
    global.asm_x = panel_x + panel_w + global.asm_gap;
    global.asm_y = (display_get_gui_height() - global.asm_h) / 2;
}

var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);
var over_panel = point_in_rectangle(mx, my, panel_x, panel_y, panel_x + panel_w, panel_y + panel_h);

// the assembly panel on the right (only on the base screen)
var over_asm = false;
var asm_hover = -1;       // 0 to 2 = the assembly slot under the mouse
if (global.base_gui_open) {
    over_asm = point_in_rectangle(mx, my, global.asm_x, global.asm_y, global.asm_x + global.asm_w, global.asm_y + global.asm_h);
    asm_hover = base_slot_at(mx, my);
}
var over_ui = over_panel || over_asm;    // anywhere on either panel

// which inventory slot is the mouse over?
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
    } else if (!over_ui) {
        // carrying a stack, clicked outside both panels: drop the whole stack
        drop_item(drag_item.item, drag_item.count);
        drag_from = -1;
        drag_item = -1;
    } else if (asm_hover != -1) {
        // carrying a stack, clicked an assembly slot: put one piece in
        if (base_deposit(asm_hover, drag_item.item)) {
            drag_item.count -= 1;
            if (drag_item.count <= 0) {
                drag_from = -1;
                drag_item = -1;
            }
        }
    } else if (hover_slot != -1) {
        // carrying a stack, clicked an inventory slot: place it
        place_held(hover_slot);
    }
}

// LEFT RELEASE (only matters right after picking something up)
if (mouse_check_button_released(mb_left) && held_by_button) {
    held_by_button = false;
    if (drag_from != -1) {
        if (!over_ui) {
            drop_item(drag_item.item, drag_item.count);    // dragged out of both panels
            drag_from = -1;
            drag_item = -1;
        } else if (asm_hover != -1) {
            if (drag_from >= 0) {
                // dragged onto an assembly slot
                if (base_deposit(asm_hover, drag_item.item)) drag_item.count -= 1;
                if (drag_item.count > 0) global.inv_slots[drag_from] = drag_item;   // anything left goes back where it came from
                drag_from = -1;
                drag_item = -1;
            } else {
                base_say("Put the totem in your inventory.");   // a totem from the base can't go in the input slots
            }
		}
        // released on its own slot: that was a click, so it keeps following the cursor
    }
}

// RIGHT CLICK outside both panels: drop one
if (mouse_check_button_pressed(mb_right) && drag_from != -1 && !over_ui) {
    drop_item(drag_item.item, 1);
    drag_item.count -= 1;
    if (drag_item.count <= 0) {
        drag_from = -1;
        drag_item = -1;
        held_by_button = false;
    }
}