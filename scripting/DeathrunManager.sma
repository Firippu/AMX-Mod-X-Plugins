
#include <amxmodx>
#include <round_terminator>
#include <hamsandwich>
#include <engine>
#include <nvault>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <xs>

#define VERSION "0.0.1"

#define MAX_WARMUP_TIME 15

#define OFFSET_LAST_MOVEMENT 124
#define OFFSET_PRIMARYWEAPON 116

#define DEATHRUN_PREFIX "[DeathRun]"
#define AWARDSYS_PREFIX "[A_S]"

#define STAGE_WARMUP 0
#define STAGE_ACTIVE 2

#define TICK 1.0
#define FRAG_LIMIT 100

new g_szTick_Thinker[]="tick_thinker"

new g_szIdentifier[33][35]
new g_iFrags[33]

new g_iVault
new g_iMsgScoreInfo
new const g_szFrag_Vault[] = "frag_save"

new g_iCurrentAward[33]

new g_iMaxPlayers

new g_GameStage=STAGE_WARMUP

new bool:g_bAlive[33]

new Float:g_flGameTime

new g_pTR2

new g_iWarmUpTimer,
	g_iCurTerr,
	g_pAutoBalance,
	g_pLimitTeams

new g_pCvar_AS_GravityCost,
	g_pCvar_AS_GravityAmount,
	g_pCvar_AS_SpeedCost,
	g_pCvar_AS_SpeedAmount,
	g_pCvar_AS_StealthCost,
	g_pCvar_AS_StealthAmount,
	g_pCvar_AS_HealthCost,
	g_pCvar_AS_HealthAmount

new g_ExtraLifes[33]

new g_CvarAFKTime

new g_iStuckTick
new g_iAFKTick

public plugin_init() {
	register_plugin("DeathRun",VERSION,"Firippu")

	g_pAutoBalance=get_cvar_pointer("mp_autoteambalance")
	g_pLimitTeams=get_cvar_pointer("mp_limitteams")

	register_forward(FM_ClientKill,"FwdClientKill")
	RegisterHam(Ham_TakeDamage,"player","FwdHamPlayerDamage")

	RegisterHam(Ham_Killed,"player","fwdPlayerKilled",1)
	RegisterHam(Ham_Spawn,"player","fwdPlayerSpawn",1)

	register_logevent("eNewRound",2,"1=Round_Start")

	set_cvar_num("mp_freezetime",0)

	g_pCvar_AS_GravityCost = register_cvar("amx_gravity_cost","4")
	g_pCvar_AS_GravityAmount = register_cvar("amx_gravity_amount","0.7")

	g_pCvar_AS_SpeedCost = register_cvar("amx_speed_cost","6")
	g_pCvar_AS_SpeedAmount = register_cvar("amx_speed_amount","300.0")

	g_pCvar_AS_StealthCost = register_cvar("amx_stealth_cost","5")
	g_pCvar_AS_StealthAmount = register_cvar("amx_stealth_amount","50")

	g_pCvar_AS_HealthCost = register_cvar("amx_health_cost","5")
	g_pCvar_AS_HealthAmount = register_cvar("amx_health_amount","50")

	g_CvarAFKTime = register_cvar("afk_time","60.0")

	new iEntity
	if((iEntity = create_entity("info_target"))) {
		entity_set_string(iEntity,EV_SZ_classname,g_szTick_Thinker)
		g_flGameTime=get_gametime()
		entity_set_float(iEntity,EV_FL_nextthink,g_flGameTime + 10.0)
		register_think(g_szTick_Thinker,"Ticker")
	}

	g_iMaxPlayers = get_maxplayers()

	register_event("ScoreInfo","fwEvScoreInfo","a")

	g_iMsgScoreInfo = get_user_msgid("ScoreInfo")

	register_clcmd("say /awards","fnAward_System_Menu")
	register_clcmd("say awards","fnAward_System_Menu")
	register_clcmd("awards","fnAward_System_Menu")
	register_event("CurWeapon","speedb","be","1=1")

	register_forward(FM_PlayerPreThink, "preThink")
	register_forward(FM_PlayerPostThink, "postThink")
}

