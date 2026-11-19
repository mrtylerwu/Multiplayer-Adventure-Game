event_inherited();
interact_text = "Click to restore the totem";
map_color = make_colour_rgb(255, 235, 140);

gui_msg = "";
gui_msg_timer = 0;
gui_w = 0;
gui_h = 0;
panel_x = 0;
panel_y = 0;
panel_w = 760;
panel_h = 400;
slot_size = 104;
slot_gap = 56;
btn_w = 220;
btn_h = 52;

// where everything sits inside the panel
gui_layout = function() {
    gui_w = display_get_gui_width();
    gui_h = display_get_gui_height();
    panel_x = (gui_w - panel_w) / 2;
    panel_y = (gui_h - panel_h) / 2;
};
slot_x = function(i) { return panel_x + (panel_w - (4 * slot_size + 3 * slot_gap)) / 2 + i * (slot_size + slot_gap); };
slot_y = function() { return panel_y + 100; };
btn_x = function() { return panel_x + (panel_w - btn_w) / 2; };
btn_y = function() { return panel_y + panel_h - btn_h - 30; };