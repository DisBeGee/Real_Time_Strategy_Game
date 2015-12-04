// argument0 = message type Id
// argument1 = socket being read from

msg = argument0;

if (msg==0) // empty message
{
    // do nothing
}
else if (msg==20) // broadcast message
{
    msgLen = read_ubyte(argument1) //needs to be ubyte - KEEP MESSAGES SHORT!!
    tempBuf = buffer_create_faucet();
    write_buffer_part(tempBuf,argument1,msgLen)
    for (j=0;j<global.PlayerCount;j+=1) 
    {
        if (global.player_socket[j]==argument1) { continue; }
        write_buffer(global.player_socket[j],tempBuf);
    }
    buffer_destroy(tempBuf);
}
else if (msg==22) // forward message to single client
{
    msgLen = read_ubyte(argument1) //needs to be ubyte - KEEP MESSAGES SHORT!!
    recipient = read_ubyte(argument1);
    if ( (global.PlayerCount-1) >= recipient)
    {
        write_buffer_part(global.player_socket[recipient],argument1,msgLen);
    }
    else //discard message
    {
        tempBuf = buffer_create_faucet();
        write_buffer_part(tempBuf,argument1,msgLen);
        buffer_destroy(tempBuf);
    }
}
else if (msg==100) // game start (sent to client)
{  
    global.PlayerId = read_ubyte(global.ServerSocket);
    global.ServerPlyrCnt = read_ubyte(global.ServerSocket);
    // additional info - start
    for (i=0;i<global.ServerPlyrCnt;i+=1)
    {
        global.p_team[i] = read_ubyte(argument1);
        global.p_col[i] = read_uint(argument1);
        namelen = read_ubyte(argument1);
        global.p_name[i] = read_string(argument1,namelen);
        global.p_race[i] = read_ubyte(argument1);
    }
    // set correct parent for ally's and enemy's
    for (i=0;i<global.PlayerMax;i++) {
        global.Player[i] = ENEMY
    }
    for (i=0;i<global.ServerPlyrCnt;i+=1)
    {
        //object_set_parent(global.obj_unit_type[0,i],obj_enem_unit_parent); // units
        //object_set_parent(global.obj_building_type[0,i],obj_enem_building_parent); // buildings
        //global.obj_unit_type[0,i].team = ENEMY
        //global.obj_building_type[0,i].team = ENEMY
        global.Player[i] = ENEMY
        if (global.p_team[i]==global.p_team[global.PlayerId])
        {
            //global.obj_unit_type[0,i].team = ALLY
            //global.obj_building_type[0,i].team = ALLY
            global.Player[i] = ALLY
            //object_set_parent(global.obj_unit_type[0,i],obj_ally_unit_parent); //units
            //object_set_parent(global.obj_building_type[0,i],obj_ally_building_parent); // buildings
        }
    }
    // multiplayer level
    multi_level = read_uint(argument1);
    global.random_start = read_ubyte(argument1); //used for randomizing start positions 
    // additional info  end
    global.ClientState = 8;
    if (global.isHost) { global.ServerState=8; }
    random_set_seed(99); // makes things consistent
    room_goto(multi_level);
    // information I should also send:
        // multiplayer level
        // teams
        // player colors
}
else if (msg==101) // game start (host to server)
{
    rubbish = read_ubyte(argument1); // ignore value
    
    if (global.ServerState!=0) exit; // make sure in correct state

    // check alive + disconnects (is this lagging me UP???)
    for (i=0;i<global.PlayerCount;i+=1)
    {
        write_ushort(global.player_socket[i],0);
        socket_send(global.player_socket[i]);
                
        if socket_has_error(global.player_socket[i])
        {
            // free color
            color_avail[color_index[i]] = true;
        
            for (j=i;j<(global.PlayerCount-1);j+=1)
            {
                global.player_socket[j] = global.player_socket[j+1]
                global.player_name[j] = global.player_name[j+1]
                global.player_team[j] = global.player_team[j+1];
                global.player_color[j] = global.player_color[j+1];
                global.player_race[j] = global.player_race[j+1];
                color_index[j] = color_index[j+1];
            }           
            
            global.PlayerCount -= 1;
        }
    }

    // send start messatge to everyone  
    for (i=0;i<global.PlayerCount;i+=1)
    {
        write_ushort(global.player_socket[i],100); // msgId for start game msg is '100'
        write_ubyte(global.player_socket[i],i); // this give clients thier PlayerId
        write_ubyte(global.player_socket[i],global.PlayerCount); // give client the number of players in game
        //additional info
        for (f=0;f<global.PlayerCount;f+=1)
        {
            //player teams
            write_ubyte(global.player_socket[i],global.player_team[f]);
            //player colors
            write_uint(global.player_socket[i],global.player_color[f]);
            // player names
            write_ubyte(global.player_socket[i],string_length(global.player_name[f]));
            write_string(global.player_socket[i],global.player_name[f]);
            // player race id
            write_ubyte(global.player_socket[i],global.player_race[f]);
        }
        write_uint(global.player_socket[i],map_list[map_index]); // selected multiplayer level
        
        write_ubyte(global.player_socket[i],i/*irandom(9)*/); // send random int for starting positions (not working as expected)
    }
    
    global.ServerState = 1; //state is waiting for clients to start state 8
    

}
else if (msg==110) // update lobby info (sent to client)
{
    lobby_p_count = read_ubyte(argument1);
    
    for (i=0;i<lobby_p_count;i+=1)
    {
        namlang = read_ubyte(argument1);
        lobby_p_name[i] = read_string(argument1,namlang);
        lobby_p_team[i] = read_ubyte(argument1);
        lobby_p_color[i] = read_uint(argument1);
        racelang = read_ubyte(argument1);
        lobby_p_race[i] = read_string(argument1,racelang);
    }
    
    mapnamleng = read_ubyte(argument1);
    lobby_map_name = read_string(argument1,mapnamleng);
}
else if (msg==111) // change team (temp?)
{
    dir = read_ubyte(argument1);
    
    // find out player id
    for (i=0;i<global.PlayerCount;i+=1)
    {
        if (global.player_socket[i]==argument1) { whatid=i; break; }
    }
    
    if (dir==0) //up
    {
        if (global.player_team[whatid]<10) global.player_team[whatid]+=1;
    }
    else // down
    {
        if (global.player_team[whatid]>1) global.player_team[whatid]-=1;
    }
}
else if (msg==112) // change color (temp?)
{
    dir = read_ubyte(argument1);

    // find out player id
    for (i=0;i<global.PlayerCount;i+=1)
    {
        if (global.player_socket[i]==argument1) { whatid=i; break; }
    }
    
    if (dir==0) // left
    {
        // free color
        color_avail[color_index[whatid]] = true;
        
        do
        {
            if (color_index[whatid]==0) { global.player_color[whatid] = color_list[num_colors-1]; color_index[whatid] = num_colors-1; }
            else { global.player_color[whatid] = color_list[color_index[whatid]-1]; color_index[whatid] = color_index[whatid]-1; }
        } until (color_avail[color_index[whatid]]==true)
        
        color_avail[color_index[whatid]] = false;
    }
    else // right
    {
        // free color
        color_avail[color_index[whatid]] = true;
        
        do
        {
            if (color_index[whatid]==(num_colors-1)) { global.player_color[whatid] = color_list[0]; color_index[whatid] = 0; }
            else { global.player_color[whatid] = color_list[color_index[whatid]+1]; color_index[whatid] = color_index[whatid]+1; }
        } until (color_avail[color_index[whatid]]==true)
        
        color_avail[color_index[whatid]] = false;
    }
}
else if (msg==113) // update player name
{
    leng = read_ubyte(argument1);
    
    // find out player id
    for (i=0;i<global.PlayerCount;i+=1)
    {
        if (global.player_socket[i]==argument1) { whatid=i; break; }
    }
    
    // update name
    global.player_name[whatid] = read_string(argument1,leng);
}
else if (msg==114) // change level
{
    dir = read_ubyte(argument1);

    // find out player id
    for (i=0;i<global.PlayerCount;i+=1)
    {
        if (global.player_socket[i]==argument1) { whatid=i; break; }
    }
    
    if (dir==0) // pg up
    {
        if (map_index==0) map_index=(num_maps-1);
        else map_index-=1;
    }
    else // pg down
    {
        if (map_index==(num_maps-1)) map_index=0;
        else map_index+=1;
    }
}
else if (msg==115) // change race
{
    ignore = read_ubyte(argument1);
    
    // find out player id
    for (i=0;i<global.PlayerCount;i+=1)
    {
        if (global.player_socket[i]==argument1) { whatid=i; break; }
    }
    
    if (global.player_race[whatid]==(num_races-1)) global.player_race[whatid]=0;
    else global.player_race[whatid]+=1;
}
else if (msg==600) // create spell projectile
{
    scr_spellHndlr(read_ushort(argument1));
}
else if (msg==700) // update resource amount
{
    resid = read_uint(argument1);
    resamt = read_ushort(argument1);
    
    if instance_exists(resid) 
    { 
        resid.resource_amount = resamt; 
        resid.prev_threshold = resamt;
    }
}
else if (msg==701) // destroy resource
{
    resid = read_uint(argument1);
    
    as_map_setcell(obj_map.map,resid.x/obj_map.map_col_width,((resid.y)/obj_map.map_row_height),1)
    as_map_setcell(obj_map.map,(resid.x/obj_map.map_col_width)-1,((resid.y)/obj_map.map_row_height),1)

    
    if instance_exists(resid) { with (resid) { instance_destroy(); } }
}
else if (msg==800) // initialize net id (request)
{
    unitid = read_uint(argument1);
    
    //get network id
    netid = netId_counter;
    netId_counter += 1;
    
    //send net id to all players
    for (i=0;i<global.PlayerCount;i+=1)
    {
        write_ushort(global.player_socket[i],801);
        write_ushort(global.player_socket[i],netid);
        write_uint(global.player_socket[i],unitid);
    }
}
else if (msg==801) // initialize net id (service) (use this in combination with msg==800 ONLY!!)
{
    netid = read_ushort(argument1);
    unitid = read_uint(argument1);
    
    //set net id
    unitid.netId = netid;
    
    //store id in net id table
    global.netid_table[netid] = unitid;
}
else if (msg==802) // create unit network id (request)
{
    unittype = read_ushort(argument1);
    unitowner = read_ubyte(argument1);
    xcreat = read_short(argument1);
    ycreat = read_short(argument1);
    
    //get network id
    netid = netId_counter;
    netId_counter += 1;
    
    //send unit create info to all other players
    for (i=0;i<global.PlayerCount;i+=1)
    {
        write_ushort(global.player_socket[i],803);
        write_ushort(global.player_socket[i],netid);
        write_ushort(global.player_socket[i],unittype);
        write_ubyte(global.player_socket[i],unitowner);
        write_short(global.player_socket[i],xcreat);
        write_short(global.player_socket[i],ycreat);
    }
}
else if (msg==803) // create unit network id (service) (use this in combination with msg==802)
{
    unitnetid = read_ushort(argument1);
    unittype = read_ushort(argument1);
    unitowner = read_ubyte(argument1);
    xcreat = read_short(argument1);
    ycreat = read_short(argument1);
    
    //create unit
    unitid = instance_create(xcreat,ycreat,global.obj_unit_type[unittype,unitowner]);
    
    //set net id
    unitid.netId = unitnetid;
    
    //store id in net id table
    global.netid_table[unitnetid] = unitid;
}
else if (msg==804) // create building network id (request)
{
    buildtype = read_ushort(argument1);
    buildowner = read_ubyte(argument1);
    xcreat = read_short(argument1);
    ycreat = read_short(argument1);
    
    //get network id
    netid = netId_counter;
    netId_counter += 1;
    
    //send unit create info to all other players
    for (i=0;i<global.PlayerCount;i+=1)
    {
        write_ushort(global.player_socket[i],805);
        write_ushort(global.player_socket[i],netid);
        write_ushort(global.player_socket[i],buildtype);
        write_ubyte(global.player_socket[i],buildowner);
        write_short(global.player_socket[i],xcreat);
        write_short(global.player_socket[i],ycreat);
    }
//    global.buildingbuilding = true //Prevents unit from deselecting found in obj_unit_template_multi
}
else if (msg==805) // create building network id (service) (use this in combination with msg==804)
{
    buildnetid = read_ushort(argument1);
    buildtype = read_ushort(argument1);
    buildowner = read_ubyte(argument1);
    xcreat = read_short(argument1);
    ycreat = read_short(argument1);
    
    //create unit
    buildid = instance_create(xcreat,ycreat,global.obj_building_type[buildtype,buildowner]);
    
    //set net id
    buildid.netId = buildnetid;
    // setup building so it is placed down
    buildid.is_built = false;
    buildid.is_placed = true;
    buildid.building_depth = -y;
    buildid.def_waypointx = buildid.x+buildid.def_waypointposx;
    buildid.def_waypointy = buildid.y+buildid.def_waypointposy;
    buildid.waypointx = buildid.def_waypointx;
    buildid.waypointy = buildid.def_waypointy;
    
    //store id in net id table
    global.netid_table[buildnetid] = buildid;
    
    //Building
    buildid.mask_width = buildid.bbox_right-buildid.bbox_left
    buildid.mask_height = buildid.bbox_bottom-buildid.bbox_top
    //as_map_setrectangle(obj_map.map,bbox_left/64,bbox_top/32,mask_width/64,mask_height/32,-1)
    //as_map_setcell(obj_map.map,x/64,y/32,-1)
    /*
    for (i=buildid.bbox_left;i<buildid.bbox_right;i+=64) {
        for (z=buildid.bbox_top;z<buildid.bbox_bottom;z+=32) {
        
            if (instance_position(i,z,buildid) = buildid) {
            
                as_map_setcell(obj_map.map,i/64,z/32,-1)
            
            }
        }
    } */
    
    //Building cliff fog of war

    

}
else if (msg==806) // create unit network id + waypoint (request)
{
    unittype = read_ushort(argument1);
    unitowner = read_ubyte(argument1);
    xcreat = read_short(argument1);
    ycreat = read_short(argument1);
    wayx = read_short(argument1);
    wayy = read_short(argument1);
    
    //get network id
    netid = netId_counter;
    netId_counter += 1;
    
    //send unit create info to all other players
    for (i=0;i<global.PlayerCount;i+=1)
    {
        write_ushort(global.player_socket[i],807);
        write_ushort(global.player_socket[i],netid);
        write_ushort(global.player_socket[i],unittype);
        write_ubyte(global.player_socket[i],unitowner);
        write_short(global.player_socket[i],xcreat);
        write_short(global.player_socket[i],ycreat);
        write_short(global.player_socket[i],wayx);
        write_short(global.player_socket[i],wayy);
    }
}
else if (msg==807) // create unit network id + waypoint (service) (use this in combination with msg==806)
{
    unitnetid = read_ushort(argument1);
    unittype = read_ushort(argument1);
    unitowner = read_ubyte(argument1);
    xcreat = read_short(argument1);
    ycreat = read_short(argument1);
    wayx = read_short(argument1);
    wayy = read_short(argument1);
    
    //create unit
    unitid = instance_create(xcreat,ycreat,global.obj_unit_type[unittype,unitowner]);
    
    //set net id
    unitid.netId = unitnetid;
    
    //set waypoint
    unitid.move_x = wayx;
    unitid.move_y = wayy;
    unitid.able_to_move = true;
    unitid.alarm[6] = 1;
    
    //store id in net id table
    global.netid_table[unitnetid] = unitid;
}
else if (msg==808) // create building fully built netid (request)
{
    buildtype = read_ushort(argument1);
    buildowner = read_ubyte(argument1);
    xcreat = read_short(argument1);
    ycreat = read_short(argument1);
    
    //get network id
    netid = netId_counter;
    netId_counter += 1;
    
    //send unit create info to all other players
    for (i=0;i<global.PlayerCount;i+=1)
    {
        write_ushort(global.player_socket[i],809);
        write_ushort(global.player_socket[i],netid);
        write_ushort(global.player_socket[i],buildtype);
        write_ubyte(global.player_socket[i],buildowner);
        write_short(global.player_socket[i],xcreat);
        write_short(global.player_socket[i],ycreat);
    }
}
else if (msg==809) // create building fully built netid (service) (use with 808)
{
    buildnetid = read_ushort(argument1);
    buildtype = read_ushort(argument1);
    buildowner = read_ubyte(argument1);
    xcreat = read_short(argument1);
    ycreat = read_short(argument1);
    
    //create building
    buildid = instance_create(xcreat,ycreat,global.obj_building_type[buildtype,buildowner]);
    
    //set net id
    buildid.netId = buildnetid;
    
    //store id in net id table
    global.netid_table[buildnetid] = buildid;
}
else if (msg==900) // chat message
{
    ohner = read_ubyte(argument1);
    team = read_ubyte(argument1);
    leng = read_ubyte(argument1);
    mesg = read_string(argument1,leng);
    // if message for me, show it
    if (team == global.p_team[global.PlayerId] || team == 0)
    {
        //put message into chat queue
        msg = mesg;
        
        for (i=(obj_chat.chat_cap-1);i>0;i-=1) // push everything in the list back
        {
            obj_chat.chat_queue[i] = obj_chat.chat_queue[(i-1)];
            obj_chat.chat_queue_life[i] = obj_chat.chat_queue_life[(i-1)];
            obj_chat.chat_queue_owner[i] = obj_chat.chat_queue_owner[(i-1)];
        }
        obj_chat.chat_queue[0] = msg;
        obj_chat.chat_queue_life[0] = obj_chat.chat_life;
        obj_chat.chat_queue_owner[0] = ohner;
        if (obj_chat.chat_count<obj_chat.chat_cap)
        {
            obj_chat.chat_count += 1;
        }
    }
}
else if (msg==901) // lobby chat message (client to server)
{
    mesjSize = read_ubyte(argument1);

    tempBuf = buffer_create_faucet();
    write_buffer_part(tempBuf,argument1,mesjSize);
    
    // find out player id
    for (i=0;i<global.PlayerCount;i+=1)
    {
        if (global.player_socket[i]==argument1) { whatid=i; break; }
    }
    
    // forward to all players
    for (j=0;j<global.PlayerCount;j+=1) 
    {
        write_ushort(global.player_socket[j],902); // message header: lobby chat message
        write_ubyte(global.player_socket[j],whatid); // owner
        write_buffer(global.player_socket[j],tempBuf); // message
    }
    buffer_destroy(tempBuf);
}
else if (msg==902) // lobby chat message (server to client)
{
    ohner = read_ubyte(argument1);
    leng = read_ubyte(argument1);
    mesg = read_string(argument1,leng);

    if instance_exists(obj_lobby_chat)
    {
        //put message into chat queue
        msg = mesg;
        
        for (i=(obj_lobby_chat.chat_cap-1);i>0;i-=1) // push everything in the list back
        {
            obj_lobby_chat.chat_queue[i] = obj_lobby_chat.chat_queue[(i-1)];
            obj_lobby_chat.chat_queue_owner[i] = obj_lobby_chat.chat_queue_owner[(i-1)];
        }
        obj_lobby_chat.chat_queue[0] = msg;
        obj_lobby_chat.chat_queue_owner[0] = ohner;
        if (obj_lobby_chat.chat_count<obj_lobby_chat.chat_cap)
        {
            obj_lobby_chat.chat_count += 1;
        }
    }

}
else if (msg==1000) // update unit move state
{
    unitId = global.netid_table[read_ushort(argument1)];
    unitId.able_to_move=true;
    unitId.move_x = read_short(argument1);
    unitId.move_y = read_short(argument1);
    unitId.x = read_short(argument1);
    unitId.y = read_short(argument1);
    
    
    // turn off other states
    unitId.build_ing = false;
    unitId.attack_target = 99;
    unitId.attack_mode = false;
    unitId.gathering = false;
    unitId.alarm[6] = 1;
}
else if (msg==1001) // update unit attack state
{
    unitId = global.netid_table[read_ushort(argument1)];
    tarUnit = read_ushort(argument1);
    if (instance_exists(unitId)) {
        // turn off other states
        unitId.gathering = false;
        unitId.build_ing = false;
        
        unitId.attack_mode = true;
        unitId.attack_target = global.netid_table[tarUnit];
    }
}
else if (msg==1002) // update unit for damage taken
{    
    unitId = global.netid_table[read_ushort(argument1)];
    damageTaken = read_short(argument1);
    
    if (instance_exists(unitId))
    {
        unitId.unit_hp -= damageTaken;
        
        with(unitId) {
            draw_sprite(spr_splat,0,x,y)
        }
    
        //broadcast health update
        write_ushort(global.ServerSocket,20); // message id: broadcast message
        write_ubyte(global.ServerSocket,6); // message size
        write_ushort(global.ServerSocket,1021); //message id: sync health
        write_ushort(global.ServerSocket,unitId.netId); // unit id (netId)
        write_short(global.ServerSocket,unitId.unit_hp); // unit health
    }
}
else if (msg==1003) // update unit build state
{
    unitid = global.netid_table[read_ushort(argument1)];
    buildid = global.netid_table[read_ushort(argument1)];
    
    // turn off other states
    unitid.able_to_move = false;
    unitid.attack_target = 99;
    unitid.attack_mode = false;
    unitid.gathering = false;
    
    // building state information
    if instance_exists(buildid)
    {
        unitid.build_target = buildid;
        unitid.buildn_x = buildid.x;
        unitid.buildn_y = buildid.y;
        unitid.build_ing = true;
    }
}
else if (msg==1004) // update unit collecting resource state
{
    unitid = global.netid_table[read_ushort(argument1)];
    resid = read_uint(argument1);
    
    // turn off other states
    unitid.attack_target = 99;
    unitid.attack_mode = false;
    unitid.build_ing = false;
    
    // gathering state info
    unitid.gathering = true;
    unitid.holding_resources = true;
    unitid.grout_collect = 0;
    unitid.grout_target = resid;
    unitid.res_x = resid.x;
    unitid.res_y = resid.y;
    unitid.grout_type = resid.type;
}
else if (msg==1005) // update unit storing resource state
{
    unitid = global.netid_table[read_ushort(argument1)];
    hausid = global.netid_table[read_ushort(argument1)];
    
    // turn off other states
    unitid.attack_target = 99;
    unitid.attack_mode = false;
    unitid.build_ing = false;
    
    // gathering state info
    unitid.gathering = true;
    unitid.holding_resources = true;
    unitid.grout_collect = unitid.res_hold_lim;
    unitid.grout_deposit = hausid;
}
else if (msg==1006) // update unit casting state
{
    unitid = global.netid_table[read_ushort(argument1)];
    
    // turn off other states
    unitid.able_to_move = false;
    unitid.attack_target = 99;
    unitid.attack_mode = false;
    unitid.gathering = false;
    unitid.build_ing = false;
    
    // cast state information
    unitid.cast = true;
    unitid.casting = true;
    unitid.cast_code = "";
    unitid.alarm[3] = 30; // just put some large number
    unitid.casting = true;
    unitid.state = 7;
}
else if (msg==1007) // update unit cast type 1 state
{
    unitid = global.netid_table[read_ushort(argument1)];
    tarid = global.netid_table[read_ushort(argument1)];
    
    // turn off other states
    unitid.able_to_move = false;
    unitid.attack_target = 99;
    unitid.attack_mode = false;
    unitid.gathering = false;
    unitid.build_ing = false;
    
    // cast state information
    unitid.cast = true;
    unitid.cast_code = "";
    unitid.cast_time = 30; // just put some large number
    unitid.cast_target = tarid;
}
else if (msg==1008) // update unit cast type 2 state
{
    unitid = global.netid_table[read_ushort(argument1)];
    tarx = global.netid_table[read_short(argument1)];
    tary = global.netid_table[read_short(argument1)];
    
    // turn off other states
    unitid.able_to_move = false;
    unitid.attack_target = 99;
    unitid.attack_mode = false;
    unitid.gathering = false;
    unitid.build_ing = false;
    
    // cast state information
    unitid.cast = true;
    unitid.cast_code = "";
    unitid.cast_time = 30; // just put some large number
    unitid.cast_targetx = tarx;
    unitid.cast_targetx = tary;
}
else if (msg==1020) // sync position
{
    
    unitId = global.netid_table[read_ushort(argument1)];
    truex = read_short(argument1)
    truey = read_short(argument1)
    if (instance_exists(unitId)) {
        unitId.x = truex;
        unitId.y = truey;
    }
}
else if (msg==1021) // sync health
{
    unitId = global.netid_table[read_ushort(argument1)];
    unitId.unit_hp = read_short(argument1);
}
else if (msg==1030) // update stun state
{
    unitid = global.netid_table[read_ushort(argument1)];
    stunleng = read_ushort(argument1);
    
    // stun state information
    if (instance_exists(unitid))
    {
        unitid.stun_counter = stunleng;
        if (unitid.stunned==false)
        {
            unitid.ailment_count += 1;
            unitid.stunned = true;
        }
    
        // sync stun state with others
        write_ushort(global.ServerSocket,20); // message id: broadcast message
        write_ubyte(global.ServerSocket,6); // message size
        write_ushort(global.ServerSocket,1031); //message id: sync stun
        write_ushort(global.ServerSocket,unitid.netId); // unit id (netId)
        write_ushort(global.ServerSocket,stunleng); // stunleng
    }
}
else if (msg==1031) // sync stun state
{
    unitid = global.netid_table[read_ushort(argument1)];
    stunleng = read_ushort(argument1);
    
    // stun state information
    if (instance_exists(unitid))
    {
        unitid.stun_counter = stunleng;
        if (unitid.stunned==false)
        {
            unitid.ailment_count += 1;
            unitid.stunned = true;
        }
    }
}
else if (msg==1100) // update building 'is_built' state
{
    buildId = global.netid_table[read_ushort(argument1)];
    buildId.is_built = true;
}
else
{
    // possible error: whole message not received, or typo in msg handler routine,
    //                 may also be a sign that the network traffic is too high.
    show_message("error: unknown message id:"+string(msg));
    
    // Use below if not debugging (and comment-out above code)
    //buffer_clear(argument1); // clear dirty messages
}
//else if (msg==1)
//{

//}







// handle the rest of the contents of the message
if (buffer_bytes_left(argument1)>2) { scr_msgHandler(read_ushort(argument1),argument1) }