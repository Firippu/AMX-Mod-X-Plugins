#include <amxmodx>
#include <engine>

#define SECONDS 10.0

new g_szThinkerClassname[]="35hp_thinker"
new g_iBrokenGlass[174]
new g_iCount
new g_iGlass

public plugin_init() {
	register_plugin("35hp_glass","1.0","Firippu")

	new szMapName[12]
	get_mapname(szMapName,11)

	if(equali(szMapName,"35hp_glass")) {
		register_touch("func_breakable","player","fwdPlayerTouch")

		new iEntity
		if((iEntity = create_entity("info_target"))) {
			entity_set_string(iEntity,EV_SZ_classname,g_szThinkerClassname)
			entity_set_float(iEntity,EV_FL_nextthink,get_gametime() + SECONDS)
			register_think(g_szThinkerClassname,"ThinkerThought")
		}
	}
}

public fwdPlayerTouch(iEntity,iPlayer) {
	static Float:fHealth
	fHealth = entity_get_float(iEntity,EV_FL_health)-0.1
	entity_set_float(iEntity,EV_FL_health,fHealth)

	if(fHealth<0) {
		fakedamage(iEntity,"func_breakable",0.1,0)
	}
}

public ThinkerThought(iThinker) {
	g_iBrokenGlass=""
	g_iCount=0
	while((g_iGlass=find_ent_by_tname(g_iGlass,"glass")) != 0) {
		if(entity_get_int(g_iGlass,EV_INT_effects) & EF_NODRAW) {
			g_iBrokenGlass[g_iCount]=g_iGlass
			g_iCount++
		}
	}

	if(g_iCount!=0) {
		g_iGlass=g_iBrokenGlass[random_num(0,(g_iCount-1))]
		DispatchSpawn(g_iGlass)
		entity_set_int(g_iGlass,EV_INT_effects,entity_get_int(g_iGlass,EV_INT_effects) & ~EF_NODRAW)
		entity_set_float(g_iGlass,EV_FL_health,10.0)
	}

	entity_set_float(iThinker,EV_FL_nextthink,get_gametime() + SECONDS)
}
