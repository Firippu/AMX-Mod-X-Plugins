
#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_stocks>
#include <hamsandwich>
#include <dhudmessage>
#include <cstrike>
#include <fun>

#define VERSION "0.0.1"

#define OFFSET_PRIMARYWEAPON 116
#define OFFSET_SECONDARYWEAPON 117

#define m_rgAmmo_player_Slot0 376

#define OFFSET_NVGOGGLES 129
#define HAS_NVGOGGLES (1<<0)

#define PLAYERS_NEEDED 2

#define WARMUP_TIME 15
#define PREFIX "[ZE]"

#define PREGAME 0
#define PREPARE 1
#define UNFREEZ 2
#define INFECTD 3
#define RDENDED 4

new bool:g_bIsZombie[33]

new CsTeams:g_iTeamTouchedHelicopter

new g_RoundProgess=69
new g_iWarmUpTimer=0

new HideWeapon
new defusekit

new g_iMaxPlayers

new g_szModels[][] = {
	"models/zombie_escape/v_knife_tank_zombi.mdl",
	"models/player/tank_zombi_host/tank_zombi_host.mdl",
	"models/player/zombie_source/zombie_source.mdl",
	"models/player/zombie_nazi/zombie_nazi.mdl"
}

new g_szSoundsInfect[][] = {
	"sound/zombie_escape/ze_infect_001.wav",
	"sound/zombie_escape/ze_infect_002.wav",
	"sound/zombie_escape/ze_infect_003.wav"
}

new g_szSoundsAmbience[][] = {
	"sound/zombie_escape/ze_ambience_001.mp3",
	"sound/zombie_escape/ze_ambience_002.mp3"
}

new g_szSoundsZombieWin[][] = {
	"sound/zombie_escape/ze_zombie_win_001.wav",
	"sound/zombie_escape/ze_zombie_win_002.wav"
}

new g_szSoundsHumanWin[][] = {
	"sound/zombie_escape/ze_human_win_001.wav",
	"sound/zombie_escape/ze_human_win_002.wav"
}

new const g_szEnts2Remove[][] = {
	"func_bomb_target",
	"info_bomb_target",
	"info_vip_start",
	"func_vip_safetyzone",
	"func_escapezone",
	"hostage_entity",
	"monster_scientist",
	"func_hostage_rescue",
	"info_hostage_rescue",
	"item_longjump"
}

new g_fCvar_HSpeed,
	g_fCvar_ZSpeed,
	g_fCvar_ZHealth

public plugin_init() {
	register_plugin("ZombieEscape",VERSION,"Firippu")

	RegisterHam(Ham_Spawn,"player","fwdPlayerSpawn",1)

	RegisterHam(Ham_TakeDamage,"player","fwdTakeDmg",0)

	register_touch("weaponbox","player","fwdTouch")
	register_touch("armoury_entity","player","fwdTouch")

	RegisterHam(Ham_Killed,"player","fwdPlayerKilled",1)

	register_forward(FM_ClientKill,"FwdClientKill")

	set_cvar_num("mp_freezetime",0)
	
	g_iMaxPlayers = get_maxplayers()

	register_event("AmmoX","Event_AmmoX","be","2<200")

	g_fCvar_HSpeed = register_cvar("ze_hspeed","200.0")
	g_fCvar_ZSpeed = register_cvar("ze_zspeed","250.0")
	g_fCvar_ZHealth = register_cvar("ze_zhealth","10000")

	register_touch("func_tracktrain","player","fwdPlayerTouchedTrackTrain")

	register_clcmd("say !zspawn","cmdZombieSpawn")
	register_clcmd("say_team !zspawn","cmdZombieSpawn")

	RegisterHam(Ham_Use,"env_shake","EnvShakeCalled",1)

	register_event("CurWeapon","CurWeapon","be","1!0","2=29")
	HideWeapon = get_user_msgid("HideWeapon")

	new iEntity
	for(new i=0; i<sizeof g_szEnts2Remove; i++) {
		if((iEntity = find_ent_by_class(-1,g_szEnts2Remove[i]))) {
			remove_entity(iEntity)
		}
	}

	register_touch("player","func_tracktrain","fwdTouchedTrackTrain")

	StartWarmUp()

	register_logevent("NewRound",2,"1=Round_Start")
}

