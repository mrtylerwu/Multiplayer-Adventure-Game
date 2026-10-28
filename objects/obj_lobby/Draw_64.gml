// Draw GUI
draw_text(20, 20, "LOBBY");
draw_text(20, 50, "F1 = host   F2 = join   Enter = start (host only)");

if (!instance_exists(obj_client)) {
    draw_text(20, 80, "Host IP to join: " + keyboard_string);
} else {
    var st = obj_client.connected;
    var txt = "connecting...";
    if (st == 1) txt = "connected";
    if (st == 0) txt = "connection failed";
    draw_text(20, 80, "Status: " + txt);
    draw_text(20, 110, "Players:");
    for (var i = 0; i < array_length(obj_client.lobby); i++) {
        draw_text(40, 140 + i * 24, obj_client.lobby[i].name);
    }
}