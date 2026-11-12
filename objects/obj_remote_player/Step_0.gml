// Step
if (hurt_timer > 0) hurt_timer--;
x = lerp(x, target_x, 0.3);
y = lerp(y, target_y, 0.3);
depth = -bbox_bottom;