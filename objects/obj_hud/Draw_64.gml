// Draw GUI
if (!instance_exists(obj_player)) exit;

var hx = hud_x;
var bw = 240;      // your bar
var bh = 22;

// ---- you: the big bar ----
var my_frac = clamp(obj_player.hp / max(obj_player.hp_max, 1), 0, 1);
draw_set_color(c_white);
draw_text(hx, hud_y, my_player_name());

var by = hud_y + 22;
draw_set_alpha(0.6);
draw_set_color(c_black);
draw_rectangle(hx, by, hx + bw, by + bh, false);
draw_set_alpha(1);
draw_set_color(make_colour_hsv(my_frac * 85, 220, 220));   // green when full, red when empty
draw_rectangle(hx, by, hx + bw * my_frac, by + bh, false);
draw_set_color(c_white);
draw_rectangle(hx, by, hx + bw, by + bh, true);
draw_set_halign(fa_center);
draw_text(hx + bw / 2, by + 0, string(obj_player.hp) + " / " + string(obj_player.hp_max));
draw_set_halign(fa_left);

// ---- your stamina: a thin blue bar right under the health bar ----
var st_frac = clamp(obj_player.staminaBar / max(obj_player.stamina_max, 1), 0, 1);
var st_y = by + bh + 3;
var st_h = 5;
draw_set_alpha(0.6);
draw_set_color(c_black);
draw_rectangle(hx, st_y, hx + bw, st_y + st_h, false);
draw_set_alpha(1);
draw_set_color(obj_player.exhausted ? make_colour_rgb(90, 110, 160) : make_colour_rgb(60, 140, 255));
draw_rectangle(hx, st_y, hx + bw * st_frac, st_y + st_h, false);
draw_set_color(c_white);
draw_rectangle(hx, st_y, hx + bw, st_y + st_h, true);

// ---- everyone else: smaller bars underneath ----
var oy = by + bh + 14; // was 14
with (obj_remote_player) {
    var r_w = 150;
    var r_h = 10;
    var r_frac = clamp(real(hp) / max(real(hp_max), 1), 0, 1);
    var r_top = oy + 16;

    // name
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_text_transformed(hx, oy, player_name_for(net_pid), 0.75, 0.75, 0);

    // dark background
    draw_set_alpha(0.6);
    draw_set_color(c_black);
    draw_rectangle(hx, r_top, hx + r_w, r_top + r_h, false);

    // colored fill (green when full, red when empty)
    draw_set_alpha(1);
    draw_set_color(make_colour_hsv(r_frac * 85, 220, 220));
    draw_rectangle(hx, r_top, hx + r_w * r_frac, r_top + r_h, false);

    // outline
    draw_set_color(c_white);
    draw_rectangle(hx, r_top, hx + r_w, r_top + r_h, true);

    // debug numbers: delete this line once the bar looks right
    //draw_text(hx + r_w + 10, oy + 14, string(hp) + " / " + string(hp_max) + "  " + typeof(hp) + "  frac " + string(r_frac));

    oy += 36;
}
draw_set_alpha(1);
draw_set_color(c_white);


// DEBUG: delete when we've found it
var dbx = hud_x;
var dby = 300;
draw_set_color(c_yellow);
draw_text(dbx, dby, "servers: " + string(instance_number(obj_server)) + "   clients: " + string(instance_number(obj_client)) + "   remote players: " + string(instance_number(obj_remote_player)));
dby += 20;
if (instance_exists(obj_server)) {
    draw_text(dbx, dby, "server connections: " + string(ds_list_size(obj_server.clients)));
    dby += 20;
}
draw_text(dbx, dby, "me: hp " + string(obj_player.hp));
with (obj_remote_player) {
    dby += 20;
    draw_text(dbx, dby, "pid " + string(net_pid) + "   hp " + string(hp) + "   at " + string(round(x)) + ", " + string(round(y)));
}
draw_set_color(c_white);