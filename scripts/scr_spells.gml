#define scr_spells


#define scr_spell_heal
cast_target.unit_hp += cast_damage;hud_button_cooldown_index[cast_button_index]=cast_cooldown;

#define scr_spell_clight
temp_proj=instance_create(-100,-100,cast_object);temp_proj.owner=id;temp_proj.target=cast_target;temp_proj.damage=cast_damage;hud_button_cooldown_index[cast_button_index]=cast_cooldown;

#define scr_spell_cocktail
temp_proj=instance_create(x,y,cast_object);temp_proj.target = cast_target;hud_button_cooldown_index[cast_button_index]=cast_cooldown;
#define scr_spell_scilence
temp_proj=instance_create(cast_targetx,cast_targety,cast_object);hud_button_cooldown_index[cast_button_index]=cast_cooldown;

#define scr_spell_grenade
temp_proj=instance_create(x,y,cast_object);temp_proj.targetx=cast_targetx;temp_proj.targety=cast_targety;hud_button_cooldown_index[cast_button_index]=cast_cooldown;