public KillAllCTs() {
	for(new iPlayer=1; iPlayer<=g_iMaxPlayers; iPlayer++) {
		if(is_user_alive(iPlayer)) {
			if(cs_get_user_team(iPlayer)==CS_TEAM_CT) {
				user_silentkill(iPlayer)
			}
		}
	}
}

public KillAllTEs() {
	for(new iPlayer=1; iPlayer<=g_iMaxPlayers; iPlayer++) {
		if(is_user_alive(iPlayer)) {
			if(cs_get_user_team(iPlayer)==CS_TEAM_T) {
				user_silentkill(iPlayer)
			}
		}
	}
}

public KillAll() {
	client_print(0,print_chat,"[DEBUG] KillAll Called 2")
	for(new iPlayer=1; iPlayer<=g_iMaxPlayers; iPlayer++) {
		if(is_user_alive(iPlayer)) {
			client_print(0,print_chat,"[DEBUG] KillAll Called 3")
			cs_set_user_deaths(iPlayer,(cs_get_user_deaths(iPlayer)-1))
			user_silentkill(iPlayer)
		}
	}
}

public FwdClientKill(const id) {
	if(!is_user_alive(id))
		return FMRES_IGNORED

	if(cs_get_user_team(id)==CS_TEAM_T) {
		return FMRES_SUPERCEDE
	}

	return FMRES_IGNORED
}

public fwdTouchedTrackTrain(iPlayer,iEntity) {
	if(entity_get_int(iPlayer,EV_INT_button) & IN_DUCK) {
		client_cmd(iPlayer,"-duck")
	}
}

public PlaySoundToClients(const sound[]) {
	if(equal(sound[strlen(sound)-4],".mp3")) {
		client_cmd(0,"mp3 play ^"sound/%s^"",sound)
	} else {
		client_cmd(0,"spk ^"%s^"",sound)
	}
}

public PlaySoundToClient(id,const sound[]) {
	if(equal(sound[strlen(sound)-4],".mp3")) {
		client_cmd(id,"mp3 play ^"sound/%s^"",sound)
	} else {
		client_cmd(id,"spk ^"%s^"",sound)
	}
}

public CurWeapon(id) {
	if(g_bIsZombie[id]) {
		message_begin(MSG_ONE_UNRELIABLE,HideWeapon,_,id)
		write_byte(1<<6)
		message_end()
	} else {
		message_begin(MSG_ONE_UNRELIABLE,HideWeapon,_,id)
		write_byte(0)
		message_end()
	}
}

public fwdPlayerTouchedTrackTrain(Touched,Toucher) {
	if(g_RoundProgess!=INFECTD) {
		return PLUGIN_HANDLED
	}

	if(!g_iTeamTouchedHelicopter) {
		static szTargetname[32]
		entity_get_string(Touched,EV_SZ_targetname,szTargetname,31)

		if(equal(szTargetname,"hel") || equal(szTargetname,"heliescape") || equal(szTargetname,"Vertolet") || equal(szTargetname,"qiqiu") || equal(szTargetname,"heli") || equal(szTargetname,"rescate_jp")) {
			g_iTeamTouchedHelicopter=cs_get_user_team(Toucher)
		}
	}

	return PLUGIN_CONTINUE
}

public EndRound(CsTeams:team) {
	if(g_RoundProgess!=RDENDED) {
		g_RoundProgess=RDENDED

		switch(team) {
			case CS_TEAM_T: {
				TeamWin("Zombies Win")
				PlaySoundToClients(g_szSoundsZombieWin[random_num(0,charsmax(g_szSoundsZombieWin))])
				KillAllCTs()
			} case CS_TEAM_CT: {
				TeamWin("Humans Win")
				PlaySoundToClients(g_szSoundsHumanWin[random_num(0,charsmax(g_szSoundsHumanWin))])
				KillAllTEs()
			} default: {
				TeamWin("Round Disrupted")
				KillAll()
			}
		}
	}
}

public EnvShakeCalled(ent) {
	if(g_RoundProgess!=RDENDED) {
		EndRound(g_iTeamTouchedHelicopter)
	}
}

public Event_AmmoX(id) {
	set_pdata_int(id,m_rgAmmo_player_Slot0 + read_data(1),200,5)
}

