if (sprite_index == -1) exit;

if (view_current == 1) {
    // the minimap shows a small marker, never the building itself
    if (map_visible) {
        var mm_s = view_wport[1] / camera_get_view_width(view_camera[1]);
        var mm_cy = y - sprite_height * 0.3;
        var mm_h = 3 / mm_s;          // half the marker's size, in minimap pixels
        var mm_o = 1 / mm_s;            // the outline
        draw_set_color(c_black);
        draw_rectangle(x - mm_h - mm_o, mm_cy - mm_h - mm_o, x + mm_h + mm_o, mm_cy + mm_h + mm_o, false);
        draw_set_color(map_color);
        draw_rectangle(x - mm_h, mm_cy - mm_h, x + mm_h, mm_cy + mm_h, false);
        draw_set_color(c_white);
    }
    exit;
}

draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, 0, c_white, fade_alpha);

// a small hint when you're close and pointing at it
if (near_me && hover_me && interact_text != "") {
    draw_set_halign(fa_center);
    draw_set_color(c_black);
    draw_text(x + 1, y - sprite_height - 17, interact_text);
    draw_set_color(c_white);
    draw_text(x, y - sprite_height - 18, interact_text);
    draw_set_halign(fa_left);
}