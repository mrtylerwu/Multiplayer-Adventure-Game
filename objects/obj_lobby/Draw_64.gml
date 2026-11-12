// Draw GUI
draw_set_color(c_white);
draw_text(20, 20, "LOBBY");
draw_text(20, 50, "F1 = host   F2 = join   Enter = start (host only)   Tab = switch box");

if (!instance_exists(obj_client)) {
    var blink = ((current_time div 500) mod 2 == 0) ? "|" : "";

    draw_set_color(field == 0 ? c_yellow : c_white);
    draw_text(20, 90, "Your name");
    draw_rectangle(20, 112, 320, 142, true);
    draw_text(28, 119, name_text + (field == 0 ? blink : ""));

    draw_set_color(field == 1 ? c_yellow : c_white);
    draw_text(20, 160, "Host IP to join");
    draw_rectangle(20, 182, 320, 212, true);
    draw_text(28, 189, ip_text + (field == 1 ? blink : ""));

    draw_set_color(c_white);
} else {
    var st = obj_client.connected;
    var txt = "connecting...";
    if (st == 1) txt = "connected";
    if (st == 0) txt = "connection failed";
    draw_text(20, 90, "Status: " + txt);
    draw_text(20, 120, "Players:");
    for (var i = 0; i < array_length(obj_client.lobby); i++) {
        draw_text(40, 150 + i * 24, obj_client.lobby[i].name);
    }
}