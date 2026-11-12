if (room == rm_game) {
    ds_map_clear(world_pickups);     // the old room's objects are gone
    ds_map_clear(remote_players);
    var b = buffer_create(4, buffer_grow, 1);
    buffer_write(b, buffer_u8, 10);  // "ready": ask the server for everything that's already happened
    network_send_packet(socket, b, buffer_tell(b));
    buffer_delete(b);
}