// scr_bases: the starter base and the extraction zone
#macro EXTRACT_RADIUS 192     // how far from the zone's center counts as "inside", in pixels

function bases_init() {
    global.base_gui_open = false;
    global.base_mask = 0;     // bits 0, 1, 2 = totem piece 1, 2, 3 placed. bit 3 = the totem is restored
}

// how many of an item the player is carrying
function inv_count(_item) {
    var n = 0;
    for (var i = 0; i < array_length(global.inv_slots); i++) {
        var s = global.inv_slots[i];
        if (is_struct(s) && s.item == _item) n += s.count;
    }
    return n;
}

// takes items out of the inventory
function inv_take(_item, _amount) {
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

function base_close_gui() {
    global.base_gui_open = false;
    if (instance_exists(obj_player)) obj_player.can_move = true;
}

// asks the server to place a totem piece (the server answers with message 25 and 26)
function base_request_deposit(_slot) {
    var b = buffer_create(4, buffer_grow, 1);
    buffer_write(b, buffer_u8, 24);
    buffer_write(b, buffer_u8, _slot);
    net_send_to_server(b);
    buffer_delete(b);
}

function base_request_restore() {
    var b = buffer_create(4, buffer_grow, 1);
    buffer_write(b, buffer_u8, 27);
    net_send_to_server(b);
    buffer_delete(b);
}

// ---- where the structures go ----
// the list of structures for a seed. the server and every game run this and get the same result
// the list of structures for a seed. the server and every game run this and get the same result
function structures_generate(_seed) {
    // computed once per seed
    if (variable_global_exists("struct_cache_seed") && global.struct_cache_seed == _seed) return global.struct_cache;

    random_set_seed(_seed + 4242);
    var list = [];

    // the starter base: a few tiles north of the spawn point, so everyone sees it on arrival
    array_push(list, { type: "base_start", x: (GW div 2) * CELL + CELL / 2, y: (GH div 2 - 3) * CELL, r: 3 });

    // which water is the sea (connected to the map edge) and which is a pond
    var total = GW * GH;
    var land01 = array_create(total, 0);
    for (var i = 0; i < total; i++) {
        if (global.world_grid[i] >= T_SAND) land01[i] = 1;
    }
    var sea = grid_ocean(land01);

    // the extraction zone: on SAND, on the coast, out toward the edge of the island
    var ex = -1;
    var ey = -1;
    for (var tries = 0; tries < 20000 && ex < 0; tries++) {
        var relaxed = (tries >= 10000);      // rules loosen if nothing fit in the first half
        var gx = irandom_range(8, GW - 9);
        var gy = irandom_range(8, GH - 9);

        if (global.world_grid[gy * GW + gx] != T_SAND) continue;                 // sand only

        var d = point_distance(gx, gy, GW / 2, GH / 2) / (GW / 2);              // 0 = center, 1 = map edge
        if (d < (relaxed ? 0.35 : 0.55)) continue;                               // toward the outskirts

        // the sea has to be close (ponds don't count)...
        var sea_r = relaxed ? 7 : 5;
        var near_sea = false;
        for (var oy = -sea_r; oy <= sea_r && !near_sea; oy++) {
            for (var ox = -sea_r; ox <= sea_r && !near_sea; ox++) {
                if (sea[(gy + oy) * GW + gx + ox] == 1) near_sea = true;
            }
        }
        if (!near_sea) continue;

        // ...but the middle of the zone should be dry land
        var dry_r = relaxed ? 1 : 2;
        var dry = true;
        for (var oy2 = -dry_r; oy2 <= dry_r && dry; oy2++) {
            for (var ox2 = -dry_r; ox2 <= dry_r && dry; ox2++) {
                if (!world_land_at_cell(gx + ox2, gy + oy2)) dry = false;
            }
        }
        if (!dry) continue;

        ex = gx;
        ey = gy;
    }

    // last resort: the sand tile farthest from the center
    if (ex < 0) {
        var best = -1;
        for (var c = 0; c < total; c++) {
            if (global.world_grid[c] != T_SAND) continue;
            var cx = c mod GW;
            var cy = c div GW;
            var cd = point_distance(cx, cy, GW / 2, GH / 2);
            if (cd > best) {
                best = cd;
                ex = cx;
                ey = cy;
            }
        }
        if (ex < 0) {                      // no sand at all, which shouldn't happen
            ex = GW div 2;
            ey = GH div 2;
        }
    }
    array_push(list, { type: "extraction", x: ex * CELL + CELL / 2, y: ey * CELL + CELL / 2, r: 4 });

    global.struct_cache_seed = _seed;
    global.struct_cache = list;
    randomize();
    return list;
}

// every game builds the same structures from the world seed
function structures_spawn() {
    var list = structures_generate(global.world_seed);
    for (var i = 0; i < array_length(list); i++) {
        var s = list[i];
        if (s.type == "base_start") instance_create_layer(s.x, s.y, "Instances", obj_base_start);
        if (s.type == "extraction") instance_create_layer(s.x, s.y, "Instances", obj_extraction);
    }
}

// ---- server side ----
function server_register_structures() {
    var list = structures_generate(global.world_seed);
    with (obj_server) {
        base_mask = 0;
        game_won = false;
        for (var i = 0; i < array_length(list); i++) {
            var s = list[i];
            if (s.type == "base_start") { base_x = s.x; base_y = s.y; }
            if (s.type == "extraction") { extract_x = s.x; extract_y = s.y; }
        }
    }
}

// tells everyone (or one client) what is placed in the base
function server_send_base_state(_socket = -1) {
    var b = buffer_create(4, buffer_grow, 1);
    buffer_write(b, buffer_u8, 26);
    buffer_write(b, buffer_u8, obj_server.base_mask);
    if (_socket == -1) server_broadcast(b);
    else network_send_packet(_socket, b, buffer_tell(b));
    buffer_delete(b);
}