public cmdZombieSpawn(iPlayer) {
	if(!is_user_alive(iPlayer)) {
		if(bPlayerInTeam(iPlayer)) {
			ExecuteHam(Ham_CS_RoundRespawn,iPlayer)
		} else {
			client_print(iPlayer,print_chat,"%s You must be on a team.",PREFIX)
		}
	} else {
		client_print(iPlayer,print_chat,"%s You are already alive.",PREFIX)
	}
}

public NewRound() {
	if(g_RoundProgess!=PREPARE) {
		g_RoundProgess=PREPARE

		ResetTeams()

		if(GetInTeamNum()<PLAYERS_NEEDED) {
			StartWarmUp()
		} else {
			PrintHudMessage(3.0,"Prepare")
			set_task(5.0,"AfterPrepare")
		}
	}
}

public AfterPrepare() {
	g_RoundProgess=UNFREEZ

	for(new id=1; id<32; id++) {
		if(is_user_alive(id)) {
			set_pev(id,pev_flags,pev(id,pev_flags) & ~FL_FROZEN)
		}
	}

	if(GetInTeamNum()<PLAYERS_NEEDED) {
		StartWarmUp()
	} else {
		PrintHudMessage(3.0,"Go Go Go")
		set_task(10.0,"StartInfection")
	}
}

public client_disconnect(iPlayer) {
	set_task(1.0,"AfterDisconnect")
}

public AfterDisconnect() {
	if(g_RoundProgess!=PREGAME) {
		if(!iHumansLeft()) {
			EndRound(CS_TEAM_UNASSIGNED)
		}
	}

	if(g_RoundProgess==INFECTD) {
		if(!bZombiesLeft()) {
			EndRound(CS_TEAM_UNASSIGNED)
		}
	}
}

public StartWarmUp() {
	if(g_RoundProgess!=PREGAME) {
		g_RoundProgess=PREGAME
		g_iWarmUpTimer=0
		set_task(1.0,"fnWarmUpTimer")
	}
}

public fnWarmUpTimer() {
	if(g_RoundProgess==PREGAME) {
		if(g_iWarmUpTimer>=WARMUP_TIME) {
			g_iWarmUpTimer=0

			if(GetInTeamNum()<PLAYERS_NEEDED) {
				client_print(0,print_chat,"%s Need %d player(s) to start round.",PREFIX,PLAYERS_NEEDED)
				set_task(1.0,"fnWarmUpTimer")
			} else {
				client_print(0,print_chat,"[DEBUG] KillAll Called 1")
				KillAll()
			}
		} else {
			PrintHudMessage(1.0,"Warm-up Round")
			g_iWarmUpTimer++
			set_task(1.0,"fnWarmUpTimer")
		}
	}
}

public GetInTeamNum() {
	new num
	for(new id=1; id<32; id++) {
		if(is_user_connected(id)) {
			if(bPlayerInTeam(id)) {
				num++
			}
		}
	}

	return num
}

public fwdPlayerKilled(iPlayer) {
	if(g_RoundProgess==INFECTD) {
		switch(cs_get_user_team(iPlayer)) {
			case CS_TEAM_T: {
				if(!bZombiesLeft()) {
					EndRound(CS_TEAM_CT)
					return HAM_SUPERCEDE
				}
			} case CS_TEAM_CT: {
				if(!iHumansLeft()) {
					EndRound(CS_TEAM_T)
					return HAM_SUPERCEDE
				}
			}
		}
	}

	set_task(1.0,"fnRespawn",iPlayer)

	return HAM_IGNORED
}

public fnRespawn(iPlayer) {
	if(g_RoundProgess==INFECTD) {
		if(is_user_connected(iPlayer)) {
			ExecuteHam(Ham_CS_RoundRespawn,iPlayer)
		}
	}
}

public PrimaryWeaponMenu(id) {
	new menu = menu_create("\rPrimary Weapon Menu","primary_weapon_menu_handler")
	menu_setprop(menu,MPROP_EXIT,MEXIT_NEVER)

	menu_additem(menu,"M4A1","1",0)
	menu_additem(menu,"AK47","2",0)
	menu_additem(menu,"MP5","3",0)
	menu_additem(menu,"M249","4",0)
	menu_additem(menu,"M3","5",0)
	menu_additem(menu,"AUG","6",0)
	menu_additem(menu,"P90","7",0)
	menu_additem(menu,"SG552","8",0)

	menu_display(id,menu,0)
}

