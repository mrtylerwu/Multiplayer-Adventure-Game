#macro CELL 64 //32      // tile size in pixels (keep your value)
#macro GW 256       // grid width in cells (keep your value)
#macro GH 256       // grid height in cells (keep your value)

#macro T_WATER 0
#macro T_SAND  1
#macro T_GRASS 2

// ================= noise =================
function noise_lattice(_scale) {
    var lw = ceil(GW / _scale) + 2;
    var lh = ceil(GH / _scale) + 2;
    var a = array_create(lw * lh);
    for (var i = 0; i < lw * lh; i++) a[i] = random(1);
    return { a: a, w: lw, scale: _scale };
}

function noise_sample(_n, _x, _y) {
    var fx = _x / _n.scale;
    var fy = _y / _n.scale;
    var x0 = floor(fx);
    var y0 = floor(fy);
    var tx = fx - x0;
    var ty = fy - y0;
    tx = tx * tx * (3 - 2 * tx);
    ty = ty * ty * (3 - 2 * ty);
    var w = _n.w;
    var v00 = _n.a[y0 * w + x0];
    var v10 = _n.a[y0 * w + x0 + 1];
    var v01 = _n.a[(y0 + 1) * w + x0];
    var v11 = _n.a[(y0 + 1) * w + x0 + 1];
    return lerp(lerp(v00, v10, tx), lerp(v01, v11, tx), ty);
}

function noise_fbm(_layers, _x, _y) {
    var total = 0;
    var amp = 1;
    var norm = 0;
    for (var i = 0; i < array_length(_layers); i++) {
        total += noise_sample(_layers[i], _x, _y) * amp;
        norm += amp;
        amp *= 0.5;
    }
    return total / norm;
}

// the value such that _keep_fraction of the values are >= it
function percentile_threshold(_values, _keep_fraction) {
    var sorted = array_create(array_length(_values));
    array_copy(sorted, 0, _values, 0, array_length(_values));
    array_sort(sorted, true);
    var idx = clamp(floor(array_length(sorted) * (1 - _keep_fraction)), 0, array_length(sorted) - 1);
    return sorted[idx];
}

// ================= grid tools (these work on 0/1 grids) =================
function grid_clear_border(_g, _n) {
    for (var gy = 0; gy < GH; gy++) {
        for (var gx = 0; gx < GW; gx++) {
            if (gx < _n || gy < _n || gx >= GW - _n || gy >= GH - _n) _g[gy * GW + gx] = 0;
        }
    }
    return _g;
}

// shrink land by one cell on every side
function grid_erode(_g) {
    var out = array_create(GW * GH, 0);
    for (var gy = 1; gy < GH - 1; gy++) {
        for (var gx = 1; gx < GW - 1; gx++) {
            var i = gy * GW + gx;
            if (_g[i] == 1 && _g[i - 1] == 1 && _g[i + 1] == 1 && _g[i - GW] == 1 && _g[i + GW] == 1) out[i] = 1;
        }
    }
    return out;
}

// round off corners, remove 1-cell spikes and puddles
function grid_smooth(_g) {
    var out = array_create(GW * GH, 0);
    for (var gy = 1; gy < GH - 1; gy++) {
        for (var gx = 1; gx < GW - 1; gx++) {
            var n = 0;
            for (var oy = -1; oy <= 1; oy++) {
                for (var ox = -1; ox <= 1; ox++) {
                    if (ox != 0 || oy != 0) n += _g[(gy + oy) * GW + gx + ox];
                }
            }
            var i = gy * GW + gx;
            if (n > 4) out[i] = 1;
            else if (n < 4) out[i] = 0;
            else out[i] = _g[i];
        }
    }
    return out;
}

// keep the biggest connected piece of land, everything else becomes water
function grid_keep_largest(_g) {
    var total = GW * GH;
    var comp = array_create(total, -1);
    var queue = array_create(total, 0);
    var best_size = 0;
    var best_id = -1;
    var comp_id = 0;

    for (var s = 0; s < total; s++) {
        if (_g[s] != 1 || comp[s] != -1) continue;
        var head = 0;
        var tail = 0;
        var size = 0;
        queue[tail] = s;
        tail++;
        comp[s] = comp_id;
        while (head < tail) {
            var c = queue[head];
            head++;
            size++;
            var nb = [c - 1, c + 1, c - GW, c + GW];   // safe: the border is always water
            for (var k = 0; k < 4; k++) {
                var q = nb[k];
                if (_g[q] == 1 && comp[q] == -1) {
                    comp[q] = comp_id;
                    queue[tail] = q;
                    tail++;
                }
            }
        }
        if (size > best_size) {
            best_size = size;
            best_id = comp_id;
        }
        comp_id++;
    }
    var out = array_create(total, 0);
    for (var i = 0; i < total; i++) {
        if (comp[i] == best_id) out[i] = 1;
    }
    return out;
}

