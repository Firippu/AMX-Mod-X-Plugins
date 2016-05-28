#include <amxmodx>
#include <engine>

#define VERSION	"0.1"

public plugin_init() {
	register_plugin("MiscFixes",VERSION,"Firippu")

	new szMapName[33]
	get_mapname(szMapName,32)

	if(equali(szMapName,"surf_megawave")) {
		MoveEntByTargetname("bonus",Float:{979.0,561.0,600.0})
	} else if(equali(szMapName,"surf_green")) {
		MoveEntByTargetname("bonus",Float:{-771.0,-1855.0,-2500.0})
	} else if(equali(szMapName,"surf_ninja")) {
		MoveEntByTargetname("t",Float:{-2816.0,-3336.0,3440.0})
		MoveEntByTargetname("ct",Float:{-3119.0,-3343.0,3440.0})
	}
}

stock MoveEntByTargetname(szTargetname[],Float:newOrigin[3]) {
	entity_set_origin(find_ent_by_tname(-1,szTargetname),Float:newOrigin)
}
