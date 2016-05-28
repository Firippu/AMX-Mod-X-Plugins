#include <amxmodx>
#include <hamsandwich>
#include <cstrike>
#include <engine>

new g_szTargetname[33]

public plugin_init() {
	register_plugin("deathrun_fixes1","0.0.5","Firippu")

	new szMapName[33]
	get_mapname(szMapName,32)

	if(equali(szMapName,"deathrun_baw")) {
		strcat(g_szTargetname,"brokenwheel",11)
		register_touch("player","func_door_rotating","fwdTouchedDoorRotating")
	} else if(equali(szMapName,"deathrun_extreme")) {
		strcat(g_szTargetname,"rummet",6)
		register_touch("player","func_door_rotating","fwdTouchedDoorRotating")
	} else if(equali(szMapName,"deathrun_cartoon")) {
		//fnCreateBlock(Float:{-384.0,1296.0,-1200.0},Float:{0.0,0.0,0.0},Float:{450.0,50.0,100.0})
		fnCreateTriggerHurt("100",Float:{-384.0,1296.0,-1344.0},Float:{32.0,1344.0,-1120.0})
	} else if(equali(szMapName,"deathrun_dojo")) {
		//fnCreateBlock(Float:{1480.0,-1856.0,-50.0},Float:{0.0,0.0,0.0},Float:{10.0,700.0,350.0})
		fnCreateTriggerHurt("100",Float:{1464.0,-1856.0,64.0},Float:{1520.0,-1176.0,344.0})
	} else if(equali(szMapName,"deathrun_temple")) {
		deathrun_temple()
		fnCreateTriggerPush("250","0 0 0",Float:{100.0,-230.0,-230.0},Float:{127.0,-170.0,-90.0})
		fnCreateTriggerPush("250","0 -90 0",Float:{289.0,129.0,-230.0},Float:{365.0,156.0,-90.0})
	} else if(equali(szMapName,"deathrun_projetocs")) {
		RegisterHam(Ham_Use,"func_button","fwdPlayerUse")
	} else if(equali(szMapName,"deathrun_forest")) {
		remove_entity(find_ent_by_model(-1,"func_water","*143"))
		fnCreateTriggerHurt("100",Float:{-1664.0,-704.0,-272.0},Float:{-1472.0,-256.0,-260.0})
	} else if(equali(szMapName,"deathrun_forest2_final")) {
		fnCreateTriggerPush("250","0 -90 0",Float:{784.0,1072.0,16.0},Float:{1568.0,1136.0,160.0})
	} else if(equali(szMapName,"deathrun_dust")) {
		deathrun_dust()
	} else if(equali(szMapName,"deathrun_wanderers")) {
		remove_entity(find_ent_by_model(-1,"trigger_push","*50"))
	} else if(equali(szMapName,"deathrun_alpin_spring")) {
		//fnSetEntHealth(find_ent_by_model(-1,"func_breakable","*6"),100.0)
		remove_entity(find_ent_by_model(-1,"func_breakable","*6"))
	}
}

public fnSetEntHealth(iEntity,Float:fHealth) {
	entity_set_float(iEntity,EV_FL_health,fHealth)
}

public fwdPlayerUse(iEntity,iPlayer) {
	if(cs_get_user_team(iPlayer) == CS_TEAM_CT) {
		static szTarget[7]
		entity_get_string(iEntity,EV_SZ_target,szTarget,6)
		if(!equal(szTarget,"final")) {
			return HAM_SUPERCEDE
		}
	}

	return HAM_IGNORED
}

/*
public fnCreateBlock(Float:Origin[3],Float:Mins[3],Float:Maxs[3]) {
	new iEntity=create_entity("info_target")

	entity_set_int(iEntity,EV_INT_solid,SOLID_BBOX);
	entity_set_model(iEntity,"models/null.mdl")
	entity_set_size(iEntity,Mins,Maxs)
	entity_set_origin(iEntity,Origin)
}

public plugin_precache() {
    precache_model("models/null.mdl")
}
*/

public deathrun_dust() {
	new iEntity
	while((iEntity = find_ent_by_class(iEntity,"func_pushable")) != 0) {
		entity_set_int(iEntity,EV_INT_movetype,MOVETYPE_NONE)
	}
}

public deathrun_temple() {
	new iEntity
	for(new i=0; i<2; i++) {
		iEntity=find_ent_by_tname(iEntity,"brolucka")
		static Float:vOrigin[3]
		entity_get_vector(iEntity,EV_VEC_origin,vOrigin)

		if(i == 0) {
			vOrigin[1] += 6.0
		} else {
			vOrigin[1] -= 6.0
		}

		entity_set_origin(iEntity,vOrigin)
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
}

public fnCreateTriggerHurt(szDamage[],Float:Mins[3],Float:Maxs[3]) {
	new iEntity
	if((iEntity=create_entity("trigger_hurt"))) {
		DispatchKeyValue(iEntity,"dmg",szDamage)
		DispatchSpawn(iEntity)
		entity_set_size(iEntity,Mins,Maxs)
	}
}

public fwdTouchedDoorRotating(iPlayer,iEntity) {
	static szTargetname[33]
	entity_get_string(iEntity,EV_SZ_targetname,szTargetname,32)
	if(equal(szTargetname,g_szTargetname)) {
		if(entity_get_int(iPlayer,EV_INT_button) & IN_DUCK) {
			client_cmd(iPlayer,"-duck")
		}
	}
}
