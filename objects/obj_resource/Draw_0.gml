var shake_x = (shake_timer > 0) ? random_range(-2, 2) : 0;
draw_sprite_ext(sprite_index, image_index, x + shake_x, y, image_xscale, image_yscale, 0, c_white, fade_alpha);

// small health bar, only when your own player is close
if (near_player && hp_max > 0 && !(bar_only_when_damaged && hp >= hp_max)) {
    var bar_w = 48;
    var bar_h = 6;
    var bar_x = x - bar_w / 2;
    var bar_y = y + 6;
    var bar_f = clamp(real(hp) / real(hp_max), 0, 1);

    draw_set_alpha(0.6);
    draw_set_color(c_black);
    draw_rectangle(bar_x - 1, bar_y - 1, bar_x + bar_w + 1, bar_y + bar_h + 1, false);
    draw_set_alpha(1);
    draw_set_color(make_colour_hsv(bar_f * 85, 220, 220));
    draw_rectangle(bar_x, bar_y, bar_x + bar_w * bar_f, bar_y + bar_h, false);
    draw_set_color(c_white);
    draw_rectangle(bar_x, bar_y, bar_x + bar_w, bar_y + bar_h, true);
}
draw_set_alpha(1);
draw_set_color(c_white);