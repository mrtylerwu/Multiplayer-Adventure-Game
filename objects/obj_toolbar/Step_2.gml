// End Step
if (global.tool_selected == -1) exit;
if (global.inv_open || global.click_used) exit;
if (!mouse_check_button_pressed(mb_left)) exit;
if (!instance_exists(obj_player) || instance_exists(my_swing)) exit;   // only your own swing blocks you

var cx = (obj_player.bbox_left + obj_player.bbox_right) / 2;
var cy = (obj_player.bbox_top + obj_player.bbox_bottom) / 2;

var s = instance_create_layer(cx, cy, "Instances", obj_swing);
s.owner = obj_player.id;
s.tool = global.tool_selected;
s.aim = point_direction(cx, cy, mouse_x, mouse_y);
s.sweep = swing_dir;
my_swing = s;
swing_dir *= -1;

// tell the server, so everyone else sees it too
var b = buffer_create(8, buffer_grow, 1);
buffer_write(b, buffer_u8, 5);
buffer_write(b, buffer_u8, s.tool);
buffer_write(b, buffer_f32, s.aim);
buffer_write(b, buffer_s8, s.sweep);
net_send_to_server(b);
buffer_delete(b);