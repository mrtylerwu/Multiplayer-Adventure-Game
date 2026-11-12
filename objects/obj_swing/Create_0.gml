// obj_swing, Create
owner = noone;
tool = 0;
aim = 0;
sweep = 1;
timer = 0;
started = false;
sprite_index = -1;

// hit detection
hit_ids = ds_list_create();   // what this swing has already hit, so nothing is hit twice
blade_len = 40;               // how far the tool reaches past the handle, in pixels
hit_radius = 14;              // how wide the hit area is
is_mine = false;              // set to true in the first step if it's your own swing