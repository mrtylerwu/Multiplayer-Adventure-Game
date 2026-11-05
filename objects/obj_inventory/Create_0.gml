inventory_init();
slot_size = 56;
pad = 6;
drag_from = -1;
drag_item = -1;
hover_slot = -1;
panel_x = 0; panel_y = 0; panel_w = 0; panel_h = 0;
ui_alpha = 0.35;   // 0 = invisible backgrounds, 1 = solid

slot_x = function(i) { return panel_x + pad + (i mod global.inv_cols) * (slot_size + pad); };
slot_y = function(i) { return panel_y + 30 + pad + (i div global.inv_cols) * (slot_size + pad); };

held_by_button = false;   // true while the mouse button is still down from picking a stack up

// put the held stack into a slot (merge / swap / move)
place_held = function(target) {
    var t = global.inv_slots[target];
    if (is_struct(t) && t.item == drag_item.item) {
        var space = global.item_db[$ t.item].max_stack - t.count;
        var moved = min(space, drag_item.count);
        t.count += moved;
        drag_item.count -= moved;
        if (drag_item.count > 0) global.inv_slots[drag_from] = drag_item;
    } else {
        global.inv_slots[drag_from] = t;
        global.inv_slots[target] = drag_item;
    }
    drag_from = -1;
    drag_item = -1;
};