// marks the sea: every water cell connected to the map border (1 = sea). Ponds are the water left over
function grid_ocean(_g) {
    var total = GW * GH;
    var ocean = array_create(total, 0);
    var queue = array_create(total, 0);
    var head = 0;
    var tail = 0;
    queue[tail] = 0;       // cell 0 is a border cell, so it is sea
    tail++;
    ocean[0] = 1;
    while (head < tail) {
        var c = queue[head];
        head++;
        var cx = c mod GW;
        var cy = c div GW;
        var nb = [];
        if (cx > 0) array_push(nb, c - 1);
        if (cx < GW - 1) array_push(nb, c + 1);
        if (cy > 0) array_push(nb, c - GW);
        if (cy < GH - 1) array_push(nb, c + GW);
        for (var k = 0; k < array_length(nb); k++) {
            var q = nb[k];
            if (_g[q] == 0 && ocean[q] == 0) {
                ocean[q] = 1;
                queue[tail] = q;
                tail++;
            }
        }
    }
    return ocean;
}

// distance (in cells) from every cell to the nearest cell marked 1 in _src
function grid_distance(_src) {
    var total = GW * GH;
    var d = array_create(total, 9999);
    for (var i = 0; i < total; i++) {
        if (_src[i] == 1) d[i] = 0;
    }
    // pass 1: top-left to bottom-right
    for (var gy = 0; gy < GH; gy++) {
        for (var gx = 0; gx < GW; gx++) {
            var a = gy * GW + gx;
            var v = d[a];
            if (gx > 0) v = min(v, d[a - 1] + 1);
            if (gy > 0) {
                v = min(v, d[a - GW] + 1);
                if (gx > 0) v = min(v, d[a - GW - 1] + 1.414);
                if (gx < GW - 1) v = min(v, d[a - GW + 1] + 1.414);
            }
            d[a] = v;
        }
    }
    // pass 2: bottom-right to top-left
    for (var hy = GH - 1; hy >= 0; hy--) {
        for (var hx = GW - 1; hx >= 0; hx--) {
            var b = hy * GW + hx;
            var w = d[b];
            if (hx < GW - 1) w = min(w, d[b + 1] + 1);
            if (hy < GH - 1) {
                w = min(w, d[b + GW] + 1);
                if (hx < GW - 1) w = min(w, d[b + GW + 1] + 1.414);
                if (hx > 0) w = min(w, d[b + GW - 1] + 1.414);
            }
            d[b] = w;
        }
    }
    return d;
}

