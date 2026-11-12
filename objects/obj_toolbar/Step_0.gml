// Step
update_layout();
var n = array_length(global.tool_list);

// number keys: press a number to equip it, press it again to put it away
for (var i = 0; i < n; i++) {
    if (keyboard_check_pressed(ord("1") + i)) {
        global.tool_selected = (global.tool_selected == i) ? -1 : i;
    }
}

// scroll wheel: cycles through tools (from empty hands it picks the first or last one)
var wheel = mouse_wheel_down() - mouse_wheel_up();
if (wheel != 0) {
    if (global.tool_selected == -1) global.tool_selected = (wheel > 0) ? 0 : n - 1;
    else global.tool_selected = (global.tool_selected + wheel + n) mod n;
}

// clicking a box works the same way: click the held tool's box again to put it away
if (!global.inv_open && mouse_check_button_pressed(mb_left)) {
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);
    for (var j = 0; j < n; j++) {
        var sx = bar_x + j * (slot_size + gap);
        if (point_in_rectangle(mx, my, sx, bar_y, sx + slot_size, bar_y + slot_size)) {
            global.tool_selected = (global.tool_selected == j) ? -1 : j;
            global.click_used = true;
        }
    }
}