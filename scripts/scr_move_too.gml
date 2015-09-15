//scr_move_too(x,y,speed)

/* Arguments:
argument0 = x position where the unit should move
argument1 = y position where the unit should move
argument2 = movement speed
*/


if (following_path=true) {path_delete(my_path)} //deletes the old path (I am not completely sure if that is nessesary...)
my_path=path_add() //make the path to follow
following_path=true //this variable does hold if the unit is currently following the path
//mp_grid_path(obj_control_ingame.grid,my_path,x,y,argument0,argument1,1) 
gotox=argument0
gotoy=argument1
path_start(my_path,argument2,0,1)

/*here is a fix so that fix that if the place
where it was moving towards were blocked, then the
unit will not move. So this basicly checks how far the
unit is from it's final destination
and if it haven't moved in arlarm0 then the way were blocked and it is
going to move straight to where the mouse pointed.
*/

xpath_start=x
ypath_start=y

xpath_end=move_x //Lastpress is where the mouse pressed when the movement started
ypath_end=move_y //it's global variables initialized in the obj_control create event.

old_dist=point_distance(xpath_start,ypath_start,move_x,move_y)
alarm[0]=argument2*2 //sets the check alarm to the speed * 2