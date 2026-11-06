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