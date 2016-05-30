#include <amxmodx>
#include <engine>
#include <hamsandwich>

#define SECONDS 60.0

new g_szThinkerClassname[]="35hpcars_thinker"

new g_iEntity

public plugin_init() {
	register_plugin("35hp_cars","1.0","Firippu")

	new szMapName[11]
	get_mapname(szMapName,10)

	if(equali(szMapName,"35hp_cars")) {
		if((g_iEntity = create_entity("info_target"))) {
			entity_set_string(g_iEntity,EV_SZ_classname,g_szThinkerClassname)
			entity_set_float(g_iEntity,EV_FL_nextthink,get_gametime() + SECONDS)
			register_think(g_szThinkerClassname,"ThinkerThought")
		}

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

	entity_set_float(iThinker,EV_FL_nextthink,get_gametime() + SECONDS)
}

public ResetCar(iCar) {
	static Float:vOrigin[3]
	entity_get_vector(iCar,EV_VEC_oldorigin,vOrigin)
	entity_set_vector(iCar,EV_VEC_angles,Float:{0.0,0.0,0.0})
	entity_set_vector(iCar,EV_VEC_velocity,Float:{0.0,0.0,0.0})
	entity_set_origin(iCar,vOrigin)
}
