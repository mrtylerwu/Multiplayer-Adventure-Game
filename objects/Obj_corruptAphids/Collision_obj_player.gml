if (obj_player.hp <= dmg){
	instance_destroy(obj_player)
}

if (other.damage_timer <= 0)
{
    other.hp -= dmg;
    other.damage_timer = other.damage_cooldown;
}