// ================= the generator =================
function world_generate(_seed) {
    var total = GW * GH;

    for (var attempt = 0; attempt < 20; attempt++) {
        random_set_seed(_seed + attempt * 7919);

        // this seed's "personality": same seed = same island on every computer
        var ms = GW / 128;   // 1 on a 128-cell map, 2 on 256, 3 on 384
		var island_layers = [noise_lattice(32 * ms), noise_lattice(16 * ms), noise_lattice(8 * ms)];
		var pond_layers   = [noise_lattice(14 * ms), noise_lattice(7 * ms)];
		var width_layers  = [noise_lattice(20 * ms), noise_lattice(10 * ms)];
        var pond_frac = random_range(0.04, 0.12);   // ponds cover this much of the inland area
        var angle     = random_range(-12, 12);      // slight tilt only, a fully random angle would turn a square into a diamond
		var stretch   = random_range(0.85, 1.0);    // 1 = square, lower = rectangle
		var sq_p      = random_range(5, 8);         // 2 = circle, 4 = rounded square, 8 = nearly square
		var wobble    = random_range(0.5, 0.9);     // higher = more ragged coastline

        // 1) island shape: stretched falloff + noise, keep the top 40% of cells as land
        var island_score = array_create(total, 0);
        for (var gy = 0; gy < GH; gy++) {
            for (var gx = 0; gx < GW; gx++) {
                var dx = gx - GW / 2;
                var dy = gy - GH / 2;
                var rx = dx * dcos(angle) + dy * dsin(angle);
                var ry = -dx * dsin(angle) + dy * dcos(angle);
                var half = min(GW, GH) * 0.5;
				var dist = power(power(abs(rx) / half, sq_p) + power(abs(ry / stretch) / half, sq_p), 1 / sq_p);
				var sc = (1 - dist) + (noise_fbm(island_layers, gx, gy) - 0.5) * wobble;
				if (dist > 0.90) sc = -10;   // no land in the outer ring, so it can never reach the edge
				island_score[gy * GW + gx] = sc;
            }
        }
        var thr = percentile_threshold(island_score, 0.60);
        var g = array_create(total, 0);
        for (var i = 0; i < total; i++) {
            if (island_score[i] >= thr) g[i] = 1;
        }
        g = grid_clear_border(g, 2);
		
		// the middle of the map is always land (the spawn area)
		for (var cy0 = 0; cy0 < GH; cy0++) {
		    for (var cx0 = 0; cx0 < GW; cx0++) {
		        if (point_distance(cx0, cy0, GW / 2, GH / 2) <= 4) g[cy0 * GW + cx0] = 1;
		    }
		}

        // 2) ponds, only well inland (6 cells from the sea)
        var inland = g;
        repeat (3) inland = grid_erode(inland);
        var pond_noise = array_create(total, 0);
        var pond_values = [];
        for (var pcy = 0; pcy < GH; pcy++) {
            for (var pcx = 0; pcx < GW; pcx++) {
                var pidx = pcy * GW + pcx;
                if (inland[pidx] == 1) {
                    pond_noise[pidx] = noise_fbm(pond_layers, pcx, pcy);
                    array_push(pond_values, pond_noise[pidx]);
                }
            }
        }
        if (array_length(pond_values) > 0) {
            var pthr = percentile_threshold(pond_values, pond_frac);
            for (var pj = 0; pj < total; pj++) {
			    // no ponds within 14 cells of the center
			    var far_from_center = point_distance(pj mod GW, pj div GW, GW / 2, GH / 2) > 7;
			    if (inland[pj] == 1 && pond_noise[pj] >= pthr && far_from_center) g[pj] = 0;
			}
        }

        // 3) smooth, then keep only the one connected island
        repeat (2) g = grid_smooth(g);
        g = grid_keep_largest(g);

        // 4) sand and grass, based on distance from the sea and from ponds
        var ocean = grid_ocean(g);
        var pond_src = array_create(total, 0);
        for (var s = 0; s < total; s++) {
            if (g[s] == 0 && ocean[s] == 0) pond_src[s] = 1;
        }
        var d_ocean = grid_distance(ocean);
        var d_pond = grid_distance(pond_src);

        var terrain = array_create(total, T_WATER);
        for (var ty = 0; ty < GH; ty++) {
            for (var tx = 0; tx < GW; tx++) {
                var ti = ty * GW + tx;
                if (g[ti] == 0) continue;
                var wv = clamp((noise_fbm(width_layers, tx, ty) - 0.3) * 2.5, 0, 1);
                var coast_w = lerp(2, 4, wv);     // sand belt along the sea: 2 to 4 cells
                var pond_w  = lerp(1, 1.5, wv);   // thinner belt around ponds: 1 to 1.5 cells
                if (d_ocean[ti] <= coast_w || d_pond[ti] <= pond_w) terrain[ti] = T_SAND;
                else terrain[ti] = T_GRASS;
            }
        }

        // round off the grass outline
        var grass = array_create(total, 0);
        for (var a = 0; a < total; a++) {
            if (terrain[a] == T_GRASS) grass[a] = 1;
        }
        repeat (2) grass = grid_smooth(grass);
        for (var b = 0; b < total; b++) {
            if (g[b] == 1) terrain[b] = (grass[b] == 1) ? T_GRASS : T_SAND;
        }

        // grass never touches water directly: grass next to water becomes sand
        for (var uy = 1; uy < GH - 1; uy++) {
            for (var ux = 1; ux < GW - 1; ux++) {
                var ui = uy * GW + ux;
                if (terrain[ui] != T_GRASS) continue;
                for (var oy = -1; oy <= 1; oy++) {
                    for (var ox = -1; ox <= 1; ox++) {
                        if (terrain[ui + oy * GW + ox] == T_WATER) terrain[ui] = T_SAND;
                    }
                }
            }
        }

        // 5) sanity check: reject tiny islands and try the next variation
        var land = 0;
		var grass_count = 0;
		var sum_x = 0;
		var sum_y = 0;
		for (var c = 0; c < total; c++) {
		    if (terrain[c] >= T_SAND) {
		        land++;
		        sum_x += c mod GW;
		        sum_y += c div GW;
		    }
		    if (terrain[c] == T_GRASS) grass_count++;
		}
		global.world_grid = terrain;

		var center_ok = (terrain[(GH div 2) * GW + (GW div 2)] == T_GRASS);
		// how far the island's middle is from the map's middle, in cells
		var off = point_distance(sum_x / max(land, 1), sum_y / max(land, 1), GW / 2, GH / 2);
		var centered = (off < GW * 0.05);

		if (land >= total * 0.25 && grass_count >= total * 0.08 && center_ok && centered) break;
    }
    randomize();   // everything after this may be truly random again
}

