
#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <secondsleft>


new bool:bPushDisabled

#define PUSH_SPEED "250"

new g_iSeconds

new Classname[] = "akcoltEnforcer";

new g_iTPush
new g_iCTPush

public plugin_init() {
	register_plugin("akcoltEnforcer","0.1","Firippu")

	new szMapName[13]
	get_mapname(szMapName,12)

	if(equali(szMapName,"aim_ak-colt")
	|| equali(szMapName,"aim_ak_colt")) {
		g_iTPush=fnCreateTriggerPush(PUSH_SPEED,"0 -90 0",Float:{-256.0,-960.0,0.0},Float:{1792.0,-768.0,64.0})
		g_iCTPush=fnCreateTriggerPush(PUSH_SPEED,"0 90 0",Float:{-256.0,-768.0,0.0},Float:{1792.0,-576.0,64.0})

		register_logevent("eNewRound",2,"1=Round_Start")

		new Ent = create_entity("info_target")
		entity_set_string(Ent,EV_SZ_classname,Classname)
		entity_set_float(Ent,EV_FL_nextthink,get_gametime() + 1.0)
		register_think(Classname,"Forward_Think")
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
	bPushDisabled = false

	g_iSeconds=115

	DispatchKeyValue(g_iTPush,"speed",PUSH_SPEED)
	DispatchKeyValue(g_iCTPush,"speed",PUSH_SPEED)
}

public Forward_Think(Ent) {
		static TimeLeft

		TimeLeft=get_remaining_seconds()

		client_print(0,print_chat,"%d",TimeLeft)
	if(!bPushDisabled) {

		if(g_iSeconds == TimeLeft) {
			bPushDisabled=true
			DispatchKeyValue(g_iTPush,"speed","0")
			DispatchKeyValue(g_iCTPush,"speed","0")
			client_print(0,print_chat,"opened")
		}
	}

	entity_set_float(Ent,EV_FL_nextthink,get_gametime() + 1.0)
}
