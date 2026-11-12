// obj_world Draw GUI
var x1 = view_xport[1];
var y1 = view_yport[1];
var x2 = x1 + view_wport[1] - 1;
var y2 = y1 + view_hport[1] - 1;

// outer dark line, then a 3px light border just outside the map
draw_set_color(c_white);
draw_rectangle(x1 - 4, y1 - 4, x2 + 4, y2 + 4, true);

draw_set_color(c_white);
for (var i = 1; i <= 3; i++) {
    draw_rectangle(x1 - i, y1 - i, x2 + i, y2 + i, true);
}



/*
// Draw GUI
if (!variable_global_exists("minimap")) exit;

var size = 220;                                   // minimap size on screen, in pixels
var mx0 = display_get_gui_width() - size - 20;    // top-right corner
var my0 = 20;
var k = size / room_width;                        // world pixels to minimap pixels

// the map
var tf = gpu_get_texfilter();
gpu_set_texfilter(false);
draw_sprite_stretched(global.minimap, 0, mx0, my0, size, size);
gpu_set_texfilter(tf);

// items on the ground
with (obj_pickup) {
    var c = c_white;
    if (item_id == "wood") c = make_colour_rgb(200, 140, 60);
    if (item_id == "stone") c = c_ltgray;
    draw_set_color(c_black);
    draw_circle(mx0 + x * k, my0 + y * k, 3, false);
    draw_set_color(c);
    draw_circle(mx0 + x * k, my0 + y * k, 2, false);
}

// teammates (yellow) and you (lime)
draw_set_color(c_yellow);
with (obj_remote_player) draw_circle(mx0 + x * k, my0 + y * k, 4, false);
draw_set_color(c_lime);
with (obj_player) draw_circle(mx0 + x * k, my0 + y * k, 4, false);

// border
draw_set_color(c_black);
draw_rectangle(mx0 - 4, my0 - 4, mx0 + size + 3, my0 + size + 3, true);
draw_set_color(c_white);
for (var b = 1; b <= 3; b++) {
    draw_rectangle(mx0 - b, my0 - b, mx0 + size - 1 + b, my0 + size - 1 + b, true);
}
draw_set_color(c_white);
*/