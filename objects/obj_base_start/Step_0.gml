event_inherited();
if (global.base_msg_timer > 0) global.base_msg_timer--;

if (!global.base_gui_open) {
    // click the base while standing close to open the screen
    if (near_me && hover_me && !global.inv_open && !global.click_used && mouse_check_button_pressed(mb_left)) {
        global.base_gui_open = true;
        global.inv_open = true;                 // the inventory opens next to it
        global.click_used = true;
        if (instance_exists(obj_player)) obj_player.can_move = false;
    }
} else {
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);
    var clicked = mouse_check_button_pressed(mb_left);
    if (clicked) global.click_used = true;      // clicks on the screen must never swing a tool

    if (keyboard_check_pressed(vk_escape)) {
        base_close_gui();
    } else if (clicked) {
        var x_left = global.asm_x + global.asm_w - 38;
        var x_top = global.asm_y + 10;
        if (point_in_rectangle(mx, my, x_left, x_top, x_left + 28, x_top + 28)) {
            base_close_gui();                                   // the X
        } else if (point_in_rectangle(mx, my, asm_btn_x(), asm_btn_y(), asm_btn_x() + ASM_BTN_W, asm_btn_y() + ASM_BTN_H)) {
            base_assemble_click();                              // the Assemble button
        } else if (point_in_rectangle(mx, my, asm_slot_x(3), asm_slot_y(), asm_slot_x(3) + ASM_SLOT, asm_slot_y() + ASM_SLOT)) {
            base_take_totem();                                  // the finished totem
        }
    }
}