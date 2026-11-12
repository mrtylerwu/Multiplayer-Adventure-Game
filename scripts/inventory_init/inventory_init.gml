function inventory_init() {
    // every item type in the game is defined here
    global.item_db = {
        wood: { name: "Wood", sprite: spr_wood, obj: obj_wood, max_stack: 20 },
		stone: { name: "Stone", sprite: spr_stone, obj: obj_stone, max_stack: 20 },
		medkit: { name: "Medkit", sprite: spr_medkit, obj: obj_medkit, max_stack: 1 }
    };
    global.inv_cols = 6;
    global.inv_rows = 4;
    global.inv_slots = array_create(global.inv_cols * global.inv_rows, -1);  // -1 = empty
    global.inv_open = false;
}

// returns how many items did NOT fit (0 = everything was added)
function inventory_add(_item, _amount) {
    var max_stack = global.item_db[$ _item].max_stack;
    var n = array_length(global.inv_slots);

    // 1) top up stacks you already have
    for (var i = 0; i < n && _amount > 0; i++) {
        var s = global.inv_slots[i];
        if (is_struct(s) && s.item == _item && s.count < max_stack) {
            var take = min(_amount, max_stack - s.count);
            s.count += take;
            _amount -= take;
        }
    }
    // 2) then fill empty slots
    for (var j = 0; j < n && _amount > 0; j++) {
        if (!is_struct(global.inv_slots[j])) {
            var put = min(_amount, max_stack);
            global.inv_slots[j] = { item: _item, count: put };
            _amount -= put;
        }
    }
    return _amount;
}

// draws an item's sprite shrunk to fit a square, centered on (_cx, _cy)
function draw_item_icon(_item, _cx, _cy, _size, _alpha) {
    var spr = global.item_db[$ _item].sprite;
    var sw = sprite_get_width(spr);
    var sh = sprite_get_height(spr);
    var sc = _size / max(sw, sh);
    var dx = _cx - (sw / 2 - sprite_get_xoffset(spr)) * sc;
    var dy = _cy - (sh / 2 - sprite_get_yoffset(spr)) * sc;
    draw_sprite_ext(spr, 0, dx, dy, sc, sc, 0, c_white, _alpha);
}

// new function in the same script
/*function drop_item(_item, _amount) {
    if (!instance_exists(obj_player)) return;
    var ang = random(360);
    var inst = instance_create_layer(
        obj_player.x + lengthdir_x(40, ang),
        obj_player.y + lengthdir_y(40, ang),
        "Instances",
        global.item_db[$ _item].obj
    );
    inst.amount = _amount;   // a dropped stack lands as one pile holding the whole amount
}*/

function net_send_to_server(_buf) {
    if (instance_exists(obj_client)) network_send_packet(obj_client.socket, _buf, buffer_tell(_buf));
}

// drop request: the item appears when the server answers
function drop_item(_item, _amount) {
    if (!instance_exists(obj_player)) return;
    var ang = random(360);
    var b = buffer_create(32, buffer_grow, 1);
    buffer_write(b, buffer_u8, 15);
    buffer_write(b, buffer_string, _item);
    buffer_write(b, buffer_u16, _amount);
    buffer_write(b, buffer_f32, obj_player.x + lengthdir_x(40, ang));
    buffer_write(b, buffer_f32, obj_player.y + lengthdir_y(40, ang));
    net_send_to_server(b);
    buffer_delete(b);
}

function server_write_spawn(_b, _nid, _w) {
    buffer_write(_b, buffer_u8, 11);
    buffer_write(_b, buffer_u32, _nid);
    buffer_write(_b, buffer_string, _w.item);
    buffer_write(_b, buffer_u16, _w.amount);
    buffer_write(_b, buffer_f32, _w.x);
    buffer_write(_b, buffer_f32, _w.y);
}

// register an item on the server; _broadcast = tell connected clients right away
function server_spawn_item(_item, _amount, _x, _y, _broadcast) {
    with (obj_server) {
        var nid = next_item_id;
        next_item_id++;
        var w = { item: _item, amount: _amount, x: _x, y: _y };
        world_items[? nid] = w;

        if (_broadcast) {
            var b = buffer_create(32, buffer_grow, 1);
            server_write_spawn(b, nid, w);
            for (var i = 0; i < ds_list_size(clients); i++) {
                network_send_packet(clients[| i], b, buffer_tell(b));
            }
            buffer_delete(b);
        }
    }
}