// ================= queries (used by movement, spawning, items) =================
function world_terrain_at_cell(_gx, _gy) {
    if (_gx < 0 || _gy < 0 || _gx >= GW || _gy >= GH) return T_WATER;
    return global.world_grid[_gy * GW + _gx];
}

function world_land_at_cell(_gx, _gy) {
    return world_terrain_at_cell(_gx, _gy) >= T_SAND;   // sand and grass are both walkable
}

function world_land_at_px(_px, _py) {
    return world_land_at_cell(floor(_px / CELL), floor(_py / CELL));
}

// true if a box (a hitbox) is completely on land
function world_can_walk(_l, _t, _r, _b) {
    return world_land_at_px(_l, _t) && world_land_at_px(_r, _t) && world_land_at_px(_l, _b) && world_land_at_px(_r, _b);
}

// random point at least _margin cells from water. _min_terrain: 1 = sand or grass, 2 = grass only
function world_random_land_point(_margin, _min_terrain = T_SAND) {
    for (var tries = 0; tries < 1000; tries++) {
        var gx = irandom_range(2, GW - 3);
        var gy = irandom_range(2, GH - 3);
        var ok = true;
        for (var oy = -_margin; oy <= _margin && ok; oy++) {
            for (var ox = -_margin; ox <= _margin && ok; ox++) {
                if (world_terrain_at_cell(gx + ox, gy + oy) < _min_terrain) ok = false;
            }
        }
        if (ok) return { x: gx * CELL + CELL / 2, y: gy * CELL + CELL / 2 };
    }
    return { x: GW * CELL / 2, y: GH * CELL / 2 };
}

// ================= drawing the world =================
// which of the 4 neighbours are at least _level? N=1 E=2 S=4 W=8
function world_edge_mask(_gx, _gy, _level) {
    var m = 0;
    if (world_terrain_at_cell(_gx, _gy - 1) >= _level) m += 1;
    if (world_terrain_at_cell(_gx + 1, _gy) >= _level) m += 2;
    if (world_terrain_at_cell(_gx, _gy + 1) >= _level) m += 4;
    if (world_terrain_at_cell(_gx - 1, _gy) >= _level) m += 8;
    return m;
}


// sends one message to every connected client
function server_broadcast(_b) {
    with (obj_server) {
        for (var i = 0; i < ds_list_size(clients); i++) {
            network_send_packet(clients[| i], _b, buffer_tell(_b));
        }
    }
}


function world_build_tiles() {
    // depths 90 and 80 are in front of the room's Background layer (100) and behind your instances (0)
    var sand_layer  = layer_create(90, "TerrainSand");
    var grass_layer = layer_create(80, "TerrainGrass");
    var sand_map  = layer_tilemap_create(sand_layer, 0, 0, ts_sand, GW, GH);
    var grass_map = layer_tilemap_create(grass_layer, 0, 0, ts_grass, GW, GH);
	

    for (var gy = 0; gy < GH; gy++) {
        for (var gx = 0; gx < GW; gx++) {
            var t = world_terrain_at_cell(gx, gy);
            if (t >= T_SAND)  tilemap_set(sand_map,  1 + world_edge_mask(gx, gy, T_SAND),  gx, gy);
            if (t == T_GRASS) tilemap_set(grass_map, 1 + world_edge_mask(gx, gy, T_GRASS), gx, gy);
        }
    }
}

