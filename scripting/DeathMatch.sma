/*
description:
	Automatic removal and respawn of weapons with given time
	Automatic player respawn with given delay

cvars:
	"amx_wrc #"	 // Amount of seconds weapon reset will occur
	"amx_prd #"	 // Amount of seconds player respawn will delay

commands:
	"say /respawn"  // Respawns player under specific conditions
*/

#include <amxmodx>
#include <engine>
#include <hamsandwich>
#include <cstrike>

#define VERSION "1.0.0"

#define PREFIX "[DeathMatch]"

new bool:g_bPlayerQueued[33]

new g_szThinkerClassname[]="deathmatch_thinker"

new g_iResetEntity

new g_pCvarWeaponResetCycle,
	g_pCvarPlayerRespawnDelay

public plugin_init() {
	register_plugin("DeathMatch",VERSION,"Firippu")

	g_pCvarWeaponResetCycle=register_cvar("amx_wrc","180")
	g_pCvarPlayerRespawnDelay=register_cvar("amx_prd","3")

	register_clcmd("say /respawn","cmdRespawn")

	register_event("DeathMsg","fwdPlayerKilled","a")

	register_clcmd("joinclass","clcmd_joinclass")

	new iEntity
	if((iEntity=create_entity("info_target"))) {
		entity_set_string(iEntity,EV_SZ_classname,g_szThinkerClassname)
		entity_set_float(iEntity,EV_FL_nextthink,get_gametime() + get_pcvar_float(g_pCvarWeaponResetCycle))
		register_think(g_szThinkerClassname,"ResetWeapons")
	}
}

public client_disconnected(iPlayer) {
	g_bPlayerQueued[iPlayer]=false
}

public clcmd_joinclass(iPlayer) {
	set_task(1.0,"checkifstilldead",iPlayer)
}

public checkifstilldead(iPlayer) {
	if(!is_user_alive(iPlayer)) {
		set_task(1.0,"cmdRespawn",iPlayer)
	}
}

public cmdRespawn(iPlayer) {
	fwdPlayerKilled(iPlayer)
}

public bool:bPlayerInTeam(iPlayer) {
	switch(cs_get_user_team(iPlayer)) {
		case 1..2: {
			return true
		}
	}

	return false
}

public fwdPlayerKilled(iPlayer) {
	if(!iPlayer) {
		iPlayer=read_data(2)
	}

	if(!is_user_alive(iPlayer) && !g_bPlayerQueued[iPlayer] && bPlayerInTeam(iPlayer)) {
		g_bPlayerQueued[iPlayer]=true

		client_print(iPlayer,print_chat,"%s Respawning in %d seconds.",PREFIX,get_pcvar_num(g_pCvarPlayerRespawnDelay))

		set_task(get_pcvar_float(g_pCvarPlayerRespawnDelay),"fnRespawnPlayer",iPlayer)
	} else {
		client_print(iPlayer,print_chat,"%s Not qualified to respawn.",PREFIX)
	}
}

public fnRespawnPlayer(iPlayer) {
	if(!is_user_alive(iPlayer) && g_bPlayerQueued[iPlayer] && bPlayerInTeam(iPlayer)) {
		ExecuteHam(Ham_CS_RoundRespawn,iPlayer)
	}

	g_bPlayerQueued[iPlayer]=false
}

public ResetWeapons(iEntity) {
	while((g_iResetEntity=find_ent_by_class(g_iResetEntity,"weaponbox")) != 0) {
		call_think(g_iResetEntity)
	}

	while((g_iResetEntity=find_ent_by_class(g_iResetEntity,"armoury_entity")) != 0) {
		if(entity_get_int(g_iResetEntity,EV_INT_effects) & EF_NODRAW) {
			DispatchSpawn(g_iResetEntity)

			entity_set_int(g_iResetEntity,EV_INT_effects,entity_get_int(g_iResetEntity,EV_INT_effects) & ~EF_NODRAW)
		}
	}

	client_print(0,print_chat,"%s Weapons Reset",PREFIX)

	entity_set_float(iEntity,EV_FL_nextthink,get_gametime() + get_pcvar_float(g_pCvarWeaponResetCycle))
}
