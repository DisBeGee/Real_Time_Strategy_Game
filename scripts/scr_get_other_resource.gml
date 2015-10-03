//scr_get_other_resource(x , y , resource_object , original object ID)

//Recursive function for getting maxed resource

var ex = argument0
var wy = argument1
var obj = argument2
var oid = argument3

instance_deactivate_object(oid)
//temp = instance_nearest(ex,wy,obj)
temp = instance_nearest(res_x + random(4) - random(4), res_y + random(4) - random(4), obj)    

if (temp == noone) {
    instance_activate_object(oid)
    return -1
}

if (temp.num_harvesting < temp.max_harvesting) {
    instance_activate_object(oid)
    return temp
}
return_val = scr_get_other_resource(ex,wy,obj,temp)
instance_activate_object(oid)
return return_val