public Ticker(iEntity) {
	g_flGameTime=get_gametime()

	switch(g_GameStage) {
		case STAGE_ACTIVE: {
			g_iStuckTick++
			if(g_iStuckTick>=5) {
				g_iStuckTick=0
				for(new id=1; id<=g_iMaxPlayers; id++) {
					if(g_bAlive[id]) {
						if(bPlayerStuck(id)) {
							//client_print(0,print_chat,"[DEBUG] Player %d got stuck.",id)
							//log_amx("[DEBUG] Player %d is stuck.",id)
							user_silentkill(id)
						}
					}
				}
			}

			g_iAFKTick++
			if(g_iAFKTick>=get_pcvar_float(g_CvarAFKTime)) {
				g_iAFKTick=0
				new Float:afk_time = get_pcvar_float(g_CvarAFKTime)
				new i,Float:lastActivity 
				afk_time-=g_flGameTime
				for(i=1; i<=g_iMaxPlayers; i++) {
					if(is_user_alive(i)) {
						lastActivity = get_pdata_float(i, OFFSET_LAST_MOVEMENT)
						if(lastActivity < afk_time) {
							server_cmd("kick #%d  AFK",get_user_userid(i))
						}
					}
				}
			}
		} case STAGE_WARMUP: {
			g_iWarmUpTimer--
			if(g_iWarmUpTimer<=0) {
				g_iWarmUpTimer=MAX_WARMUP_TIME
				if(iInTeamNum()>=2) {
					g_GameStage=STAGE_ACTIVE
					DisplayHudMsg("Starting")
					TerminateRound(RoundEndType_Draw)
				} else {
					DisplayHudMsg("Need More Players")
				}
			} else {
				static string[16]
				format(string,15,"Starting in %d",g_iWarmUpTimer)
				DisplayHudMsg(string)
			}
		}
	}

	entity_set_float(iEntity,EV_FL_nextthink,g_flGameTime + TICK)
}

public LifeMenu(id) {
	new menu = menu_create("\rLife Menu:","life_menu_handler")
	menu_additem(menu,"\wUse Extra Life","1",0)
	menu_additem(menu,"\wNo Not Use","2",0)
	menu_setprop(menu,MPROP_EXIT,MEXIT_ALL)
	menu_display(id,menu,0)
}

