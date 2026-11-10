// Create
tools_init();
slot_size = 56;
gap = 8;
bar_x = 0;
bar_y = 0;
swing_dir = 1;     // flips each swing so they alternate direction

my_swing = noone;   // the swing object that belongs to you

update_layout = function() {
    var n = array_length(global.tool_list);
    var total_w = n * slot_size + (n - 1) * gap;
    bar_x = (display_get_gui_width() - total_w) / 2;
    bar_y = display_get_gui_height() - slot_size - 20;
};