/*
function world_build_tiles() {
    var g = global.world_grid;
    var sand_layer  = layer_create(90, "TerrainSand");
    var grass_layer = layer_create(80, "TerrainGrass");
    var sand_map  = layer_tilemap_create(sand_layer, 0, 0, ts_sand, GW, GH);
    var grass_map = layer_tilemap_create(grass_layer, 0, 0, ts_grass, GW, GH);

    // land never touches the outer 2 cells of the grid, so neighbours can be read without bounds checks
    for (var gy = 1; gy < GH - 1; gy++) {
        for (var gx = 1; gx < GW - 1; gx++) {
            var i = gy * GW + gx;
            var t = g[i];
            if (t == T_WATER) continue;

            var ms = 1;
            if (g[i - GW] >= T_SAND) ms += 1;
            if (g[i + 1]  >= T_SAND) ms += 2;
            if (g[i + GW] >= T_SAND) ms += 4;
            if (g[i - 1]  >= T_SAND) ms += 8;
            tilemap_set(sand_map, ms, gx, gy);

            if (t == T_GRASS) {
                var mg = 1;
                if (g[i - GW] == T_GRASS) mg += 1;
                if (g[i + 1]  == T_GRASS) mg += 2;
                if (g[i + GW] == T_GRASS) mg += 4;
                if (g[i - 1]  == T_GRASS) mg += 8;
                tilemap_set(grass_map, mg, gx, gy);
            }
        }
    }
}
*/


// a grass cell near the middle of the map. returns { x, y } in pixels
function world_spawn_point(_spread = 2) {
    var mx = GW div 2;
    var my = GH div 2;

    // random spot within _spread cells of the center, so teammates don't stack
    for (var tries = 0; tries < 200; tries++) {
        var gx = mx + irandom_range(-_spread, _spread);
        var gy = my + irandom_range(-_spread, _spread);
        if (world_terrain_at_cell(gx, gy) == T_GRASS) {
            return { x: gx * CELL + CELL / 2, y: gy * CELL + CELL / 2 };
        }
    }
    // fallback: search outward from the center for the nearest grass
    for (var r = 0; r < max(GW, GH) / 2; r++) {
        for (var oy = -r; oy <= r; oy++) {
            for (var ox = -r; ox <= r; ox++) {
                if ((abs(ox) == r || abs(oy) == r) && world_terrain_at_cell(mx + ox, my + oy) == T_GRASS) {
                    return { x: (mx + ox) * CELL + CELL / 2, y: (my + oy) * CELL + CELL / 2 };
                }
            }
        }
    }
    return { x: GW * CELL / 2, y: GH * CELL / 2 };
}

// a random point that is within _max_px of land, but may be in shallow water. returns { x, y }
function world_random_point_near_land(_max_px) {
    var reach = ceil(_max_px / CELL);
    for (var tries = 0; tries < 2000; tries++) {
        var gx = irandom_range(2, GW - 3);
        var gy = irandom_range(2, GH - 3);
        for (var oy = -reach; oy <= reach; oy++) {
            for (var ox = -reach; ox <= reach; ox++) {
                if (world_land_at_cell(gx + ox, gy + oy)) {
                    return { x: gx * CELL + irandom(CELL - 1), y: gy * CELL + irandom(CELL - 1) };
                }
            }
        }
    }
    return world_random_land_point(1);
}


#macro MM_STEP 2   // one minimap pixel per 2x2 cells, which keeps it fast

// draws the whole island once into a small picture. returns a sprite
function minimap_build() {
    var mw = GW div MM_STEP;
    var mh = GH div MM_STEP;
    var surf = surface_create(mw, mh);
    surface_set_target(surf);
    draw_clear_alpha(c_black, 0);
    for (var py = 0; py < mh; py++) {
        for (var px = 0; px < mw; px++) {
            var t = world_terrain_at_cell(px * MM_STEP, py * MM_STEP);
            var col = make_colour_rgb(64, 140, 200);                 // water
            if (t == T_SAND)  col = make_colour_rgb(228, 208, 140);
            if (t == T_GRASS) col = make_colour_rgb(94, 158, 70);
            draw_point_colour(px, py, col);
        }
    }
    surface_reset_target();
    var spr = sprite_create_from_surface(surf, 0, 0, mw, mh, false, false, 0, 0);
    surface_free(surf);
    return spr;
}