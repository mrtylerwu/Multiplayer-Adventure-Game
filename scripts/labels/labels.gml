// the name for another player, looked up from the lobby list the server sent us
function player_name_for(_pid) {
    if (instance_exists(obj_client)) {
        var l = obj_client.lobby;
        for (var i = 0; i < array_length(l); i++) {
            if (l[i].id == _pid) return l[i].name;
        }
    }
    return "Player";
}

// your own name (a fallback if you start rm_game directly without the lobby)
function my_player_name() {
    if (variable_global_exists("player_name") && global.player_name != "") return global.player_name;
    return "You";
}