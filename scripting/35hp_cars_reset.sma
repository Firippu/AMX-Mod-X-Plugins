/*
description:
	This plugin is for the map 35hp_cars. It allows the cars to be reset & set back to their spawn.
	This is either done automatically by a set number of seconds, or by an admin command.

cvars:
	"35hp_cars_reset <#>"    // Amount of seconds cars automatically reset

commands:
	"say /resetcars" // Resets cars on demand, admin only
*/


#include <amxmodx>
#include <engine>
#include <hamsandwich>

new const g_szThinkerClassname[]="35hpcars_thinker"

new g_iEntity
new g_pCvarCarsReset

public plugin_init() {
	register_plugin("35hp_cars","1.1","Firippu")

	new szMapName[11]
	get_mapname(szMapName,10)

	if(equali(szMapName,"35hp_cars")) {
		if((g_iEntity = create_entity("info_target"))) {
			entity_set_string(g_iEntity,EV_SZ_classname,g_szThinkerClassname)
			entity_set_float(g_iEntity,EV_FL_nextthink,get_gametime() + get_pcvar_num(g_pCvarCarsReset))
			register_think(g_szThinkerClassname,"ThinkerThought")
		}

		g_pCvarCarsReset=register_cvar("35hp_cars_reset","60")

		register_clcmd("say /resetcars","cmdResetCars")
	}
}

public cmdResetCars(iPlayer) {
	if(get_user_flags(iPlayer) & ADMIN_KICK) {
		while((g_iEntity=find_ent_by_class(g_iEntity,"func_vehicle")) != 0) {
			ResetCar(g_iEntity)
		}
	}
}

public ThinkerThought(iThinker) {
	while((g_iEntity=find_ent_by_class(g_iEntity,"func_vehicle")) != 0) {
		if(!ExecuteHam(Ham_IsInWorld,g_iEntity)) {
			ResetCar(g_iEntity)
		}
	}

	entity_set_float(iThinker,EV_FL_nextthink,get_gametime() + get_pcvar_num(g_pCvarCarsReset))
}

public ResetCar(iCar) {
	static Float:vOrigin[3]
	entity_get_vector(iCar,EV_VEC_oldorigin,vOrigin)
	entity_set_vector(iCar,EV_VEC_angles,Float:{0.0,0.0,0.0})
	entity_set_vector(iCar,EV_VEC_velocity,Float:{0.0,0.0,0.0})
	entity_set_origin(iCar,vOrigin)
}
