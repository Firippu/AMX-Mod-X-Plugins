/*
installation:
	Use the map specific plugin method, instructions shown in link below
	http://wiki.amxmodx.org/Configuring_AMX_Mod_X#Map_Specific_Plugins

cvars:
	"ski_1337_bomb_off #"  // Removes bombsite -- 0 off -- 1 on
*/

#include <amxmodx>
#include <engine>

#define VERSION "1.1.0"

new g_pDisableBombSite

public plugin_init() {
	register_plugin("surf_ski-1337",VERSION,"Firippu")

	g_pDisableBombSite=register_cvar("ski_1337_bomb_off","0")

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
