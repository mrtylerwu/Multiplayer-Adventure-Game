if instance_exists(obj_player){
	direction = point_direction(x, y, obj_player.x, obj_player.y)
	x += lengthdir_x(base_speed, direction);
    y += lengthdir_y(base_speed, direction);
	chase_timer += 1 / room_speed;

        // Wait until the timer finishes
	if (chase_timer >= chase_delay)
	{
		is_chasing = true;
	}
}

