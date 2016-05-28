/*
Fixes for following maps:
	jail_204jailbreak_v1
	jail_zow_2towers
	jail_zow_carlbase
	jail_zow_dp
	jail_zow_highsecurity
	jail_zow_penitentary_simple
	jail_zow_roflbase
	jail_zowxmas_applefoohy
	jb_revo_complex_v3e
	vc__jail1_final
	vc__jail_electric_large-b3
*/

#include <amxmodx>
#include <engine>

#define VERSION "1.1.0"

new const Float:vcJail1TESPAWNS[][3] = {
	{-940.0,-919.0,199.0},{-964.0,-622.0,189.0},{-983.0,-364.0,184.0},{-936.0,-123.0,190.0},
	{-948.0,-143.0,54.0},{-969.0,-363.0,41.0},{-931.0,-669.0,41.0},{-942.0,-901.0,49.0},
	{962.0,-666.0,210.0},{958.0,-131.0,199.0},{964.0,-399.0,194.0},{977.0,-907.0,185.0},
	{-943.0,121.0,184.0},{-934.0,393.0,185.0},{956.0,-912.0,67.0},{926.0,-637.0,48.0},
	{961.0,-410.0,56.0},{977.0,-113.0,51.0},{976.0,126.0,184.0},{962.0,421.0,185.0},
	{-961.0,397.0,60.0},{-978.0,126.0,52.0},{937.0,120.0,64.0},{939.0,403.0,75.0}
}

new const Float:vcElectricTESPAWNS[][3] = {
	// bottom cells
	{615.0,578.0,54.0},{615.0,450.0,54.0},{615.0,322.0,54.0},
	{615.0,194.0,54.0},{615.0,66.0,54.0},

	// top cells
	{615.0,578.0,189.0},{615.0,450.0,189.0},{615.0,322.0,189.0},
	{615.0,194.0,189.0},{615.0,66.0,189.0},

	// solitary
	{695.0,1041.0,54.0},

	// vip cell
	{600.0,-450.0,54.0},{540.0,-450.0,54.0},{720.0,-180.0,54.0},
	{720.0,-240.0,54.0},{430.0,-170.0,54.0},{430.0,-220.0,54.0},
	{530.0,-220.0,54.0},{600.0,-400.0,54.0},{540.0,-400.0,54.0},
	{430.0,-400.0,54.0},{600.0,-300.0,54.0},{540.0,-300.0,54.0},
	{430.0,-300.0,54.0}
}

