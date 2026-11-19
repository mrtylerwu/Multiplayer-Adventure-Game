// obj_world, Room Start
bases_init();

// solo testing: if we got here without the lobby, generate a world now
if (!variable_global_exists("world_grid")) {
    global.world_seed = irandom(999999);
    world_generate(global.world_seed);
}

world_build_tiles();

//if (variable_global_exists("minimap")) sprite_delete(global.minimap);
//global.minimap = minimap_build();

if (instance_exists(obj_player)) {
    var p = world_spawn_point();
    obj_player.x = p.x;
    obj_player.y = p.y;
}

// trees and rocks: every game builds the same ones from the world seed
resources_init();
var rlist = resources_generate(global.world_seed);
if (instance_exists(obj_client)) ds_map_clear(obj_client.resource_nodes);
for (var ri = 0; ri < array_length(rlist); ri++) {
    var rr = rlist[ri];
    var rdef = global.resource_db[$ rr.type];
    var rinst = instance_create_layer(rr.x, rr.y, "Instances", rdef.obj);
    rinst.net_id = rr.rid;
    rinst.hp = rdef.hp;
    if (instance_exists(obj_client)) obj_client.resource_nodes[? rr.rid] = rinst;
}

structures_spawn();