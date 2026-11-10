// End Step
if (!instance_exists(owner)) { instance_destroy(); exit; }

// first frame: read the settings for the chosen tool
if (!started) {
    started = true;
    var def = global.tool_list[tool];
    sprite_index = def.sprite;
    duration = def.swing_time;
    arc = def.swing_arc;
    reach = def.reach;
    tip = def.tip_angle;
    depth = owner.depth - 1;
}

timer++;
var t = timer / duration;
var eased = 1 - power(1 - t, 3);

// the direction the tool should point right now, sweeping through the arc
var dir = aim - sweep * arc / 2 + sweep * arc * eased;

// turn the sprite by the difference between where it should point and where the art points.
// when it's mirrored (sweep = -1) the tip flips to -tip_angle, which is why this multiplies by sweep
var sc = 1;                       // change this to scale the tool up or down
image_xscale = sc;
image_yscale = sweep * sc;
image_angle = dir - tip * sweep;

// the handle sits on a circle around the player's center, following them while they move
var cx = (owner.bbox_left + owner.bbox_right) / 2;
var cy = (owner.bbox_top + owner.bbox_bottom) / 2;
x = cx + lengthdir_x(reach, dir);
y = cy + lengthdir_y(reach, dir);

// fade out over the last 30%
image_alpha = (t < 0.7) ? 1 : 1 - (t - 0.7) / 0.3;

if (timer >= duration) instance_destroy();