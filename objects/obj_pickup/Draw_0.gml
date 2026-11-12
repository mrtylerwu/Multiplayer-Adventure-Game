// Draw
if (view_current == 1) {
    // how much the minimap shrinks the world
    var s = view_wport[1] / camera_get_view_width(view_camera[1]);

    // size you want the icon to appear on the minimap, in minimap pixels
    var icon = 12 / s;   // converted to world pixels

    var cx = (bbox_left + bbox_right) / 2;
    var cy = (bbox_top + bbox_bottom) / 2;

    //draw_set_color(c_black);
    //draw_circle(cx, cy, icon * 0.65, false);    // dark backing so it stands out on grass
    draw_set_color(c_white);
    draw_item_icon(item_id, cx, cy, icon, 1);   // the item's own sprite, scaled up
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