if (room == rm_game) {
    ds_map_clear(world_pickups);   // old room's instances are gone
    ds_map_clear(remote_players);   // forget characters from the old room, the server is about to resend them
    var b = buffer_create(4, buffer_grow, 1);
    buffer_write(b, buffer_u8, 10);   // ready
    network_send_packet(socket, b, buffer_tell(b));
    buffer_delete(b);
}