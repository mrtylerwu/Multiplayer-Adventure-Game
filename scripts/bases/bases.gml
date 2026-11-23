// scr_bases: the starter base and the extraction zone
#macro EXTRACT_RADIUS 192 //384     // how far from the zone's center counts as "inside", in pixels

#macro ASM_SLOT 60            // size of each assembly slot, in pixels
#macro ASM_GAP 22             // space between assembly slots
#macro ASM_BTN_W 170
#macro ASM_BTN_H 40


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

// ---- the base screen ----
// closes the assembly panel and the inventory together
function base_close_gui() {
    global.base_gui_open = false;
    global.inv_open = false;
    if (instance_exists(obj_player)) obj_player.can_move = true;
}


// where things sit inside the assembly panel
function asm_slot_x(_i) { return global.asm_x + (global.asm_w - (4 * ASM_SLOT + 3 * ASM_GAP)) / 2 + _i * (ASM_SLOT + ASM_GAP); }
function asm_slot_y() { return global.asm_y + 72; }
function asm_btn_x() { return global.asm_x + (global.asm_w - ASM_BTN_W) / 2; }
function asm_btn_y() { return global.asm_y + global.asm_h - ASM_BTN_H - 22; }

// which input slot (0 to 2) is under the mouse, or -1
function base_slot_at(_mx, _my) {
    for (var i = 0; i < 3; i++) {
        var sx = asm_slot_x(i);
        var sy = asm_slot_y();
        if (point_in_rectangle(_mx, _my, sx, sy, sx + ASM_SLOT, sy + ASM_SLOT)) return i;
    }
    return -1;
}

// tries to put a carried item into an assembly slot. returns true if one piece was placed
function base_deposit(_slot, _item) {
    var piece = 0;
    if (_item == "totem1") piece = 1;
    if (_item == "totem2") piece = 2;
    if (_item == "totem3") piece = 3;

    if (global.base_restored) { base_say("The totem is already assembled."); return false; }
    if (piece == 0) { base_say("Only totem pieces fit here."); return false; }
    if (global.base_slots[_slot] != 0) { base_say("That slot is taken."); return false; }
    for (var i = 0; i < 3; i++) {
        if (global.base_slots[i] == piece) { base_say("That piece is already in the base."); return false; }
    }

    global.base_slots[_slot] = piece;       // shown right away, the server confirms (or sends the piece back)
    var b = buffer_create(4, buffer_grow, 1);
    buffer_write(b, buffer_u8, 24);
    buffer_write(b, buffer_u8, _slot);
    buffer_write(b, buffer_u8, piece);
    net_send_to_server(b);
    buffer_delete(b);
    return true;
}

// asks the server to assemble the totem
function base_request_restore() {
    var b = buffer_create(4, buffer_grow, 1);
    buffer_write(b, buffer_u8, 27);
    net_send_to_server(b);
    buffer_delete(b);
}

// the Assemble button
function base_assemble_click() {
    if (global.base_restored) { base_say("The totem is already assembled."); return; }

    var have = [false, false, false, false];
    for (var i = 0; i < 3; i++) {
        var p = global.base_slots[i];
        if (p >= 1 && p <= 3) have[p] = true;
    }

    var missing = [];
    for (var k = 1; k <= 3; k++) {
        if (!have[k]) array_push(missing, "Piece " + string(k));
    }

    if (array_length(missing) > 0) {
        var txt = "Missing: ";
        for (var m = 0; m < array_length(missing); m++) {
            txt += missing[m];
            if (m < array_length(missing) - 1) txt += ", ";
        }
        base_say(txt);
    } else {
        base_request_restore();
    }
}

// ---- where the structures go ----
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


#macro BASE_MSG_FRAMES 70    // how long popup messages stay up, in frames (60 frames = 1 second)

function bases_init() {
    global.base_gui_open = false;
    global.base_slots = [0, 0, 0];     // the three assembly slots: 0 = empty, 1/2/3 = that totem piece
    global.base_restored = false;      // true once the totem has been assembled (stays true)
    global.base_output = false;        // true while the finished totem sits in the fourth slot
    global.base_msg = "";
    global.base_msg_timer = 0;
    global.asm_x = 0;
    global.asm_y = 0;
    global.asm_w = 350;
    global.asm_h = 240;
    global.asm_gap = 20;
}

// a short popup message on the assembly panel
function base_say(_text) {
    global.base_msg = _text;
    global.base_msg_timer = BASE_MSG_FRAMES;
}

// press the finished totem to pick it up onto your cursor
function base_take_totem() {
    if (!global.base_output) return;
    if (instance_exists(obj_inventory) && obj_inventory.drag_from != -1) {
        base_say("Your hands are full.");
        return;
    }
    var b = buffer_create(4, buffer_grow, 1);
    buffer_write(b, buffer_u8, 28);
    net_send_to_server(b);
    buffer_delete(b);
}

// ---- server side ----
function server_register_structures() {
    var list = structures_generate(global.world_seed);
    with (obj_server) {
        base_slots = [0, 0, 0];
        base_restored = false;
        base_output = false;
        game_won = false;
        for (var i = 0; i < array_length(list); i++) {
            var s = list[i];
            if (s.type == "base_start") { base_x = s.x; base_y = s.y; }
            if (s.type == "extraction") { extract_x = s.x; extract_y = s.y; }
        }
    }
}

// tells everyone (or one client) what is in the base
function server_send_base_state(_socket = -1) {
    var b = buffer_create(8, buffer_grow, 1);
    buffer_write(b, buffer_u8, 26);
    for (var i = 0; i < 3; i++) buffer_write(b, buffer_u8, obj_server.base_slots[i]);
    buffer_write(b, buffer_u8, obj_server.base_restored ? 1 : 0);
    buffer_write(b, buffer_u8, obj_server.base_output ? 1 : 0);
    if (_socket == -1) server_broadcast(b);
    else network_send_packet(_socket, b, buffer_tell(b));
    buffer_delete(b);
}