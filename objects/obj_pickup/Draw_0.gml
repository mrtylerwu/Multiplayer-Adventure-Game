// Draw
if (view_current == 1) {
    var mm_s = view_wport[1] / camera_get_view_width(view_camera[1]);   // how much the minimap shrinks the world
    var mm_cx = (bbox_left + bbox_right) / 2;
    var mm_cy = (bbox_top + bbox_bottom) / 2;

    var mm_col = c_white;                       // anything else: white
    var mm_r = 2 / mm_s;                        // dot radius: 5 minimap pixels
    if (item_id == "wood")  mm_col = make_colour_rgb(200, 140, 60);
    if (item_id == "stone") mm_col = c_ltgray;
    if (string_copy(item_id, 1, 5) == "totem") {
        mm_col = make_colour_rgb(255, 215, 0);                  // totem pieces: gold, bigger, pulsing
        mm_r = (6 + sin(current_time / 200)) / mm_s;
    }

    draw_set_color(c_black);
    draw_circle(mm_cx, mm_cy, mm_r + 2 / mm_s, false);          // dark outline so it stands out
    draw_set_color(mm_col);
    draw_circle(mm_cx, mm_cy, mm_r, false);
    draw_set_color(c_white);
    exit;
}

draw_self();
//if (view_current == 1) { draw_self(); exit; }

if (near) {
    var pulse = 0.25 + 0.15 * sin(current_time / 200 + glow_t);
    var cx = (bbox_left + bbox_right) / 2;
    var cy = (bbox_top + bbox_bottom) / 2;
    var r = max(sprite_width, sprite_height) * 0.7;

    gpu_set_blendmode(bm_add);

    // soft halo: stacked circles fade out toward the edge
    draw_set_color(make_colour_rgb(255, 220, 120));
    for (var k = 3; k >= 1; k--) {
        draw_set_alpha(pulse * 0.25);
        draw_circle(cx, cy, r * (1 + k * 0.3), false);
    }

    // bright shine on the sprite itself (stronger while the mouse is over it)
    draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, c_white, hovered ? 0.6 : pulse);

    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    draw_set_color(c_white);
}