// obj_pickup, Step
if (full_timer > 0) full_timer--;

near = false;
hovered = false;

if (instance_exists(obj_player) && !global.inv_open && !global.base_gui_open) {
    near = (distance_to_object(obj_player) <= pickup_range);
    // generous box around the sprite, so odd collision masks don't matter
    hovered = point_in_rectangle(mouse_x, mouse_y, bbox_left - 4, bbox_top - 4, bbox_right + 4, bbox_bottom + 4);
}

// pickup: only when you click it, while it's close
if (near && hovered && net_id != -1 && mouse_check_button_pressed(mb_left)) {
    global.click_used = true;          // so the same click doesn't also swing a tool
    if (inventory_has_room(item_id, amount)) {
        var b = buffer_create(8, buffer_grow, 1);
        buffer_write(b, buffer_u8, 13);
        buffer_write(b, buffer_u32, net_id);
        net_send_to_server(b);
        buffer_delete(b);
    } else {
        full_timer = 90;               // shows "Bag full" above the item
    }
}