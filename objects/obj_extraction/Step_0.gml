// discovered when you, or any teammate you can see, get close
if (!map_visible) {
    var found = false;
    if (instance_exists(obj_player) && point_distance(x, y, obj_player.x, obj_player.y) <= reveal_range) found = true;
    for (var i = 0; i < instance_number(obj_remote_player); i++) {
        var rp = instance_find(obj_remote_player, i);
        if (point_distance(x, y, rp.x, rp.y) <= reveal_range) found = true;
    }
    if (found) map_visible = true;
}