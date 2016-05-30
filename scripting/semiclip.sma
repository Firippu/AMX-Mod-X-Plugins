#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

#define VERSION "0.0.1"

new bool:g_bAlive[33]

new g_pTR2

public plugin_init() {
	register_plugin("semiclip",VERSION,"Firippu")

	new szMapName[33]
	get_mapname(szMapName,32)

	if(equali(szMapName,"de_inferno")) {
		RegisterHam(Ham_Killed,"player","fwdPlayerKilled",1)
		RegisterHam(Ham_Spawn,"player","fwdPlayerSpawn",1)
		register_forward(FM_PlayerPreThink,"preThink")
		register_forward(FM_PlayerPostThink,"postThink")
	}
}

public fwdPlayerSpawn(id) {
	if(is_user_alive(id)) {
		g_bAlive[id]=true
		set_pev(id,pev_solid,SOLID_SLIDEBOX)
	}
}

public fwdPlayerKilled(id) {
	g_bAlive[id]=false
}

public preThink(id) {
	if(!g_bAlive[id]) return

	set_pev(id,pev_solid,SOLID_SLIDEBOX)
}

public postThink(id) {
	if(!g_bAlive[id]) return

	g_pTR2=create_tr2()
 
	static Float:start[3],Float:end[3],Float:endpos[3]
	pev(id,pev_origin,start)
	pev(g_iCurTerr,pev_origin,end)

	engfunc(EngFunc_TraceLine,start,end,IGNORE_MONSTERS,id,g_pTR2)

	get_tr2(g_pTR2,TR_vecEndPos,endpos)

	free_tr2(g_pTR2)

	if(!xs_vec_equal(end,endpos)) {
		set_pev(id,pev_solid,SOLID_NOT)
	}
}