// the starting items on the ground, created by the server only
function server_init_world() {
    with (obj_server) {
        ds_map_clear(world_items);
        next_item_id = 1;
    }

    // wood only on grass
    repeat (10) {
        var p = world_random_land_point(1, T_GRASS);
        server_spawn_item("wood", irandom_range(1, 3), p.x, p.y, false);
    }

    // stone anywhere on land (sand or grass)
    repeat (10) {
        var p2 = world_random_land_point(1);
        server_spawn_item("stone", irandom_range(1, 3), p2.x, p2.y, false);
    }
}



function tools_init() {
    global.tool_list = [
        { name: "Sword",       tip_angle: 45, sprite: spr_sword,       swing_arc: 40, swing_time: 40, reach: 60, power: { player: 5, tree: 2, rock: 2 } },
        { name: "Axe",         tip_angle: 45, sprite: spr_axe,         swing_arc: 40, swing_time: 40, reach: 60, power: { player: 3, tree: 5, rock: 2 } },
        { name: "Pickaxe",     tip_angle: 45, sprite: spr_pickaxe,     swing_arc: 40, swing_time: 40, reach: 60, power: { player: 3, tree: 2, rock: 5 } },
        { name: "Fishing Rod", tip_angle: 45, sprite: spr_fishing_rod, swing_arc: 20, swing_time: 20, reach: 60, power: { player: 1 } }
    ];
    global.tool_selected = -1;
    global.click_used = false;
}

// how hard a tool hits a kind of target ("player", "tree", "rock", ...). 0 = does nothing
function tool_power(_tool, _target) {
    if (_tool < 0 || _tool >= array_length(global.tool_list)) return 0;
    var p = global.tool_list[_tool].power;
    return variable_struct_exists(p, _target) ? p[$ _target] : 0;
}

function resources_init() {
    if (variable_global_exists("resource_db")) exit;
    global.resource_db = {
        tree: { obj: obj_tree, hp: 35, drop_item: "wood",  drop_min: 2, drop_max: 4 },
        rock: { obj: obj_rock, hp: 35, drop_item: "stone", drop_min: 2, drop_max: 5 }
    };
}

// tells one client about every tree/rock that is already damaged or cut down
function server_send_resource_state(_socket) {
    with (obj_server) {
        var b = buffer_create(1024, buffer_grow, 1);

        var k = ds_map_find_first(resources);
        while (!is_undefined(k)) {
            var r = resources[? k];
            if (r.hp < global.resource_db[$ r.type].hp) {
                buffer_write(b, buffer_u8, 20);
                buffer_write(b, buffer_u32, k);
                buffer_write(b, buffer_f32, r.hp);
                if (buffer_tell(b) > 700) {
                    network_send_packet(_socket, b, buffer_tell(b));
                    buffer_seek(b, buffer_seek_start, 0);
                }
            }
            k = ds_map_find_next(resources, k);
        }
        for (var i = 0; i < ds_list_size(res_gone); i++) {
            buffer_write(b, buffer_u8, 21);
            buffer_write(b, buffer_u32, res_gone[| i]);
            if (buffer_tell(b) > 700) {
                network_send_packet(_socket, b, buffer_tell(b));
                buffer_seek(b, buffer_seek_start, 0);
            }
        }
        if (buffer_tell(b) > 0) network_send_packet(_socket, b, buffer_tell(b));
        buffer_delete(b);
    }
}

// draws a sprite shrunk to fit a square, centered on (_cx, _cy), optionally rotated
function draw_sprite_fit(_spr, _cx, _cy, _size, _alpha, _angle = 0) {
    var sw = sprite_get_width(_spr);
    var sh = sprite_get_height(_spr);
    var sc = _size / max(sw, sh);
    var vx = (sw / 2 - sprite_get_xoffset(_spr)) * sc;
    var vy = (sh / 2 - sprite_get_yoffset(_spr)) * sc;
    var rx = vx * dcos(_angle) + vy * dsin(_angle);
    var ry = -vx * dsin(_angle) + vy * dcos(_angle);
    draw_sprite_ext(_spr, 0, _cx - rx, _cy - ry, sc, sc, _angle, c_white, _alpha);
}