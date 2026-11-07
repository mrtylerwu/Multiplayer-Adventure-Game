// Create
// movement
move_speed = 3;           // normal walking speed
a_speed = 5;              // sprint speed
current_speed = move_speed;
can_move = true;
staminaBar = 100;

// water
in_water = false;
water_walk_speed = 1.5;   // walking in water
water_run_speed  = 2.0;   // running in water

// keeps the player inside the map
edge_margin = CELL * 3;

// used to send your position only when it changes
last_x = x;
last_y = y;

// health
health = 100;