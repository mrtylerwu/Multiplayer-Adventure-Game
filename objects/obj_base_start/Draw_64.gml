if (!global.base_gui_open) exit;

var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);
var ua = instance_exists(obj_inventory) ? obj_inventory.ui_alpha : 0.35;   // same see-through look as the inventory
var gold = make_colour_rgb(214, 178, 70);
var ax = global.asm_x;
var ay = global.asm_y;
var aw = global.asm_w;
var ah = global.asm_h;

// the panel
draw_set_alpha(ua);
draw_set_color(c_black);
draw_rectangle(ax, ay, ax + aw, ay + ah, false);
draw_set_alpha(1);
draw_set_color(c_white);
draw_rectangle(ax, ay, ax + aw, ay + ah, true);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_text(ax + 6, ay + 6, "Starter Base");

// the X button, top right
var x_left = ax + aw - 38;
var x_top = ay + 10;
draw_set_color(point_in_rectangle(mx, my, x_left, x_top, x_left + 28, x_top + 28) ? c_red : c_gray);
draw_rectangle(x_left, x_top, x_left + 28, x_top + 28, false);
draw_set_color(c_white);
draw_rectangle(x_left, x_top, x_left + 28, x_top + 28, true);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text(x_left + 14, x_top + 14, "X");

// the four slots: three inputs, then the finished totem
for (var i = 0; i < 4; i++) {
    var sx = asm_slot_x(i);
    var sy = asm_slot_y();
    var piece = (i < 3) ? global.base_slots[i] : 0;
    var filled = (i < 3) ? (piece != 0) : global.base_output;
    var over_slot = point_in_rectangle(mx, my, sx, sy, sx + ASM_SLOT, sy + ASM_SLOT);
    var hot = over_slot && (i < 3 || global.base_output);

    draw_set_alpha(hot ? ua + 0.25 : ua);
    draw_set_color(c_dkgray);
    draw_rectangle(sx, sy, sx + ASM_SLOT, sy + ASM_SLOT, false);
    draw_set_alpha(0.6);
    draw_set_color(filled && i == 3 ? gold : c_white);
    draw_rectangle(sx, sy, sx + ASM_SLOT, sy + ASM_SLOT, true);
    draw_set_alpha(1);

    if (i < 3 && filled) draw_item_icon("totem" + string(piece), sx + ASM_SLOT / 2, sy + ASM_SLOT / 2, ASM_SLOT - 12, 1);
    if (i == 3 && filled) draw_item_icon("totem", sx + ASM_SLOT / 2, sy + ASM_SLOT / 2, ASM_SLOT - 12, 1);
}

// [piece] + [piece] + [piece] => [totem]
draw_set_color(c_white);
var sym_y = asm_slot_y() + ASM_SLOT / 2;
draw_text_transformed(asm_slot_x(0) + ASM_SLOT + ASM_GAP / 2, sym_y, "+", 1.5, 1.5, 0);
draw_text_transformed(asm_slot_x(1) + ASM_SLOT + ASM_GAP / 2, sym_y, "+", 1.5, 1.5, 0);
draw_text_transformed(asm_slot_x(2) + ASM_SLOT + ASM_GAP / 2, sym_y, "=>", 1.5, 1.5, 0);

// status line
draw_set_valign(fa_top);
if (global.base_output) {
    draw_set_color(c_lime);
    draw_text_transformed(ax + aw / 2, ay + 148, "The totem is ready! Drag it into your inventory.", 0.8, 0.8, 0);
} else if (global.base_restored) {
    draw_set_color(c_lime);
    draw_text_transformed(ax + aw / 2, ay + 148, "The totem has been assembled.", 0.8, 0.8, 0);
} else {
    draw_set_color(c_ltgray);
    draw_text_transformed(ax + aw / 2, ay + 148, "Pick up a piece, then click a slot.", 0.8, 0.8, 0);
}

// the Assemble button
var have_all = (global.base_slots[0] != 0 && global.base_slots[1] != 0 && global.base_slots[2] != 0);
var bx = asm_btn_x();
var by0 = asm_btn_y();
var over = point_in_rectangle(mx, my, bx, by0, bx + ASM_BTN_W, by0 + ASM_BTN_H);
if (global.base_restored) draw_set_color(make_colour_rgb(70, 70, 70));
else if (have_all) draw_set_color(over ? make_colour_rgb(90, 210, 100) : make_colour_rgb(50, 160, 60));
else draw_set_color(over ? make_colour_rgb(100, 100, 100) : make_colour_rgb(80, 80, 80));
draw_rectangle(bx, by0, bx + ASM_BTN_W, by0 + ASM_BTN_H, false);
draw_set_color(c_white);
draw_rectangle(bx, by0, bx + ASM_BTN_W, by0 + ASM_BTN_H, true);
draw_set_valign(fa_middle);
draw_text(bx + ASM_BTN_W / 2, by0 + ASM_BTN_H / 2, global.base_restored ? "Assembled" : "Assemble");

// popup (missing pieces, wrong item, and so on)
if (global.base_msg_timer > 0) {
    var pw = aw - 50;
    var ph = 46;
    var px = ax + (aw - pw) / 2;
    var py = ay + 126 - ph / 2;
    draw_set_alpha(0.92);
    draw_set_color(c_black);
    draw_rectangle(px, py, px + pw, py + ph, false);
    draw_set_alpha(1);
    draw_set_color(c_yellow);
    draw_rectangle(px, py, px + pw, py + ph, true);
    draw_text(ax + aw / 2, py + ph / 2, global.base_msg);
}

// the stack you're carrying stays on top of this panel
if (instance_exists(obj_inventory) && obj_inventory.drag_from != -1) {
    draw_item_icon(obj_inventory.drag_item.item, mx, my, 44, 0.9);
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1);