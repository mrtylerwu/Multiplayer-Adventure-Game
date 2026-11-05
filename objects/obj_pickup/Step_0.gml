near = false;
hovered = false;

if (instance_exists(obj_player) && !global.inv_open) {
    near = (distance_to_object(obj_player) <= pickup_range);
    // generous box around the sprite, so odd collision masks don't matter
    hovered = point_in_rectangle(mouse_x, mouse_y, bbox_left - 4, bbox_top - 4, bbox_right + 4, bbox_bottom + 4);
}

/*if (near && hovered && mouse_check_button_pressed(mb_left)) {
    var left = inventory_add(item_id, amount);
    if (left <= 0) instance_destroy();
    else amount = left;   // inventory was full, leave the rest on the ground
}*/

if (near && hovered && net_id != -1 && mouse_check_button_pressed(mb_left)) {
    var b = buffer_create(8, buffer_grow, 1);
    buffer_write(b, buffer_u8, 13);
    buffer_write(b, buffer_u32, net_id);
    net_send_to_server(b);
    buffer_delete(b);
}