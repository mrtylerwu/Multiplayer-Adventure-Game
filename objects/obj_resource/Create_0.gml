net_id = -1;
hp = 100;               // replaced by the real value right after creation
hp_max = -1;            // looked up from the resource list on the first step
res_type = "";          // the child object sets this
solid = true;           // the player can't walk through the base
shake_timer = 0;
fade_alpha = 1;
near_player = false;
show_range = 200;       // the health bar appears when you're this close (pixels)
bar_only_when_damaged = false;
depth = -y;             // lower on screen = drawn in front