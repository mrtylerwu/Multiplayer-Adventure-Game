// obj_world, Room Start
// solo testing: if we got here without the lobby, generate a world now
if (!variable_global_exists("world_grid")) {
    global.world_seed = irandom(999999);
    world_generate(global.world_seed);
}

world_build_tiles();

if (variable_global_exists("minimap")) sprite_delete(global.minimap);
global.minimap = minimap_build();

if (instance_exists(obj_player)) {
    var p = world_spawn_point();
    obj_player.x = p.x;
    obj_player.y = p.y;
}