public plugin_init() {
	register_plugin("jbMapPlugins",VERSION,"Firippu")

	new iTE,iEntity

	new pTeleport=register_cvar("vcjail1_tp","0")

	new szMapName[32]
	get_mapname(szMapName,31)

	if(equali(szMapName,"vc__jail1_final") && get_pcvar_num(pTeleport)) {
		if((iEntity=find_ent_in_sphere(iEntity,Float:{1067.0,-40.0,216.0},1.0))) {
			static Float:vOrigin[3]

			entity_get_vector(iEntity,EV_VEC_origin,vOrigin)

			remove_entity(iEntity)

			if((iEntity=create_entity("trigger_teleport"))) {
				entity_set_origin(iEntity,vOrigin)
				entity_set_string(iEntity,EV_SZ_target,"armoury_exit")
				DispatchSpawn(iEntity)
			}
		}
	}

	new iTotalEntities=entity_count()
	for(iEntity=0; iEntity<=iTotalEntities; iEntity++) {
		if(!is_valid_ent(iEntity)) {
			continue
		}

		static szTargetname[32],szClassname[32],szModel[32]

		entity_get_string(iEntity,EV_SZ_targetname,szTargetname,31)
		entity_get_string(iEntity,EV_SZ_classname,szClassname,31)
		entity_get_string(iEntity,EV_SZ_model,szModel,31)

		if(equali(szMapName,"vc__jail1_final")) {
			if(equal(szTargetname,"cellcontrol")) {
				entity_set_string(iEntity,EV_SZ_target,"cells")
			} else if(equal(szTargetname,"armory1") || equal(szTargetname,"armory2")) {
				entity_set_string(iEntity,EV_SZ_target,"arm")
			} else if(equal(szTargetname,"cellblocker")) {
				entity_set_string(iEntity,EV_SZ_targetname,"cells")
			} else if(equal(szTargetname,"armsecret")) {
				entity_set_string(iEntity,EV_SZ_target,"tele_entrance")
			} else if((containi(szTargetname,"block_") != -1) || equal(szTargetname,"cameraload") || equal(szTargetname,"mapcredits")) {
				remove_entity(iEntity)
			}

			if(equal(szClassname,"info_player_start")) {
				static Float:vOrigin[3]

				entity_get_vector(iEntity,EV_VEC_origin,vOrigin)

				vOrigin[0] += 680.0
				vOrigin[1] += -3800.0
				vOrigin[2] = 50.0

				entity_set_origin(iEntity,vOrigin)
			} else if(equal(szClassname,"info_player_deathmatch")) {
				entity_set_origin(iEntity,vcJail1TESPAWNS[iTE])
				iTE++
			}
		} else if(equali(szMapName,"vc__jail_electric_large-b3")) {
			if(containi(szTargetname,"block") != -1 || containi(szTargetname,"dwauiodwah") != -1 || equal(szTargetname,"mapcredits") || equal(szTargetname,"cameraload")) {
				remove_entity(iEntity)
			} else if(equal(szClassname,"info_player_start")) {
				static Float:vOrigin[3]

				entity_get_vector(iEntity,EV_VEC_origin,vOrigin)

				vOrigin[0] += 270.0
				vOrigin[1] += 1060.0
				vOrigin[2] = 100.0

				entity_set_origin(iEntity,vOrigin)
			} else if(equal(szClassname,"info_player_deathmatch")) {
				entity_set_origin(iEntity,vcElectricTESPAWNS[iTE])
				iTE++
			}
		} else if(equali(szMapName,"jail_zow_2towers") || equali(szMapName,"jail_zow_penitentary_simple") || equali(szMapName,"jail_zow_roflbase") || equali(szMapName,"jail_zow_dp")) {
			if(containi(szTargetname,"zow") != -1) {
				remove_entity(iEntity)
			}
		} else if(equali(szMapName,"jail_zowxmas_applefoohy")) {
			if(equal(szTargetname,"MerryXMasZBlock")) {
				remove_entity(iEntity)
			} else if(equal(szModel,"*181")) {
				remove_entity(iEntity)
			}
		} else if(equali(szMapName,"jail_zow_highsecurity")) {
			if(equal(szTargetname,"TightSecurity")) {
				remove_entity(iEntity)
			}
		} else if(equali(szMapName,"jail_zow_carlbase")) {
			if(equal(szTargetname,"zow_roflmap") || equal(szClassname,"trigger_hurt")) {
				remove_entity(iEntity)
			}
		} else if(equali(szMapName,"jail_204jailbreak_v1")) {
			if(equal(szTargetname,"coke") || equal(szTargetname,"pepsi") || equal(szTargetname,"fruittopia")) {
				remove_entity(iEntity)
			}
		} else if(equali(szMapName,"jb_revo_complex_v3e")) {
			if(equal(szTargetname,"dont-steal") || equal(szClassname,"trigger_hurt")) {
				remove_entity(iEntity)
			} else if(containi(szTargetname,"garagedoor") != -1) {
				entity_set_string(iEntity,EV_SZ_targetname,"garagecontrol")
			} else if(equal(szTargetname,"open_armoury")) {
				entity_set_string(iEntity,EV_SZ_target,"armoury1")
			} else if(equal(szTargetname,"cellcontrol")) {
				entity_set_string(iEntity,EV_SZ_target,"celldoor")
			} else if(equal(szTargetname,"antiglitch")) {
				entity_set_string(iEntity,EV_SZ_targetname,"celldoor")
			}
		}
	}
}