public primary_weapon_menu_handler(id,menu,item) {
	if(item<0) {
		return PLUGIN_HANDLED
	}

	if(item==MENU_EXIT) {
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	if(g_bIsZombie[id]) {
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	new data[6],szName[64]
	new access,callback

	menu_item_getinfo(menu,item,access,data,charsmax(data),szName,charsmax(szName),callback)

	new iKey = str_to_num(data)

	switch(iKey) {
		case 1: GivePlayerWeapon(id,"weapon_m4a1")
		case 2: GivePlayerWeapon(id,"weapon_ak47")
		case 3: GivePlayerWeapon(id,"weapon_mp5navy")
		case 4: GivePlayerWeapon(id,"weapon_m249")
		case 5: GivePlayerWeapon(id,"weapon_m3")
		case 6: GivePlayerWeapon(id,"weapon_aug")
		case 7: GivePlayerWeapon(id,"weapon_p90")
		case 8: GivePlayerWeapon(id,"weapon_sg552")
		default: return PLUGIN_HANDLED
	}

	set_task(0.1,"SecondaryWeaponMenu",id)

	return PLUGIN_HANDLED
}

public SecondaryWeaponMenu(id) {
	new menu = menu_create("\rSecondary Weapon Menu","secondary_weapon_menu_handler")
	menu_setprop(menu,MPROP_EXIT,MEXIT_NEVER)

	menu_additem(menu,"Deagle","1",0)
	menu_additem(menu,"Elite","2",0)
	menu_additem(menu,"FiveSeven","3",0)
	menu_additem(menu,"USP","4",0)
	menu_additem(menu,"P228","5",0)
	menu_additem(menu,"Glock","6",0)

	menu_display(id,menu,0)
}

public secondary_weapon_menu_handler(id,menu,item) {
	if(item<0) {
		return PLUGIN_HANDLED
	}

	if(item==MENU_EXIT) {
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	if(g_bIsZombie[id]) {
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	new data[6],szName[64]
	new access,callback

	menu_item_getinfo(menu,item,access,data,charsmax(data),szName,charsmax(szName),callback)

	new iKey = str_to_num(data)

	switch(iKey) {
		case 1: GivePlayerWeapon(id,"weapon_deagle")
		case 2: GivePlayerWeapon(id,"weapon_elite")
		case 3: GivePlayerWeapon(id,"weapon_fiveseven")
		case 4: GivePlayerWeapon(id,"weapon_usp")
		case 5: GivePlayerWeapon(id,"weapon_p228")
		case 6: GivePlayerWeapon(id,"weapon_glock18")
		default: return PLUGIN_HANDLED
	}

	return PLUGIN_HANDLED
}

GivePlayerWeapon(id,szWeapon[]) {
	for(new i=0; i<10; i++) {
		give_item(id,szWeapon)
	}
}

public fwdTouch(Touched,Toucher) {
	if(g_bIsZombie[Toucher]) {
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public GetAliveHumanNum() {
	new num
	for(new id=1; id<32; id++) {
		if(is_user_alive(id)) {
			if(!g_bIsZombie[id]) {
				num++
			}
		}
	}

	return num
}

public ResetTeams() {
	new iTeam=1
	for(new id=1; id<32; id++) {
		if(is_user_connected(id)) {
			if(bPlayerInTeam(id)) {
				if(iTeam==2) {
					iTeam=1
					cs_set_user_team(id,2)
				} else {
					iTeam=2
					cs_set_user_team(id,1)
				}

				g_bIsZombie[id]=false
			}
		}
	}

	g_iTeamTouchedHelicopter=CS_TEAM_UNASSIGNED
}

public bool:bPlayerInTeam(iPlayer) {
	switch(cs_get_user_team(iPlayer)) {
		case 1..2: {
			return true
		}
	}

	return false
}

public PrintHudMessage(Float:iSeconds,szMessage[]) {
	set_dhudmessage(0,160,0,-0.95,-0.25,2,6.0,iSeconds,0.1,1.5)
	show_dhudmessage(0,szMessage)
}

public StartInfection() {
	if(g_RoundProgess!=INFECTD) {
		g_RoundProgess=INFECTD

		new iPlayers[33],iPlayerCount
		for(new id=1; id<32; id++) {
			if(is_user_alive(id)) {
				iPlayers[iPlayerCount]=id
				iPlayerCount++
			}
		}

		if(iPlayerCount>0) {
			new FirstInfected=iPlayers[random_num(0,(iPlayerCount-1))]
			for(new id=1; id<32; id++) {
				if(is_user_alive(id)) {
					if(FirstInfected!=id) {
						cs_set_user_team(id,CS_TEAM_CT)
					}
				}
			}

			if(!g_bIsZombie[FirstInfected]) {
				PrintHudMessage(3.0,"Infection Started")
				InfectPlayer(FirstInfected,true)
			}
		} else {
			StartWarmUp()
		}
	}
}

public ShowHealthHUD(iPlayer) {
	set_hudmessage(255,0,0,0.20,0.90,0,6.0,320.0,1.0,1.0)
	show_hudmessage(iPlayer,"Health: %d",get_user_health(iPlayer))
}

public fwdTakeDmg(iVictim,iInflictor,iAttacker,Float:damage,damagebits) {
	if(g_RoundProgess!=INFECTD) {
		return HAM_SUPERCEDE
	}

	if(iVictim<=32 && iAttacker<=32 && iVictim!=0 && iAttacker!=0) {
		if(g_bIsZombie[iAttacker] && !g_bIsZombie[iVictim]) {
			message_begin(MSG_ALL,get_user_msgid("DeathMsg"),{0,0,0},0)
			write_byte(iAttacker)
			write_byte(iVictim)
			write_byte(0)
			write_string("knife")
			message_end()

			message_begin(MSG_ALL,get_user_msgid("ScoreAttrib"),{0,0,0},0)
			write_byte(iVictim)
			write_byte(0)
			message_end()

			set_user_frags(iAttacker,get_user_frags(iAttacker)+1)
			cmdUpdateScoreBoard(iAttacker)

			PlaySoundToClient(iVictim,g_szSoundsInfect[random_num(0,charsmax(g_szSoundsInfect))])
			PlaySoundToClient(iAttacker,g_szSoundsInfect[random_num(0,charsmax(g_szSoundsInfect))])

			

			if(iHumansLeft()>1) {
				InfectPlayer(iVictim,false)
			} else {
				EndRound(CS_TEAM_T)
			}

			return HAM_SUPERCEDE
		} else if(!g_bIsZombie[iAttacker] && g_bIsZombie[iVictim]) {
			static Float:aim_vec[3]
			velocity_by_aim(iAttacker,500,aim_vec)

			static Float:vict_vec[3]
			get_user_velocity(iVictim,vict_vec)

			vict_vec[0]-=(aim_vec[0]*-1)
			vict_vec[1]-=(aim_vec[1]*-1)

			set_user_velocity(iVictim,vict_vec)

			if(!bZombiesLeft()) {
				EndRound(CS_TEAM_T)
			}

			ShowHealthHUD(iVictim)
		}
	}

	return HAM_IGNORED
}

public TeamWin(szMessage[]) {
	client_print(0,print_chat,"%s",szMessage)
	PrintHudMessage(3.0,szMessage)
}

public iHumansLeft() {
	new num
	for(new id=1; id<32; id++) {
		if(is_user_alive(id)) {
			if(!g_bIsZombie[id]) {
				num++
			}
		}
	}

	return num
}

public bZombiesLeft() {
	for(new id=1; id<32; id++) {
		if(is_user_alive(id)) {
			if(g_bIsZombie[id]) {
				return true
			}
		}
	}

	return false
}

public cmdUpdateScoreBoard(id) {
	message_begin(MSG_ALL,get_user_msgid("ScoreInfo"))
	write_byte(id)
	write_short(get_user_frags(id))
	write_short(get_user_deaths(id))
	write_short(0)
	write_short(get_user_team(id))
	message_end()
}

public fwdPlayerSpawn(iPlayer) {
	if(is_user_alive(iPlayer)) {
		StripWeapons(iPlayer)
		cs_reset_user_model(iPlayer)
		set_pev(iPlayer,pev_viewmodel2,"models/v_knife.mdl")

		if(g_RoundProgess==PREPARE || g_RoundProgess==RDENDED && g_RoundProgess!=PREGAME) {
			set_user_health(iPlayer,100)
			PrimaryWeaponMenu(iPlayer)
			set_pev(iPlayer,pev_flags,pev(iPlayer,pev_flags) | FL_FROZEN)
			set_user_maxspeed(iPlayer,get_pcvar_float(g_fCvar_HSpeed))
		} else if(g_RoundProgess==INFECTD) {
			InfectPlayer(iPlayer,false)
		}

		defusekit = get_pdata_int(iPlayer,OFFSET_NVGOGGLES)
		if(!(defusekit & HAS_NVGOGGLES)) {
			defusekit |= HAS_NVGOGGLES
			set_pdata_int(iPlayer,OFFSET_NVGOGGLES,defusekit)
		}

		client_cmd(iPlayer,"mp3 play %s",g_szSoundsAmbience[random_num(0,charsmax(g_szSoundsAmbience))])
	}
}

public StripWeapons(iPlayer) {
	strip_user_weapons(iPlayer)
	set_pdata_int(iPlayer,OFFSET_PRIMARYWEAPON,0)
	set_pdata_int(iPlayer,OFFSET_SECONDARYWEAPON,0)
	give_item(iPlayer,"weapon_knife")
}

public InfectPlayer(iPlayer,bRespawn) {
	g_bIsZombie[iPlayer]=true

	if(bRespawn) {
		ExecuteHam(Ham_CS_RoundRespawn,iPlayer)
		PlaySoundToClients(g_szSoundsInfect[random_num(0,charsmax(g_szSoundsInfect))])
		return
	}

	cs_set_user_team(iPlayer,CS_TEAM_T)

	StripWeapons(iPlayer)

	static szModel[32]
	switch(random_num(1,3)) {
		case 1: {
			szModel="tank_zombi_host"
		} case 2: {
			szModel="zombie_source"
		} case 3: {
			szModel="zombie_nazi"
		}
	}

	cs_set_user_model(iPlayer,szModel)
	set_pev(iPlayer,pev_viewmodel2,g_szModels[0])

	set_user_health(iPlayer,get_pcvar_num(g_fCvar_ZHealth))

	new gmsgShake = get_user_msgid("ScreenShake")
	message_begin(MSG_ONE,gmsgShake,{0,0,0},iPlayer)
	write_short(255 << 14 ) //ammount
	write_short(1 << 12) //lasts this long
	write_short(255 << 14) //frequency
	message_end()

	ShowHealthHUD(iPlayer)

	set_user_maxspeed(iPlayer,get_pcvar_float(g_fCvar_ZSpeed))

	//emit_sound(iPlayer,CHAN_AUTO,g_szSoundsInfect[0],1.0,ATTN_NORM,0,PITCH_NORM)

	//static Float:origin[3]
	//pev(iPlayer,pev_origin,origin)
	//EF_EmitAmbientSound(iPlayer,origin,g_szSoundsInfect[0],1.0,ATTN_NORM,0,PITCH_NORM)
	//engfunc(EngFunc_EmitAmbientSound,0,origin,g_szSoundsInfect[random_num(0,charsmax(g_szSoundsInfect))],VOL_NORM,ATTN_NORM,0,PITCH_NORM)
}

public plugin_precache() {
	for(new i=0; i<sizeof(g_szModels); i++) {
		precache_model(g_szModels[i])
	}

	for(new i=0; i<sizeof(g_szSoundsInfect); i++) {
		precache_generic(g_szSoundsInfect[i])
	}
	for(new i=0; i<sizeof(g_szSoundsAmbience); i++) {
		precache_generic(g_szSoundsAmbience[i])
	}
	for(new i=0; i<sizeof(g_szSoundsZombieWin); i++) {
		precache_generic(g_szSoundsZombieWin[i])
	}
	for(new i=0; i<sizeof(g_szSoundsHumanWin); i++) {
		precache_generic(g_szSoundsHumanWin[i])
	}

	new ent = find_ent_by_class(-1,"info_map_parameters")
	if(!ent) {
		ent = create_entity("info_map_parameters")
	}

	DispatchKeyValue(ent,"buying","3")
	DispatchSpawn(ent)

	//switch(random_num(1,2)) {
		//case 1: create_entity("env_rain")
		//case 2: create_entity("env_snow")
	//}
}
