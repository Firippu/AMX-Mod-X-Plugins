/*
	description:
		Creates trigger_push between the team sides, preventing both teams from rushing to the other sides.
		After some time, the trigger_push will become ineffective, allows the teams to reach the other side if needed.

	cvars:
		akcolt_delay <number>  // Amount of seconds path will remain blocked
*/

#include <amxmodx>
#include <engine>

#define PUSH_SPEED "250"

new g_iSeconds

new g_pCvar_OPENTIME

new const g_szThinkEntClass[] = "akcoltEnforcer"

new g_iTEPush,
	g_iCTPush,
	g_iThinkEnt

public plugin_init() {
	register_plugin("akcoltEnforcer","0.2","Firippu")

	new szMapName[13]
	get_mapname(szMapName,12)

	if(equali(szMapName,"aim_ak-colt")) {
		g_iTEPush=fnCreateTriggerPush(PUSH_SPEED,"0 -90 0",Float:{-256.0,-960.0,0.0},Float:{1792.0,-768.0,64.0})
		g_iCTPush=fnCreateTriggerPush(PUSH_SPEED,"0 90 0",Float:{-256.0,-768.0,0.0},Float:{1792.0,-576.0,64.0})

		register_logevent("eNewRound",2,"1=Round_Start")

		g_pCvar_OPENTIME = register_cvar("akcolt_delay","60")

		g_iThinkEnt = create_entity("info_target")
		entity_set_string(g_iThinkEnt,EV_SZ_classname,g_szThinkEntClass)
		register_think(g_szThinkEntClass,"Forward_Think")
	}
}

public fnCreateTriggerPush(szSpeed[],szAngles[],Float:Mins[3],Float:Maxs[3]) {
	new iEntity
	if((iEntity=create_entity("trigger_push"))) {
		DispatchKeyValue(iEntity,"angles",szAngles)
		DispatchKeyValue(iEntity,"speed",szSpeed)
		DispatchSpawn(iEntity)
		entity_set_size(iEntity,Mins,Maxs)
	}

	return iEntity
}

public eNewRound() {
	g_iSeconds=get_pcvar_num(g_pCvar_OPENTIME)
	entity_set_float(g_iThinkEnt,EV_FL_nextthink,get_gametime() + 1.0)
	DispatchKeyValue(g_iTEPush,"speed",PUSH_SPEED)
	DispatchKeyValue(g_iCTPush,"speed",PUSH_SPEED)
}

public Forward_Think(g_iThinkEnt) {
	g_iSeconds--
	if(g_iSeconds<=0) {
		DispatchKeyValue(g_iTEPush,"speed","0")
		DispatchKeyValue(g_iCTPush,"speed","0")
		client_print(0,print_chat,"path has opened")

		return PLUGIN_HANDLED
	}

	if((g_iSeconds % 1 == 0 && g_iSeconds % 10 == 0) || g_iSeconds==5)
		client_print(0,print_chat,"path will open in %d seconds",g_iSeconds)

	entity_set_float(g_iThinkEnt,EV_FL_nextthink,get_gametime() + 1.0)
	return PLUGIN_CONTINUE
}
