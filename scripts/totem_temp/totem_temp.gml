// scr_totem_temp: temporary win condition for the progress check-in
#macro TOTEM_ON true
#macro TOTEM_AUTOWIN false   // true = holding all three pieces wins instantly (the old test)

// adds the four totem items to the item list (called from inventory_init)
function totem_register_items() {
    if (!TOTEM_ON) return;
    global.totem_done = false;
    global.item_db.totem1 = { name: "Totem piece", sprite: spr_totem1, obj: obj_totem1, max_stack: 1 };
    global.item_db.totem2 = { name: "Totem piece", sprite: spr_totem2, obj: obj_totem2, max_stack: 1 };
    global.item_db.totem3 = { name: "Totem piece", sprite: spr_totem3, obj: obj_totem3, max_stack: 1 };
    global.item_db.totem  = { name: "Totem",       sprite: spr_totem,  obj: obj_totem,  max_stack: 1 };
}

// server only: places the three pieces near the center of the map, spread around it
function totem_spawn_pieces() {
    if (!TOTEM_ON) return;
    var base_angle = random(360);
    for (var i = 1; i <= 3; i++) {
        var placed = false;
        for (var tries = 0; tries < 300 && !placed; tries++) {
            var ang = base_angle + (i - 1) * 120 + random_range(-30, 30);
            var dist = random_range(5, 8);                      // distance from the center, in tiles
            var gx = round(GW / 2 + lengthdir_x(dist, ang));
            var gy = round(GH / 2 + lengthdir_y(dist, ang));

            var ok = true;
            if (abs(gx - GW / 2) <= 3 && gy < GH / 2 - 1) ok = false;   // keep clear of the starter base
            for (var oy = -1; oy <= 1 && ok; oy++) {
                for (var ox = -1; ox <= 1 && ok; ox++) {
                    if (world_terrain_at_cell(gx + ox, gy + oy) != T_GRASS) ok = false;
                }
            }
            if (ok) {
                server_spawn_item("totem" + string(i), 1, gx * CELL + CELL / 2, gy * CELL + CELL / 2, false);
                placed = true;
            }
        }
    }
}

// how many of an item the player is carrying
function totem_count(_item) {
    var n = 0;
    for (var i = 0; i < array_length(global.inv_slots); i++) {
        var s = global.inv_slots[i];
        if (is_struct(s) && s.item == _item) n += s.count;
    }
    return n;
}

// removes items from the inventory
function totem_take(_item, _amount) {
    for (var i = 0; i < array_length(global.inv_slots) && _amount > 0; i++) {
        var s = global.inv_slots[i];
        if (is_struct(s) && s.item == _item) {
            var n = min(_amount, s.count);
            s.count -= n;
            _amount -= n;
            if (s.count <= 0) global.inv_slots[i] = -1;
        }
    }
}

// called after every pickup: if you hold all three pieces, assemble the totem and win
// called every frame while playing: merges the three pieces, and wins once a complete totem is held
function totem_check_win() {
	if (!TOTEM_AUTOWIN) return;
    if (!TOTEM_ON || global.totem_done) return;
    if (!variable_global_exists("inv_slots")) return;

    // 1) holding all three pieces: they merge into the regular totem
    if (totem_count("totem1") >= 1 && totem_count("totem2") >= 1 && totem_count("totem3") >= 1) {
        totem_take("totem1", 1);
        totem_take("totem2", 1);
        totem_take("totem3", 1);
        inventory_add("totem", 1);
    }

    // 2) holding the complete totem: everyone wins
    if (totem_count("totem") >= 1) {
        global.totem_done = true;
        if (instance_exists(obj_client)) {
            var b = buffer_create(4, buffer_grow, 1);
            buffer_write(b, buffer_u8, 22);       // tell the server, which tells everyone else
            net_send_to_server(b);
            buffer_delete(b);
        }
        room_goto(rm_win);                          // you go right away, even if the relay below is broken
    }
}