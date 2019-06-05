/* Description;
	Disables the automatic damage afflicted on players upon spawn
*/

#include <amxmodx>
#include <engine>

public plugin_init() {
	register_plugin("35hp_FullHealth","0.1","Firippu")

	new szMapName[32]
	get_mapname(szMapName,31)

	if(equali(szMapName,"35hp_2")
	|| equali(szMapName,"35hp_cars")
	|| equali(szMapName,"35hp_glass")
	|| equali(szMapName,"35hp_reborn")
	|| equali(szMapName,"35hp_super_mario")) {
		new iEntity
		while((iEntity = find_ent_by_class(iEntity,"game_player_hurt")) != 0) {
			remove_entity(iEntity)
		}
	} else if(equali(szMapName,"35hp_hunters")) {
		register_touch("trigger_multiple","player","fwdPlayerTouchedTriggerMultiple")
	}
}

public fwdPlayerTouchedTriggerMultiple(iEntity,iPlayer) {
	set_user_velocity(iPlayer,Float:{0.0,0.0,0.0})
	static Float:vOrigin[3]
	entity_get_vector(iPlayer,EV_VEC_origin,vOrigin)
	vOrigin[2] -= 120.0
	entity_set_origin(iPlayer,vOrigin)
}
