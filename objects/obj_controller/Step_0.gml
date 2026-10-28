// Step event of the controller object
if (keyboard_check_pressed(ord("H"))) {
    instance_create_layer(0, 0, "Instances", obj_server);
    alarm[0] = 30;   // the host's client is created by the alarm, not here
}
if (keyboard_check_pressed(ord("J"))) {
    instance_create_layer(0, 0, "Instances", obj_client);
}