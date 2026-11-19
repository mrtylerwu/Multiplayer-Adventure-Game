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


// DEBUG: totem pieces (delete when found)
var td_x = display_get_gui_width() - 20;
var td_y = 270;                      // just below the minimap
draw_set_halign(fa_right);
draw_set_color(c_yellow);

draw_text(td_x, td_y, "TOTEM_ON: " + string(TOTEM_ON) + "   item list has totem1: " + string(variable_struct_exists(global.item_db, "totem1")));
td_y += 20;

if (instance_exists(obj_server)) {
    var ts = 0;
    var tk = ds_map_find_first(obj_server.world_items);
    while (!is_undefined(tk)) {
        var wi = obj_server.world_items[? tk];
        if (string_copy(wi.item, 1, 5) == "totem") ts++;
        tk = ds_map_find_next(obj_server.world_items, tk);
    }
    draw_text(td_x, td_y, "server has " + string(ts) + " totem pieces (" + string(ds_map_size(obj_server.world_items)) + " items total)");
    td_y += 20;
}

draw_text(td_x, td_y, "this game: totem1 x" + string(instance_number(obj_totem1)) + "  totem2 x" + string(instance_number(obj_totem2)) + "  totem3 x" + string(instance_number(obj_totem3)));
td_y += 20;

for (var tn = 0; tn < instance_number(obj_pickup); tn++) {
    var tp = instance_find(obj_pickup, tn);
    if (string_copy(tp.item_id, 1, 5) == "totem") {
        draw_text(td_x, td_y, tp.item_id + " at " + string(round(tp.x)) + ", " + string(round(tp.y)) + "   sprite " + string(tp.sprite_index));
        td_y += 20;
    }
}
if (instance_exists(obj_player)) draw_text(td_x, td_y, "you at " + string(round(obj_player.x)) + ", " + string(round(obj_player.y)));

draw_set_halign(fa_left);
draw_set_color(c_white);


// DEBUG: where is everything? (F3 hides it. delete when found)
if (!variable_instance_exists(id, "dbg_show")) dbg_show = true;
if (keyboard_check_pressed(vk_f3)) dbg_show = !dbg_show;

// what the generator says SHOULD exist (worked out once, from the seed)
if (!variable_instance_exists(id, "dbg_expected") && variable_global_exists("world_grid") && variable_global_exists("world_seed")) {
    dbg_expected = structures_generate(global.world_seed);
}

if (dbg_show) {
    var L = [];
    array_push(L, "fps " + string(fps) + "  (real " + string(round(fps_real)) + ")    instances " + string(instance_count));
    if (instance_exists(obj_player)) array_push(L, "YOU at " + string(round(obj_player.x)) + ", " + string(round(obj_player.y)));
    array_push(L, "in this room: world " + string(instance_number(obj_world)) + "  inventory " + string(instance_number(obj_inventory)) + "  toolbar " + string(instance_number(obj_toolbar)) + "  client " + string(instance_number(obj_client)) + "  server " + string(instance_number(obj_server)));
    array_push(L, "seed " + (variable_global_exists("world_seed") ? string(global.world_seed) : "NONE") + "    world grid " + (variable_global_exists("world_grid") ? "yes" : "NONE"));
    array_push(L, "trees " + string(instance_number(obj_tree)) + "  rocks " + string(instance_number(obj_rock)) + "  pickups " + string(instance_number(obj_pickup)) + "  swings " + string(instance_number(obj_swing)));

    // where the generator says the structures go
    if (variable_instance_exists(id, "dbg_expected")) {
        for (var e = 0; e < array_length(dbg_expected); e++) {
            var exp_s = dbg_expected[e];
            array_push(L, "SHOULD BE: " + exp_s.type + " at " + string(round(exp_s.x)) + ", " + string(round(exp_s.y)));
        }
    }

    // what really exists in this game
    if (instance_number(obj_base_start) == 0) array_push(L, "IN GAME: starter base NONE");
    for (var b = 0; b < instance_number(obj_base_start); b++) {
        var bs = instance_find(obj_base_start, b);
        array_push(L, "IN GAME: starter base at " + string(round(bs.x)) + ", " + string(round(bs.y)) + "   sprite " + string(bs.sprite_index));
    }
    if (instance_number(obj_extraction) == 0) array_push(L, "IN GAME: extraction NONE");
    for (var x2 = 0; x2 < instance_number(obj_extraction); x2++) {
        var xs = instance_find(obj_extraction, x2);
        array_push(L, "IN GAME: extraction at " + string(round(xs.x)) + ", " + string(round(xs.y)) + "   sprite " + string(xs.sprite_index) + "   on minimap " + string(xs.map_visible));
    }

    // what the server believes is lying on the ground
    if (instance_exists(obj_server)) {
        var n_wood = 0;
        var n_stone = 0;
        var n_totem = 0;
        var n_all = 0;
        var wk = ds_map_find_first(obj_server.world_items);
        while (!is_undefined(wk)) {
            var wi = obj_server.world_items[? wk];
            n_all++;
            if (wi.item == "wood") n_wood++;
            if (wi.item == "stone") n_stone++;
            if (string_copy(wi.item, 1, 5) == "totem") {
                n_totem++;
                array_push(L, "SERVER: " + wi.item + " at " + string(round(wi.x)) + ", " + string(round(wi.y)));
            }
            wk = ds_map_find_next(obj_server.world_items, wk);
        }
        array_push(L, "SERVER items: wood " + string(n_wood) + "  stone " + string(n_stone) + "  totem " + string(n_totem) + "  all " + string(n_all));
    }

    // the pickups in this game
    var shown_totem = 0;
    for (var p = 0; p < instance_number(obj_pickup); p++) {
        var pk = instance_find(obj_pickup, p);
        if (string_copy(pk.item_id, 1, 5) == "totem") shown_totem++;
        array_push(L, "IN GAME: " + pk.item_id + " at " + string(round(pk.x)) + ", " + string(round(pk.y)));
    }
    if (shown_totem == 0) array_push(L, "IN GAME: totem pieces NONE");

            // draw it in the bottom-right corner, growing upward
    draw_set_halign(fa_right);
    var line_h = 15;
    var dbg_x = display_get_gui_width() - 20;
    var dbg_y = display_get_gui_height() - array_length(L) * line_h - 10;
    for (var row = 0; row < array_length(L); row++) {
        draw_set_color(c_black);
        draw_text_transformed(dbg_x + 1, dbg_y + row * line_h + 1, L[row], 0.7, 0.7, 0);
        draw_set_color(c_yellow);
        draw_text_transformed(dbg_x, dbg_y + row * line_h, L[row], 0.7, 0.7, 0);
    }
    draw_set_halign(fa_left);
    draw_set_color(c_white);
}