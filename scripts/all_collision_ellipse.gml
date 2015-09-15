var iid//,temp,i;
var temp
var i
if (!global.list_made){ //new list
    global.__list = ds_queue_create();
    temp = ds_queue_create();
    do{
        iid = collision_ellipse(argument0,argument1,argument2,argument3,argument4,argument5,argument6);
        instance_deactivate_object(iid);
        if iid>-1{
            ds_queue_enqueue(global.__list,iid)
            instance_deactivate_object(iid);
        }
    }
    until (iid<0)
    ds_queue_copy(temp,global.__list);
    while ds_queue_size(global.__list)>0{
        instance_activate_object(ds_queue_dequeue(global.__list));
    }
    ds_queue_copy(global.__list,temp);
    ds_queue_destroy(temp)
    global.list_made = true
}
{ //otherwise there is an active list
    if ds_queue_size(global.__list)>0{
        global._id = ds_queue_dequeue(global.__list);
        return 1;
    }
    else{ //end of list
        ds_queue_destroy(global.__list);
        global.__list = -1;
        global.list_made = false
        return 0;
    }
}