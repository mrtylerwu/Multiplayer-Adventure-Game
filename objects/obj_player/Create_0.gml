// Create
last_x = x;
last_y = y;

// Step, replacing the send block
if ((x != last_x || y != last_y) && instance_exists(obj_client)) {
    // ...send code...
    last_x = x;
    last_y = y;
}