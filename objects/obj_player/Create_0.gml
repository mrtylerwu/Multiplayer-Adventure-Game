// Create
// movement
move_speed = 3.5;           // normal walking speed
a_speed = 4.5;              // sprint speed
current_speed = move_speed;
can_move = true;
//staminaBar = 100;

sent_start = false;

// water
in_water = false;
water_walk_speed = 1.5;   // walking in water
water_run_speed  = 2.0;   // running in water

// keeps the player inside the map
edge_margin = CELL * 3;

// used to send your position only when it changes
last_x = x;
last_y = y;


// Step, replacing the send block
if ((x != last_x || y != last_y) && instance_exists(obj_client)) {
    // ...send code...
    last_x = x;
    last_y = y;
}

damage_cooldown = 1.5; // Seconds of protection
damage_timer = 0;
// health
//health = 100;
hp_max = 100;
hp = hp_max;
last_hp = -1;      // forces one send on the first frame
hurt_timer = 0;   // red flash when hit

// stamina
stamina_max = 100;
staminaBar = stamina_max;
stamina_drain = 0.175;           // per frame while sprinting: about 8 seconds from full
stamina_regen_idle = 0.125;      // per frame while standing still: refills in about 3 seconds
stamina_regen_moving = 0.05;    // per frame while walking: about 17 seconds
stamina_recover = 20;          // after running out, this much must come back before you can sprint again
exhausted = false;