public life_menu_handler(id,menu,item) {
	if(item == MENU_EXIT) {
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	new data[6],szName[64]
	new access,callback

	menu_item_getinfo(menu,item,access,data,charsmax(data),szName,charsmax(szName),callback)

	new key = str_to_num(data)

	switch(key) {
		case 1: {
			if(!is_user_alive(id) && g_GameStage==STAGE_ACTIVE) {
				ExecuteHam(Ham_CS_RoundRespawn,id)
				g_ExtraLifes[id]--
				static szPlayerName[32]
				get_user_name(id,szPlayerName,31)
				client_print(0,print_chat,"%s %s used an extra life.",DEATHRUN_PREFIX,szPlayerName)
				client_print(id,print_chat,"%s You have %d lives left.",DEATHRUN_PREFIX,g_ExtraLifes[id])
				menu_destroy(menu)
				return PLUGIN_HANDLED
			}
		} case 2: {
			
		} default: {
			return PLUGIN_HANDLED
		}
	}

	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public client_command(client) {
	static const szJoinCommand[]="jointeam"

	static szCommand[10]
	read_argv(0,szCommand,9)

	if(equal(szCommand,szJoinCommand) && g_GameStage==STAGE_ACTIVE && cs_get_user_team(client)==CS_TEAM_T) {
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public FwdClientKill(const id) {
	if(!is_user_alive(id))
		return FMRES_IGNORED

	if(cs_get_user_team(id)==CS_TEAM_T) {
		return FMRES_SUPERCEDE
	}

	return FMRES_IGNORED
}

public FwdHamPlayerDamage(id,idInflictor,idAttacker,Float:flDamage,iDamageBits) {
	static szPlayerName[32]
	get_user_name(id,szPlayerName,31)

	if(iDamageBits & DMG_FALL) {
		if(get_user_team(id)==1) {
			return HAM_SUPERCEDE
		}
	}

	return HAM_IGNORED
}

public DisplayHudMsg(szMessage[]) {
	set_hudmessage(255,200,255,0.08,0.75,0,6.0,1.0,1.0,1.0)
	show_hudmessage(0,szMessage)
}

public fwdPlayerSpawn(iPlayer) {
	if(is_user_alive(iPlayer)) {
		switch(g_iCurrentAward[iPlayer]) {
			case 1: {
				client_print(iPlayer,print_chat,"%s Gravity set back to normal!",AWARDSYS_PREFIX)
			} case 2: {
				client_print(iPlayer,print_chat,"%s Speed set back to normal!",AWARDSYS_PREFIX)
			} case 3: {
				set_user_rendering(iPlayer,kRenderFxNone,255,255,255,kRenderNormal,16)
				set_user_footsteps(iPlayer,0)

				client_print(iPlayer,print_chat,"%s Stealth level set back to normal!",AWARDSYS_PREFIX)
			}
		}

		g_iCurrentAward[iPlayer]=0

		g_bAlive[iPlayer]=true
		set_pev(iPlayer, pev_solid, SOLID_SLIDEBOX)
		set_rendering(iPlayer,kRenderFxNone,0,0,0,kRenderTransTexture,150)

		strip_user_weapons(iPlayer)
		set_pdata_int(iPlayer,OFFSET_PRIMARYWEAPON,0)
		give_item(iPlayer,"weapon_knife")

		if(g_GameStage!=STAGE_WARMUP) {
			if(cs_get_user_team(iPlayer)==CS_TEAM_T && g_GameStage==STAGE_ACTIVE && g_iCurTerr!=iPlayer) {
				cs_set_user_team(iPlayer,CS_TEAM_CT)
				ExecuteHam(Ham_CS_RoundRespawn,iPlayer)
			}
		}
	}
}

public eNewRound() {
	set_pcvar_num(g_pAutoBalance,0)
	set_pcvar_num(g_pLimitTeams,0)

	for(new iPlayer=1; iPlayer<=g_iMaxPlayers; iPlayer++) {
		if(is_user_alive(iPlayer)) {
			if(g_ExtraLifes[iPlayer]) {
				client_print(iPlayer,print_chat,"%s You have %d extra lives.",DEATHRUN_PREFIX,g_ExtraLifes[iPlayer])
			}
		}
	}

	if(g_GameStage==STAGE_ACTIVE) {
		new id,iAlivePlayer_Num,iAlivePlayer_ID[33]
		for(id=1; id<=g_iMaxPlayers; id++) {
			if(is_user_connected(id)) {
				if(bPlayerInTeam(id) && is_user_alive(id) && id!=g_iCurTerr) {
					iAlivePlayer_ID[iAlivePlayer_Num]=id
					iAlivePlayer_Num++
				}
			}
		}

		if(iAlivePlayer_Num) {
			for(new i=1; i<=g_iMaxPlayers; i++) {
				if(is_user_alive(i)) {
					cs_set_user_team(i,CS_TEAM_CT)
					ExecuteHam(Ham_CS_RoundRespawn,i)
				}
			}

			new iNewTE=iAlivePlayer_ID[random(iAlivePlayer_Num)]
			cs_set_user_team(iNewTE,CS_TEAM_T)
			g_iCurTerr=iNewTE
			ExecuteHam(Ham_CS_RoundRespawn,iNewTE)

			set_rendering(iNewTE,kRenderFxNone,0,0,0,kRenderTransTexture,255)

			DisplayHudMsg("Game Active")
		} else {
			g_GameStage=STAGE_WARMUP
		}
	}
}

public client_disconnect(iPlayer) {
	if(g_iFrags[iPlayer]) {
		if(g_iFrags[iPlayer]>FRAG_LIMIT) {
			g_iFrags[iPlayer]=FRAG_LIMIT
		}

		new szFrags[6]
		num_to_str(g_iFrags[iPlayer],szFrags,5)

		nvault_set(g_iVault,g_szIdentifier[iPlayer],szFrags)
	}

	g_iFrags[iPlayer]=0
	g_ExtraLifes[iPlayer]=0
	g_iCurrentAward[iPlayer]=0
	g_szIdentifier[iPlayer][0]='^0'
	g_bAlive[iPlayer]=false

	set_task(1.0,"AfterDisconnect",iPlayer)
}

public AfterDisconnect(iPlayer) {
	if(g_GameStage==STAGE_ACTIVE) {
		new id,iAliveCT_Num,iAliveCT_ID[33],iDeadCT_Num
		for(id=1; id<=g_iMaxPlayers; id++) {
			if(is_user_connected(id)) {
				if((cs_get_user_team(id)==CS_TEAM_CT) && iPlayer!=id) {
					if(is_user_alive(id)) {
						iAliveCT_ID[iAliveCT_Num]=id
						iAliveCT_Num++
					} else {
						iDeadCT_Num++
					}
				}
			}
		}

		if(g_iCurTerr==iPlayer && get_timeleft()>10) {
			if(iAliveCT_Num>1) {
				static Float:vOrigin[3],Float:vVelocity[3]

				entity_get_vector(iPlayer,EV_VEC_origin,vOrigin)
				entity_get_vector(iPlayer,EV_VEC_velocity,vVelocity)

				new iNewTE=iAliveCT_ID[random(iAliveCT_Num)]

				cs_set_user_team(iNewTE,CS_TEAM_T)

				entity_set_origin(iNewTE,vOrigin)
				set_user_velocity(iNewTE,vVelocity)

				set_pev(iNewTE, pev_solid, SOLID_SLIDEBOX)
				set_rendering(iNewTE,kRenderFxNone,0,0,0,kRenderTransTexture,255)

				g_iCurTerr=iNewTE

				DisplayHudMsg("Terrorist left; appointed new one.")
			} else {
				g_GameStage=STAGE_WARMUP
			}
		}

		if(!iAliveCT_Num) {
			if(!iDeadCT_Num) {
				g_GameStage=STAGE_WARMUP
			} else {
				TerminateRound(RoundEndType_TeamExtermination,TeamWinning_Terrorist)
			}
		}
	}

	if(g_iCurTerr==iPlayer) {
		g_iCurTerr=0
	}
}

public client_connect(id) {
	g_iFrags[id]=0
	g_szIdentifier[id][0]='^0'
}

public client_putinserver(iPlayer) {
	get_user_authid(iPlayer,g_szIdentifier[iPlayer],31)

	if(!IsValidSteamID(g_szIdentifier[iPlayer])) {
		get_user_ip(iPlayer,g_szIdentifier[iPlayer],31,1)
	}

	new iFrags = nvault_get(g_iVault,g_szIdentifier[iPlayer])

	if(iFrags) {
		if(iFrags>FRAG_LIMIT) {
			iFrags=FRAG_LIMIT
		}

		g_iFrags[iPlayer] = iFrags
		set_user_frags(iPlayer,iFrags)
	}

	cs_set_user_team(iPlayer,CS_TEAM_UNASSIGNED)
}

public iAliveCTNum() {
	new iReturnNum
	for(new id=1; id<g_iMaxPlayers; id++) {
		if(is_user_alive(id)) {
			if(cs_get_user_team(id)==CS_TEAM_CT) {
				iReturnNum++
			}
		}
	}

	return iReturnNum
}

public iDeadCTNum() {
	new iReturnNum
	for(new id=1; id<g_iMaxPlayers; id++) {
		if(is_user_connected(id) && !is_user_alive(id)) {
			if(cs_get_user_team(id)==CS_TEAM_CT) {
				iReturnNum++
			}
		}
	}

	return iReturnNum
}

public iInTeamNum() {
	new iReturnNum
	for(new id=1; id<g_iMaxPlayers; id++) {
		if(is_user_connected(id)) {
			if(bPlayerInTeam(id)) {
				iReturnNum++
			}
		}
	}

	return iReturnNum
}

public fwdPlayerKilled(iVictim,iKiller) {
	g_bAlive[iVictim]=false
	switch(g_GameStage) {
		case STAGE_ACTIVE: {
			if(g_iCurTerr==iVictim) {
				DisplayHudMsg("Counter Terrorist Wins")
				TerminateRound(RoundEndType_TeamExtermination,TeamWinning_Ct)

				if(is_user_connected(iKiller)) {
					g_ExtraLifes[iKiller]++
					client_print(iKiller,print_chat,"%s You gained an extra life!",DEATHRUN_PREFIX)
				}
			} else {
				if(!iAliveCTNum()) {
					DisplayHudMsg("Terrorist Wins")
					TerminateRound(RoundEndType_TeamExtermination,TeamWinning_Terrorist)

					//g_ExtraLifes[g_iCurTerr]++
					//client_print(g_iCurTerr,print_chat,"%s You gained an extra life!",DEATHRUN_PREFIX)

					g_iFrags[g_iCurTerr]+=3
					if(g_iFrags[g_iCurTerr]>FRAG_LIMIT) {
						g_iFrags[g_iCurTerr]=FRAG_LIMIT
					}

					set_user_frags(g_iCurTerr,g_iFrags[g_iCurTerr])
					cmdUpdateScoreBoard(g_iCurTerr)

					client_print(g_iCurTerr,print_chat,"%s Frags increased by 3",DEATHRUN_PREFIX)
				} else {
					if(g_ExtraLifes[iVictim]) {
						LifeMenu(iVictim)
					}
				}
			}
		} case STAGE_WARMUP: {
			ExecuteHam(Ham_CS_RoundRespawn,iVictim)
		}
	}
}

bool:IsValidSteamID(const szSteamID[]) {
	return(('0'<=szSteamID[8]<='1') && szSteamID[9]==':' && equal(szSteamID,"STEAM_0:",8) && is_str_num(szSteamID[10]) && strlen(szSteamID)<=18)
}

public bool:bPlayerInTeam(iPlayer) {
	switch(cs_get_user_team(iPlayer)) {
		case 1..2: {
			return true
		}
	}

	return false
}

public plugin_precache() {
	new Entity = create_entity("info_map_parameters")

	DispatchKeyValue(Entity,"buying","3")
	DispatchSpawn(Entity)
}

public pfn_keyvalue(Entity) {
	new ClassName[20],Dummy[2]
	copy_keyvalue(ClassName,charsmax(ClassName),Dummy,charsmax(Dummy),Dummy,charsmax(Dummy))

	if(equal(ClassName,"info_map_parameters")) {
		remove_entity(Entity)
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public plugin_cfg() {
	g_iVault = nvault_open(g_szFrag_Vault)

	if(g_iVault == INVALID_HANDLE) {
		set_fail_state("Error opening nVault")
	}
}

public plugin_end() {
	nvault_close(g_iVault)
}

public fwEvScoreInfo() {
	new id = read_data(1)
	if(is_user_connected(id)) {
		new iFrags = read_data(2)

		//The server resets scores at mapchange so this will set the players score [if g_iFrags[] > 0].
		if(!iFrags && g_iFrags[id]) {
			set_user_frags(id,g_iFrags[id])
		} else {
			if(iFrags>FRAG_LIMIT) {
				iFrags=FRAG_LIMIT
				client_print(id,print_chat,"%s Your total amount of frags is maxed out, consider buying awards. Type /awards",AWARDSYS_PREFIX)
			}

			g_iFrags[id] = iFrags
		}
	}
}

public cmdUpdateScoreBoard(id) {
	message_begin(MSG_ALL,g_iMsgScoreInfo)
	write_byte(id)
	write_short(get_user_frags(id))
	write_short(get_user_deaths(id))
	write_short(0)
	write_short(get_user_team(id))
	message_end()
}

public AddMenuItem(menu,Label[],Price,Num[]) {
	new szLabel[16]
	new szNum[2]

	add(szLabel,15,"\w")
	add(szLabel,15,Label)
	add(szLabel,15," (")
	get_pcvar_string(Price,szNum,1)
	add(szLabel,15,szNum)
	add(szLabel,15,")")

	menu_additem(menu,szLabel,Num,0)
}

public fnAward_System_Menu(id) {
	new menu = menu_create("\rAward System Menu:","award_system_menu_handler")

	AddMenuItem(menu,"Gravity",g_pCvar_AS_GravityCost,"1")
	AddMenuItem(menu,"Speed",g_pCvar_AS_SpeedCost,"2")
	AddMenuItem(menu,"Stealth",g_pCvar_AS_StealthCost,"3")
	AddMenuItem(menu,"Health",g_pCvar_AS_HealthCost,"4")

	menu_setprop(menu,MPROP_EXIT,MEXIT_ALL)
	menu_display(id,menu,0)
}

public award_system_menu_handler(id,menu,item) {
	if(item == MENU_EXIT) {
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	if(!g_bAlive[id]) {
		client_print(id,print_chat,"%s You cannot use Awards System when dead.",AWARDSYS_PREFIX)
		return PLUGIN_HANDLED
	}

	if(id==g_iCurTerr) {
		client_print(id,print_chat,"%s Terrorist cannot buy awards.",AWARDSYS_PREFIX)
		return PLUGIN_HANDLED
	}

	if(g_iCurrentAward[id]) {
		client_print(id,print_chat,"%s You already have an award.",AWARDSYS_PREFIX)
		return PLUGIN_HANDLED
	}

	new iFrags = get_user_frags(id)

	new data[6],szName[64]
	new access,callback

	menu_item_getinfo(menu,item,access,data,charsmax(data),szName,charsmax(szName),callback)

	new iKey = str_to_num(data)

	new iItemCost
	switch(iKey) {
		case 1: {
			if(iFrags>=(iItemCost=get_pcvar_num(g_pCvar_AS_GravityCost))) {
				set_user_gravity(id,get_pcvar_float(g_pCvar_AS_GravityAmount))
				g_iFrags[id]-=iItemCost
			}
		} case 2: {
			if(iFrags>=(iItemCost=get_pcvar_num(g_pCvar_AS_SpeedCost))) {
				new Float:speed = get_user_maxspeed(id) + get_pcvar_float(g_pCvar_AS_SpeedAmount)
				set_user_maxspeed(id,speed)
				g_iFrags[id]-=iItemCost
			}
		} case 3: {
			if(iFrags>=(iItemCost=get_pcvar_num(g_pCvar_AS_StealthCost))) {
				set_rendering(id,kRenderFxNone,0,0,0,kRenderTransTexture,get_pcvar_num(g_pCvar_AS_StealthAmount))
				set_user_footsteps(id,1)
				g_iFrags[id]-=iItemCost
			}
		} case 4: {
			if(iFrags>=(iItemCost=get_pcvar_num(g_pCvar_AS_HealthCost))) {
				set_user_health(id,get_user_health(id) + get_pcvar_num(g_pCvar_AS_HealthAmount))
				g_iFrags[id]-=iItemCost
			}
		} default: {
			return PLUGIN_HANDLED
		}
	}

	if(iFrags==g_iFrags[id]) {
		client_print(id,print_chat,"%s You don't have enough frags.",AWARDSYS_PREFIX)
		return PLUGIN_HANDLED
	}

	g_iCurrentAward[id]=iKey
	set_user_frags(id,g_iFrags[id])
	cmdUpdateScoreBoard(id)
	client_print(id,print_chat,"%s Award Bought",AWARDSYS_PREFIX)

	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public speedb(id) {
	if(g_iCurrentAward[id] == 2) {
		new Float:speed = get_user_maxspeed(id) + get_pcvar_float(g_pCvar_AS_SpeedAmount)
		set_user_maxspeed(id,speed)
	}
}

public preThink(id) {
	if(g_iCurTerr==id || !g_bAlive[id]) {
		return
	}

	set_pev(id,pev_solid,SOLID_SLIDEBOX)
}

public postThink(id) {
	if(g_iCurTerr==id || !g_bAlive[id]) {
		return
	}

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

public bool:bPlayerStuck(id) { 
	static Float:originF[3]
	pev(id,pev_origin,originF)

	engfunc(EngFunc_TraceHull,originF,originF,0,(pev(id,pev_flags) & FL_DUCKING) ? HULL_HEAD:HULL_HUMAN,id,0)

	if(get_tr2(0,TR_StartSolid) || get_tr2(0,TR_AllSolid) || !get_tr2(0,TR_InOpen)) {
		return true
	}

	return false
}
