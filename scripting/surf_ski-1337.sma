/*
description:
	Corrects intentional flaws within the map, rendering it playable
	Gives option for bomb usability

installation:
	Use the map specific plugin & config method, instructions shown below;

	Make a text file named and located here:
		amxmodx/configs/maps/plugins-surf_ski-1337.ini

	Contents of .ini file:
		surf_ski-1337.amxx

cvars:
	Make a text file named and located here:
		amxmodx/configs/maps/surf_ski-1337.cfg

	Contents of .cfg file:
		"s1337_disable_bomb <0|1>"  // Removes bombsite, 1 disables
*/

#include <amxmodx>
#include <engine>

#define VERSION "1.1.0a"

new g_pDisableBombSite

public plugin_init() {
	register_plugin("surf_ski-1337",VERSION,"Firippu")

	g_pDisableBombSite=register_cvar("s1337_disable_bomb","0")

	new iEntity,iTotal

	iTotal=entity_count()

	for(iEntity=0; iEntity<=iTotal; iEntity++) {
		if(!is_valid_ent(iEntity)) {
			continue
		}

		static szClassname[23]

		entity_get_string(iEntity,EV_SZ_classname,szClassname,22)

		if(equal(szClassname,"info_player_start") || equal(szClassname,"info_player_deathmatch")) {
			static Float:vOrigin[3]

			entity_get_vector(iEntity,EV_VEC_origin,vOrigin)

			vOrigin[1] -= 750.0

			entity_set_origin(iEntity,vOrigin)
		} else if(equal(szClassname,"func_button") || equal(szClassname,"trigger_hurt") || (equal(szClassname,"func_bomb_target") && get_pcvar_num(g_pDisableBombSite))) {
			remove_entity(iEntity)
		}
	}
}

public plugin_precache() {
	precache_generic("czcs_office.wad")
	precache_generic("czde_dust.wad")
}
