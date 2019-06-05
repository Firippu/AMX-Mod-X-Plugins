/*
description:
	Renders built-in shortcuts ineffective & announces player's name on map completion

installation:
	Use the map specific plugin & config method, instructions shown below;

	Make a text file named and located here:
		amxmodx/configs/maps/plugins-surf_simpsons_final.ini

	Contents of text file:
		surf_simpsons_pro.amxx
*/

#include <amxmodx>
#include <hamsandwich>
#include <engine>

#define VERSION "1.0.1"

new bool:g_bPlayerFinished[33]

new const g_szShortcutModels[][] = {
	"*145",
	"*162",
	"*139"
}

public plugin_init() {
	register_plugin("Surf Simpsons Pro",VERSION,"Firippu")

	RegisterHam(Ham_Spawn,"player","fwdPlayerSpawn",1)
	RegisterHam(Ham_Use,"func_button","fwdPlayerUse",1)

	new iEntity

	if((iEntity=find_ent_by_tname(-1,"beat"))) {
		remove_entity(iEntity)
	}

	if((iEntity=create_entity("trigger_teleport"))) {
		entity_set_origin(iEntity,Float:{-1571.0,3721.0,-1169.0})
		entity_set_string(iEntity,EV_SZ_target,"22")
		DispatchSpawn(iEntity)
	}

	for(new i=0; i<sizeof g_szShortcutModels; i++) {
		if((iEntity=find_ent_by_model(-1,"trigger_teleport",g_szShortcutModels[i]))) {
			remove_entity(iEntity)
		}
	}
}

public fwdPlayerSpawn(iPlayer) {
	g_bPlayerFinished[iPlayer]=false
}

public fwdPlayerUse(iEntity,iPlayer) {
	if(!g_bPlayerFinished[iPlayer]) {
		static szTarget[5]

		entity_get_string(iEntity,EV_SZ_target,szTarget,4)

		if(equal(szTarget,"beat")) {
			g_bPlayerFinished[iPlayer]=true

			static szPlayerName[32]

			get_user_name(iPlayer,szPlayerName,31)

			set_hudmessage(0,255,0,-1.0,0.30,1,6.0,6.0,1.0,1.0)

			show_hudmessage(0,"%s has completed the map!",szPlayerName)
		}
	}
}
