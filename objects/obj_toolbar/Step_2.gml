if (global.tool_selected == -1) exit;   // <- new: empty hands, clicking does nothing
if (global.inv_open || global.click_used) exit;

// End Step  (by now pickups have had their chance to claim the click)
if (global.inv_open || global.click_used) exit;
if (!mouse_check_button_pressed(mb_left)) exit;
if (!instance_exists(obj_player) || instance_exists(obj_swing)) exit;   // one swing at a time

var cx = (obj_player.bbox_left + obj_player.bbox_right) / 2;
var cy = (obj_player.bbox_top + obj_player.bbox_bottom) / 2;

var s = instance_create_layer(cx, cy, "Instances", obj_swing);
s.owner = obj_player.id;
s.tool = global.tool_selected;
s.aim = point_direction(cx, cy, mouse_x, mouse_y);
s.sweep = swing_dir;
swing_dir *= -1;