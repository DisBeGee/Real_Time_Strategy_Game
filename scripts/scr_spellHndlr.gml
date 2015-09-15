// argument0 = spell index

if (argument0==1) // fireball spell
{
    team = read_ubyte(global.ServerSocket);
    xpos = read_short(global.ServerSocket);
    ypos = read_short(global.ServerSocket);
    tarx = read_short(global.ServerSocket);
    tary = read_short(global.ServerSocket);
    dam = read_short(global.ServerSocket);
    aoe = read_short(global.ServerSocket);
    
    //setup projectile
    proj = instance_create(xpos,ypos,obj_projectile_fireball);
    proj.create_multi = true; // do not create for other players (Yeah, it should be TRUE)
    proj.owned = false; // not own this projectile
    if (team==global.p_team[global.PlayerId]) { proj.targetable_units = obj_enem_unit_parent; } else { proj.targetable_units = obj_ally_unit_parent; } // set correct targets
    proj.targetx = tarx;
    proj.targety = tary;
    proj.damage = dam;
    proj.aoe = aoe;
}
else if (argument0==2) // stun spell
{
    team = read_ubyte(global.ServerSocket);
    xpos = read_short(global.ServerSocket);
    ypos = read_short(global.ServerSocket);
    tarid = global.netid_table[read_ushort(global.ServerSocket)];
    
    //setup projectile
    proj = instance_create(xpos,ypos,obj_projectile_cocktail);
    proj.create_multi = true; // do not create for other players (Yeah, it should be TRUE)
    proj.owned = false; // not own this projectile
    if (team==global.p_team[global.PlayerId]) { proj.targetable_units = obj_enem_unit_parent; } else { proj.targetable_units = obj_ally_unit_parent; } // set correct targets
    proj.target = tarid;
}
else
{
    // FOR DEBUGGING
    show_message("(scr_spellHndlr)Invalid spell index: "+string(argument0));
}