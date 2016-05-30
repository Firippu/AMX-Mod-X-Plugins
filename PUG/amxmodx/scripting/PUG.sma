#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fvault>
#include <hamsandwich>
#include <dhudmessage>
#include <fun>

#define VERSION "0.0.1"

#define FOR_PLSTART_NUM 1

new g_iHLTV_ID

new const szVault[] = "pug"
new const szEntry[] = "status"

#define PREFIX "[PUG]"

#define READY_REQUIRED     10
#define NORMAL_MAX_WIN     16
#define MAX_WIN_OVERTIME   19

#define HALFTIME_ACTIVATE  15
#define OVERTIME_ACTIVATE  30
#define OVERTIME_TMSWITCH  33
#define OVERTIME_OTFINISH  36

#define THINKERCYCLE 1.0

#define VOTE_EXPIRE 15.0

new bool:g_bPlayerReady[33]

new bool:g_bMatchActive

new g_iMatchProgress

new g_iCurrentCaptain

new g_szThinkerClassname[]="hud_thinker"

new g_iRoundCount,
	g_iCTWinCount,
	g_iTEWinCount

new g_iCaptains[2]
new g_iCaptSwitch

new g_iCaptainMenu

new bool:g_bVoteInProcess

new g_iMaxPlayers

new g_iVoteRandomize
new g_iVoteCaptain
new g_iVoteAsIs

new g_iMapVotes[7]
new g_szMapNames[7][32]
new g_szMapAllNames[16][32]

new g_iTextMsg 
new const g_szShieldCMD[] = "shield" 
new const g_szJoinCMD[]="jointeam"

new g_iDMG[12][12]

public plugin_init() {
	register_plugin("PUG",VERSION,"Firippu")

	register_event("SendAudio","Event_SendAudio_MRAD_ctwin","a","2&%!MRAD_ctwin")
	register_event("SendAudio","Event_SendAudio_MRAD_tewin","a","2&%!MRAD_terwin")

	register_logevent("event_new_round",2,"1=Round_Start")

	register_clcmd("say .ready","cmdReady")

	register_clcmd("say .unready","cmdUnReady")
	register_clcmd("say .notready","cmdUnReady")

	register_clcmd("say .score","cmdScore")

	register_clcmd("say .hp","cmdHP")

	register_clcmd("say .end","cmdEnd")
	register_clcmd("say .forceready","cmdForceReady")

	register_clcmd("say .dmg","cmdDMG")

	RegisterHam(Ham_TakeDamage,"player","fwdTakeDmg",1)

	g_iMaxPlayers=get_maxplayers()

	new iEntity
	if((iEntity = create_entity("info_target"))) {
		entity_set_string(iEntity,EV_SZ_classname,g_szThinkerClassname)
		entity_set_float(iEntity,EV_FL_nextthink,get_gametime() + THINKERCYCLE)
		register_think(g_szThinkerClassname,"DisplayReadyHud")
	}

	g_iMatchProgress=0
	exec_config("pregame.cfg")
	server_cmd("mp_roundtime 9")

	RegisterHam(Ham_Killed,"player","fwdPlayerKilled",1)
	RegisterHam(Ham_Spawn,"player","fwdPlayerSpawn",1)

	register_clcmd("joinclass","clcmd_joinclass")

	register_menucmd(register_menuid("DCT_BuyItem", 1), (1<<7), "BuyShield")
	g_iTextMsg = get_user_msgid("TextMsg")
}

public cmdHP(id) {
	if(bPlayerInTeam(id) && !is_user_alive(id)) {
		new CsTeams:OppositeTeam

		switch(cs_get_user_team(id)) {
			case CS_TEAM_T: {
				OppositeTeam=CS_TEAM_CT
			} case CS_TEAM_CT: {
				OppositeTeam=CS_TEAM_T
			} default: {
				return PLUGIN_HANDLED
			}
		}

		for(new i=FOR_PLSTART_NUM; i<=g_iMaxPlayers; i++) {
			if(is_user_connected(i)) {
				if(cs_get_user_team(i)==OppositeTeam) {
					static szName[32]
					get_user_name(i,szName,charsmax(szName))
					client_print(id,print_chat,"%s %s has %d health",PREFIX,szName,get_user_health(i))
				}
			}
		}
	} else {
		client_print(id,print_chat,"%s You must be dead to use this command",PREFIX)
	}

	return PLUGIN_HANDLED
}

public cmdDMG(id) {
	if(bPlayerInTeam(id) && !is_user_alive(id)) {
		for(new i=FOR_PLSTART_NUM; i<=g_iMaxPlayers; i++) {
			if(is_user_connected(i)) {
				if(g_iDMG[id][i]) {
					static szName[32]
					get_user_name(i,szName,charsmax(szName))
					client_print(id,print_chat,"%s Done %d damage to %s",PREFIX,g_iDMG[id][i],szName)
				}
			}
		}
	} else {
		client_print(id,print_chat,"%s You must be dead to use this command",PREFIX)
	}

	return PLUGIN_HANDLED
}

public fwdTakeDmg(iVictim,iInflictor,iAttacker,Float:damage,damagebits) {
	if(cs_get_user_team(iAttacker)==cs_get_user_team(iVictim)) {
		return HAM_SUPERCEDE
	}

	g_iDMG[iAttacker][iVictim]+=floatround(damage)

	return HAM_IGNORED
}

public cmdScore(id) {
	client_print(id,print_chat,"%s T %d - %d CT",PREFIX,g_iTEWinCount,g_iCTWinCount)
	return PLUGIN_HANDLED
}

public BuyShield(id) {
	Message_No_Shield(id)
	return PLUGIN_HANDLED
}

public CS_InternalCommand(id,const szCommand[]) {
	if(equali(szCommand,g_szShieldCMD)) {
		Message_No_Shield(id)
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

Message_No_Shield(id) {
	static const Alias_Not_Avail[] = "#Weapon_Not_Available"
	static const TactShield[] = "#TactShield"
	const HUD_PRINTCENTER = 4

	message_begin(MSG_ONE_UNRELIABLE,g_iTextMsg,.player=id)
	write_byte(HUD_PRINTCENTER)
	write_string(Alias_Not_Avail)
	write_string(TactShield)
	message_end()
}

public client_putinserver(id) {
	if(is_user_hltv(id)) {
		g_iHLTV_ID=id
	}
}

stock get_random_te() {
	static players[33]
	new id,num
	for(id=FOR_PLSTART_NUM; id<=g_iMaxPlayers; id++) {
		if(is_user_connected(id)) {
			if(cs_get_user_team(id)==CS_TEAM_T) {
				players[num]=id
				num++
			}
		}
	}

	return players[random(num)]
}

stock get_random_ct() {
	static players[33]
	new id,num
	for(id=FOR_PLSTART_NUM; id<=g_iMaxPlayers; id++) {
		if(is_user_connected(id)) {
			if(cs_get_user_team(id)==CS_TEAM_CT) {
				players[num]=id
				num++
			}
		}
	}

	return players[random(num)]
}

stock get_players_num() {
	new id,num
	for(id=FOR_PLSTART_NUM; id<=g_iMaxPlayers; id++) {
		if(is_user_connected(id) && id!=g_iHLTV_ID) {
			num++
		}
	}

	return num
}

stock get_cts_num() {
	new id,num
	for(id=FOR_PLSTART_NUM; id<=g_iMaxPlayers; id++) {
		if(is_user_connected(id)) {
			if(cs_get_user_team(id)==CS_TEAM_CT) {
				num++
			}
		}
	}

	return num
}

stock get_inteam_num() {
	new id,num
	for(id=FOR_PLSTART_NUM; id<=g_iMaxPlayers; id++) {
		if(is_user_connected(id)) {
			switch(cs_get_user_team(id)) {
				case CS_TEAM_T..CS_TEAM_CT: {
					num++
				}
			}
		}
	}

	return num
}

stock get_terrorists_num() {
	new id,num
	for(id=FOR_PLSTART_NUM; id<=g_iMaxPlayers; id++) {
		if(is_user_connected(id)) {
			if(cs_get_user_team(id)==CS_TEAM_T) {
				num++
			}
		}
	}

	return num
}

stock get_spec_num() {
	new id,num
	for(id=FOR_PLSTART_NUM; id<=g_iMaxPlayers; id++) {
		if(is_user_connected(id) && id!=g_iHLTV_ID) {
			if(cs_get_user_team(id)==CS_TEAM_SPECTATOR) {
				num++
			}
		}
	}

	return num
}

stock get_random_spec() {
	static players[33]
	new id,num
	for(id=FOR_PLSTART_NUM; id<=g_iMaxPlayers; id++) {
		if(is_user_connected(id) && id!=g_iHLTV_ID) {
			if(cs_get_user_team(id)==CS_TEAM_SPECTATOR ) {
				players[num]=id
				num++
			}
		}
	}

	return num ? players[random(num)]:0
}

stock bool:bPlayerInTeam(iPlayer) {
	if(is_user_connected(iPlayer)) {
		switch(cs_get_user_team(iPlayer)) {
			case CS_TEAM_T..CS_TEAM_CT: {
				return true
			}
		}
	}

	return false
}

public cmdForceReady(id) {
	if(get_user_flags(id) & ADMIN_KICK) {
		if(g_iMatchProgress==0) {
			initiateMatch()
		} else {
			client_print(id,print_chat,"%s Match has already started.",PREFIX)
		}
	} else {
		client_print(id,print_chat,"%s Must be admin to use this command.",PREFIX)
	}

	return PLUGIN_CONTINUE
}

public clcmd_joinclass(iPlayer) {
	if(g_iMatchProgress==0) {
		set_task(1.0,"checkifstilldead",iPlayer)
	}
}

public checkifstilldead(iPlayer) {
	if(!is_user_alive(iPlayer)) {
		set_task(1.0,"RespawnPlayer",iPlayer)
	}
}

public fwdPlayerSpawn(id) {
	if(g_iMatchProgress==0) {
		if(is_user_alive(id)) {
			cs_set_user_money(id,16000)

			if(!get_user_godmode(id)) {
				set_user_godmode(id,1)

				switch(cs_get_user_team(id)) {
					case CS_TEAM_T: set_user_rendering(id,kRenderFxGlowShell,255,0,0,kRenderNormal,16)
					case CS_TEAM_CT: set_user_rendering(id,kRenderFxGlowShell,0,0,255,kRenderNormal,16)
				}

				set_task(2.0,"RemoveProtection",id)
			}
		}
	}
}

public RemoveProtection(id) {
	if(is_user_connected(id)) {
		set_user_godmode(id,0)
		set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderNormal,0)
	}
}

public fwdPlayerKilled(iPlayer) {
	if(g_iMatchProgress==0) {
		set_task(0.3,"RespawnPlayer",iPlayer)
	}
}

public RespawnPlayer(iPlayer) {
	if(bPlayerInTeam(iPlayer)) {
		ExecuteHam(Ham_CS_RoundRespawn,iPlayer)
	}
}

public DisplayPlayerChoice(id,item_name[]) {
	static szPlayerName[32]
	get_user_name(id,szPlayerName,31)
	client_print(0,print_chat,"%s %s chose %s.",PREFIX,szPlayerName,item_name)
}

public FillMapList() {
	new file[40],configsdir[24]
	get_localinfo("amxx_configsdir",configsdir,23)
	format(file,39,"%s/maps.ini",configsdir)

	new i=0,szMapName[32]
	new fh=fopen(file,"rt")
	if(fh!=0) {
		while(!feof(fh)) {
			static szBuffer[49]
			fgets(fh,szBuffer,charsmax(szBuffer))
			parse(szBuffer,szMapName,charsmax(szMapName))
			if(!equal(";",szMapName[0])) {
				copy(g_szMapAllNames[i],31,szMapName)
				i++
			}
		}
	}
}

public bNoMapVoted() {
	new size=sizeof(g_iMapVotes)
	for(new i=0; i<size; i++) {
		if(g_iMapVotes[i]>0) {
			return false
		}
	}

	return true
}

public iGetVotedMapArrayNum() {
	new arraynum,currentlargest
	new size=sizeof(g_iMapVotes)
	for(new i=0; i<size; i++) {
		if(g_iMapVotes[i]>currentlargest) {
			currentlargest=g_iMapVotes[i]
			arraynum=i
		}
	}

	return arraynum
}

public exec_config(name[]) {
	roundrestart()
	new file[40],configsdir[24]
	get_localinfo("amxx_configsdir",configsdir,23)
	format(file,39,"%s/%s",configsdir,name)

	server_cmd("exec %s",file)
	server_exec()
}

public MapMenu() {
	FillMapList()
	new menu = menu_create("\rMap Menu","map_menu_handler")
	menu_setprop(menu,MPROP_EXIT,MEXIT_NEVER)

	for(new i=0; i<6; i++) {
		static szTemp[32]
		szTemp[0]='^0'
		copy(szTemp,31,g_szMapAllNames[random_num(0,6)])
		if( equal(szTemp,g_szMapNames[0]) ||
			equal(szTemp,g_szMapNames[1]) ||
			equal(szTemp,g_szMapNames[2]) ||
			equal(szTemp,g_szMapNames[3]) ||
			equal(szTemp,g_szMapNames[4]) ||
			equal(szTemp,g_szMapNames[5])) {
			i--
		} else {
			copy(g_szMapNames[i],31,szTemp)
			menu_additem(menu,g_szMapNames[i],"",0)
		}
	}

	for(new id=FOR_PLSTART_NUM; id<=g_iMaxPlayers; id++) {
		if(is_user_connected(id) && id!=g_iHLTV_ID) {
			menu_display(id,menu,0)
		}
	}

	set_task(VOTE_EXPIRE,"MapMenu_End",menu)
}

public MapMenu_End(menu) {
	menu_destroy(menu)
	client_print(0,print_chat,"%s Vote ended.",PREFIX)

	if(!bNoMapVoted()) {
		new arraynum=iGetVotedMapArrayNum()
		client_print(0,print_chat,"%s Map is changing to %s.",PREFIX,g_szMapNames[arraynum])
		message_begin(MSG_ALL,SVC_INTERMISSION)
		message_end()
		fvault_set_data(szVault,szEntry,"1")
		set_task(5.0,"ChangeMap",arraynum)
	} else {
		client_print(0,print_chat,"%s No Map Chosen, retrying...",PREFIX)

		for(new i=0; i<7; i++) {
			g_szMapNames[i][0] = '^0'
			g_szMapAllNames[i][0] = '^0'
		}

		set_task(0.1,"MapMenu")
	}
}

public map_menu_handler(id,menu,item) {
	if(item<0) {
		return PLUGIN_HANDLED
	}

	if(item==MENU_EXIT) {
		//menu_destroy(menu)
		//return PLUGIN_HANDLED
	}

	static szData[6],szName[35]
	new item_access,item_callback
	menu_item_getinfo(menu,item,item_access,szData,charsmax(szData),szName,charsmax(szName),item_callback)

	//menu_destroy(menu)

	g_iMapVotes[item]++

	DisplayPlayerChoice(id,szName)

	return PLUGIN_HANDLED
}

public ModeMenu() {
	new menu = menu_create("\rChoose Mode","mode_menu_handler")
	menu_setprop(menu,MPROP_EXIT,MEXIT_NEVER)

	menu_additem(menu,"Captain","",0)
	menu_additem(menu,"Randomize","",0)
	menu_additem(menu,"As-Is","",0)

	for(new id=FOR_PLSTART_NUM; id<=g_iMaxPlayers; id++) {
		if(is_user_connected(id) && id!=g_iHLTV_ID) {
			menu_display(id,menu,0)
		}
	}

	set_task(VOTE_EXPIRE,"ModeMenu_End",menu)
}

public ModeMenu_End(menu) {
	menu_destroy(menu)
	client_print(0,print_chat,"%s Mode Vote ended.",PREFIX)
	if(g_iVoteCaptain>g_iVoteRandomize && g_iVoteCaptain>g_iVoteAsIs) {
		client_print(0,print_chat,"%s Winner: Captain",PREFIX,g_iVoteCaptain)
		set_task(1.0,"LoadCaptainMode")
	} else if(g_iVoteRandomize>g_iVoteCaptain && g_iVoteRandomize>g_iVoteAsIs) {
		client_print(0,print_chat,"%s Winner: Randomize",PREFIX,g_iVoteCaptain)
		set_task(1.0,"teams_randomize")
	} else if(g_iVoteAsIs>g_iVoteCaptain && g_iVoteAsIs>g_iVoteRandomize) {
		client_print(0,print_chat,"%s Winner: As-Is",PREFIX,g_iVoteCaptain)
		set_task(1.0,"fnStartMatch")
	} else {
		client_print(0,print_chat,"%s Mode Vote ended vote tied; trying again...",PREFIX,g_iVoteAsIs)
		set_task(0.1,"ModeMenu")
	}
}

public mode_menu_handler(id,menu,item) {
	if(item<0) {
		return PLUGIN_HANDLED
	}

	if(item==MENU_EXIT) {
		//menu_destroy(menu)
		//return PLUGIN_HANDLED
	}

	static szData[6],szName[35]
	new item_access,item_callback
	menu_item_getinfo(menu,item,item_access,szData,charsmax(szData),szName,charsmax(szName),item_callback)

	//menu_destroy(menu)

	switch(item) {
		case 0: g_iVoteCaptain++
		case 1: g_iVoteRandomize++
		case 2: g_iVoteAsIs++
	}

	DisplayPlayerChoice(id,szName)

	return PLUGIN_HANDLED
}

public CaptainMenu() {
	g_iCurrentCaptain=g_iCaptains[g_iCaptSwitch^=1]

	g_iCaptainMenu = menu_create("\rCaptain Menu","captain_menu_handler")
	menu_setprop(g_iCaptainMenu,MPROP_EXIT,MEXIT_NEVER)

	static szName[32]
	static szUserId[6]

	for(new id=FOR_PLSTART_NUM; id<=g_iMaxPlayers; id++) {
		if(is_user_connected(id) && id!=g_iHLTV_ID) {
			if(cs_get_user_team(id) == CS_TEAM_SPECTATOR) {
				szName[0]='^0'
				get_user_name(id,szName,charsmax(szName))
				formatex(szUserId,charsmax(szUserId),"%d",id)
				menu_additem(g_iCaptainMenu,szName,szUserId,0)
			}
		}
	}

	menu_display(g_iCurrentCaptain,g_iCaptainMenu,0)

	set_task(VOTE_EXPIRE,"CaptainMenu_Cancel",g_iCurrentCaptain)
}

public CaptainMenu_Cancel(id) {
	if(is_user_connected(id)) {
		client_cmd(id,"slot1")
		menu_destroy(g_iCaptainMenu)
		menu_cancel(id)

		new iRandomSpec=get_random_spec()
		if(iRandomSpec>0) {
			static szCaptain[32],szSpec[32]
			get_user_name(id,szCaptain,charsmax(szCaptain))
			get_user_name(iRandomSpec,szSpec,charsmax(szSpec))
			client_print(0,print_chat,"%s %s took too long; randomly chose %s.",PREFIX,szCaptain,szSpec)
			cs_set_user_team(iRandomSpec,cs_get_user_team(id))
			set_task(1.0,"CaptainMenu")
		} else {
			set_task(1.0,"fnStartMatch")
		}
	} else {
		client_print(0,print_chat,"%s One of captains left; randomizing teams.",PREFIX)
		teams_randomize()
	}
}

public captain_menu_handler(id,menu,item) {
	remove_task(id)

	if(item<0) {
		return PLUGIN_HANDLED
	}

	if(item==MENU_EXIT) {
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	static szData[6],szName[35]
	new item_access,item_callback
	menu_item_getinfo(menu,item,item_access,szData,charsmax(szData),szName,charsmax(szName),item_callback)

	new userid=str_to_num(szData)

	if(is_user_connected(userid)) {
		if(cs_get_user_team(userid) == CS_TEAM_SPECTATOR) {
			cs_set_user_team(userid,cs_get_user_team(id))
			DisplayPlayerChoice(id,szName)
		} else {
			client_print(0,print_chat,"%s Chosen player is not in spec.",PREFIX)
		}
	} else {
		client_print(0,print_chat,"%s Chosen player is not connected.",PREFIX)
	}

	menu_destroy(menu)

	get_spec_num() ? CaptainMenu():set_task(1.0,"fnStartMatch")

	return PLUGIN_HANDLED
}

public ChangeMap(ArrayNum) {
	server_cmd("changelevel %s",g_szMapNames[ArrayNum])
}

public PrintHudMessage(Float:iSeconds,szMessage[]) {
	set_dhudmessage(0,160,0,-0.95,-0.25,2,6.0,iSeconds,0.1,1.5)
	show_dhudmessage(0,szMessage)
}

public MatchEnded(iTeamWon) {
	switch(iTeamWon) {
		case 1: {
			client_print(0,print_chat,"%s Terrorists Won Match.",PREFIX)
			PrintHudMessage(3.0,"Terrorists Wins")
		} case 2: {
			client_print(0,print_chat,"%s CTs Won Match.",PREFIX)
			PrintHudMessage(3.0,"Counter Terrorist Wins")
		} default: {
			client_print(0,print_chat,"%s Match Ended.",PREFIX)
			PrintHudMessage(3.0,"Matched Ended")
		}
	}

	g_iMatchProgress=0
	g_bMatchActive=false
	g_iCTWinCount=0
	g_iTEWinCount=0

	ClearAllReady()

	fvault_set_data(szVault,szEntry,"0") // file set off

	exec_config("pregame.cfg")
}

public ClearAllReady() {
	for(new id=FOR_PLSTART_NUM; id<=g_iMaxPlayers; id++) {
		g_bPlayerReady[id]=false
	}
}

public switchTeams() {
	new tempTE,tempCT
	tempTE=g_iTEWinCount
	tempCT=g_iCTWinCount
	g_iCTWinCount=tempTE
	g_iTEWinCount=tempCT

	for(new id=FOR_PLSTART_NUM; id<=g_iMaxPlayers; id++) {
		if(is_user_connected(id) && id!=g_iHLTV_ID) {
			if(cs_get_user_team(id)==CS_TEAM_CT) {
				cs_set_user_team(id,CS_TEAM_T)
			} else if(cs_get_user_team(id)==CS_TEAM_T) {
				cs_set_user_team(id,CS_TEAM_CT)
			}
		}
	}
}

public roundrestart() {
	server_cmd("sv_restartround 1")
}

public teams_randomize() {
	static Players[32]
	new playerCount,i,player
	get_players(Players,playerCount,"h")

	new type=0
	for(i=0; i<playerCount; i++) {
		player=Players[i]

		switch(cs_get_user_team(player)) {
			case CS_TEAM_T: {
				if(type==0) {
					type=random_num(1,2)
					cs_set_user_team(player,_:type)
				} else {
					cs_set_user_team(player,(type==1) ? 2:1)
					type=0
				}
			} case CS_TEAM_CT: {
				if(type==0) {
					type = random_num(1,2)
					cs_set_user_team(player,_:type)
				} else {
					cs_set_user_team(player,(type==1) ? 2:1)
					type=0
				}
			}
		}
	}

	client_print(0,print_chat,"%s Randomized Teams.",PREFIX)
	set_task(1.0,"fnStartMatch")
}

public RoundEnded() {
	client_print(0,print_chat,"%s Round #%d Finished.",PREFIX,g_iRoundCount)
	client_print(0,print_chat,"%s T %d - %d CT",PREFIX,g_iTEWinCount,g_iCTWinCount)

	if(g_iRoundCount==OVERTIME_OTFINISH) {
		if(g_iCTWinCount==g_iTEWinCount) {
			g_iRoundCount=30
			g_iCTWinCount=15
			g_iTEWinCount=15
			g_bMatchActive=false
			switchTeams()
			client_print(0,print_chat,"%s OverTime was a tie, restarting...",PREFIX,g_iRoundCount)
		}
	}

	switch(g_iRoundCount) {
		case HALFTIME_ACTIVATE: {
			g_iMatchProgress=2
			g_bMatchActive=false

			ClearAllReady()
			switchTeams()
			client_print(0,print_chat,"%s Half Time & Teams Switch",PREFIX)
		} case OVERTIME_ACTIVATE: {
			ClearAllReady()

			g_iMatchProgress=3
			g_bMatchActive=false

			client_print(0,print_chat,"%s Over Time Activated.",PREFIX)
		} case OVERTIME_TMSWITCH: {
			g_iMatchProgress=4
			switchTeams()
			client_print(0,print_chat,"%s Teams Switched.",PREFIX)

			exec_config("cev-ot.cfg")
			exec_config("lo3.cfg")
		}
	}

	g_iRoundCount++
}

public Event_SendAudio_MRAD_ctwin() {
	if(g_bMatchActive) {
		g_iCTWinCount++

		if((g_iMatchProgress==2 && (g_iCTWinCount>=NORMAL_MAX_WIN)) || (g_iMatchProgress==4 && (g_iCTWinCount>=MAX_WIN_OVERTIME))) {
			MatchEnded(2)
		} else {
			RoundEnded()
		}
	}
}

public Event_SendAudio_MRAD_tewin() {
	if(g_bMatchActive) {
		g_iTEWinCount++

		if((g_iMatchProgress==2 && (g_iTEWinCount>=NORMAL_MAX_WIN)) || (g_iMatchProgress==4 && (g_iTEWinCount>=MAX_WIN_OVERTIME))) {
			MatchEnded(1)
		} else {
			RoundEnded()
		}
	}
}

public InArray(const iValue,const iArray[],const iArraySize) {
	for(new i=0; i<iArraySize; i++)
		if(iValue==iArray[i])
			return 1

	return 0
}

public initiateMatch() {
	if(!bAfterMapVote()) {
		// Make map vote
		g_bVoteInProcess=true
		client_print(0,print_chat,"%s Vote Started; ending in %d seconds.",PREFIX,floatround(VOTE_EXPIRE))
		MapMenu()
	} else if(g_iMatchProgress==0) {
		// style choosen
		g_bVoteInProcess=true
		client_print(0,print_chat,"%s Vote Started; ending in %d seconds.",PREFIX,floatround(VOTE_EXPIRE))
		ModeMenu()
	} else {
		set_task(1.0,"fnStartMatch")
	}
}

public DisplayReadyHud(iEntity) {
	if(g_iCurrentCaptain>0) {
		static szName[32]
		static szTEs[512]
		static szCTs[512]

		szTEs[0] = '^0'
		szCTs[0] = '^0'

		new isCap
		for(new id=FOR_PLSTART_NUM; id<=g_iMaxPlayers; id++) {
			if(is_user_connected(id) && id!=g_iHLTV_ID) {
				get_user_name(id,szName,31)

				isCap=InArray(id,g_iCaptains,sizeof g_iCaptains)

				if(cs_get_user_team(id)==CS_TEAM_T) {
					format(szTEs,510,"%s%s%s%s^n",szTEs,(id==g_iCurrentCaptain) ? "> ":"",isCap ? "(C) ":"",szName)
				} else if(cs_get_user_team(id)==CS_TEAM_CT) {
					format(szCTs,510,"%s%s%s%s^n",szCTs,(id==g_iCurrentCaptain) ? "> ":"",isCap ? "(C) ":"",szName)
				}
			}
		}

		set_hudmessage(255,0,0,0.8,0.07,0,0.0,3.0,0.0,0.0,3)
		show_hudmessage(0,"Terrorists (%d of %d)",get_terrorists_num(),(READY_REQUIRED/2))

		set_hudmessage(0,0,255,0.8,0.50,0,0.0,3.0,0.0,0.0,2)
		show_hudmessage(0,"Counter-Terrorists (%d of %d)",get_cts_num(),(READY_REQUIRED/2))

		set_hudmessage(255,255,255,0.80,0.53,0,0.0,3.0,0.0,0.0,1)
		show_hudmessage(0,szCTs,511)

		set_hudmessage(255,255,225,0.80,0.10,0,0.0,3.0,0.0,0.0,4)
		show_hudmessage(0,szTEs,511)
	} else if(!g_bMatchActive) {
		if(!g_bVoteInProcess) {
			new iReadyCount=get_ready_num()
			if((iReadyCount>=READY_REQUIRED) || (g_iMatchProgress==2 && iReadyCount>=get_inteam_num())) {
				if(bPlayableConditions()) {
					initiateMatch()
				} else {
					MatchEnded(0)
				}
			}

			static szReadys[512]
			static szNotReadys[512]
			static szName[32]

			szReadys[0]='^0'
			szNotReadys[0]='^0'

			for(new id=FOR_PLSTART_NUM; id<=g_iMaxPlayers; id++) {
				if(is_user_connected(id) && id!=g_iHLTV_ID) {
					get_user_name(id,szName,31)

					g_bPlayerReady[id] ? format(szReadys,510,"%s%s^n",szReadys,szName):format(szNotReadys,510,"%s%s^n",szNotReadys,szName)
				}
			}

			new iPlayerCount=get_players_num()

			set_hudmessage(255,0,0,0.8,0.07,0,0.0,3.0,0.0,0.0,3)
			show_hudmessage(0,"Not Ready (%d of %d)",(READY_REQUIRED-iReadyCount),(g_iMatchProgress==2) ? iPlayerCount:READY_REQUIRED)

			set_hudmessage(0,255,0,0.8,0.50,0,0.0,3.0,0.0,0.0,2)
			show_hudmessage(0,"Ready (%d of %d)",iReadyCount,(g_iMatchProgress==2) ? iPlayerCount:READY_REQUIRED)

			set_hudmessage(255,255,225,0.80,0.53,0,0.0,3.0,0.0,0.0,1)
			show_hudmessage(0,szReadys,511)

			set_hudmessage(255,255,225,0.80,0.10,0,0.0,3.0,0.0,0.0,4)
			show_hudmessage(0,szNotReadys,511)
		}
	}

	entity_set_float(iEntity,EV_FL_nextthink,get_gametime() + THINKERCYCLE)
}

public cmdEnd(id) {
	(get_user_flags(id) & ADMIN_KICK) ? MatchEnded(0):client_print(id,print_chat,"%s Must be admin to use this command.",PREFIX)
}

public cmdUnReady(id) {
	if(!g_bMatchActive) {
		g_bPlayerReady[id]=false
	} else {
		client_print(id,print_chat,"%s Can't unready during an active match.",PREFIX)
	}
}

public event_new_round() {
	if(g_bMatchActive) {
		client_print(0,print_chat,"%s Round #%d Started.",PREFIX,g_iRoundCount)
	}

	new id=FOR_PLSTART_NUM
	new k=FOR_PLSTART_NUM
	for(id=FOR_PLSTART_NUM; id<=g_iMaxPlayers; id++) {
		for(k=FOR_PLSTART_NUM; k<=g_iMaxPlayers; k++) {
			g_iDMG[id][k]=0
		}
	}
}

public client_disconnect(id) {
	set_task(0.3,"client_disconnect_delay",id)
	g_bPlayerReady[id]=false
}

public client_disconnect_delay(id) {
	if(g_bMatchActive) {
		static szName[35]
		get_user_name(id,szName,charsmax(szName))

		client_print(0,print_chat,"%s %s left an active match.",PREFIX,szName)

		if(!bPlayableConditions()) {
			MatchEnded(0)
		}
	}
}

public fnStartMatch() {
	g_bVoteInProcess=false
	g_iCurrentCaptain=0

	if(bPlayableConditions()) {
		if(g_iMatchProgress==0) {
			g_iMatchProgress=1
			g_iRoundCount=1
		}

		g_bMatchActive=true

		switch(g_iMatchProgress) {
			case 1..2: {
				exec_config("cevo.cfg")
				exec_config("lo3.cfg")
			} case 3..4: {
				exec_config("cev-ot.cfg")
				exec_config("lo3.cfg")
			}
		}
	} else {
		MatchEnded(0)
	}
}

public bool:bPlayableConditions() {
	if(get_cts_num() && get_terrorists_num()) {
		return true
	}

	return false
}

public get_ready_num() {
	new id,num
	for(id=FOR_PLSTART_NUM; id<=g_iMaxPlayers; id++) {
		if(g_bPlayerReady[id]) {
			num++
		}
	}

	return num
}

public LoadCaptainMode() {
	client_print(0,print_chat,"%s Captains now choosing their team.",PREFIX,g_iVoteCaptain)
	g_iCaptains[0]=get_random_te()
	//g_iCaptains[0]=find_player("a","Firippu")
	g_iCaptains[1]=get_random_ct()

	for(new id=FOR_PLSTART_NUM; id<=g_iMaxPlayers; id++) {
		if(is_user_connected(id) && id!=g_iHLTV_ID) {
			if(g_iCaptains[0]!=id && g_iCaptains[1]!=id) {
				user_silentkill(id)
				cs_set_user_team(id,CS_TEAM_SPECTATOR)
			}
		}
	}

	CaptainMenu()
}

public bAfterMapVote() {
	new iTimestamp
	new szTempValue[2]
	new iModeStatus
	fvault_get_data(szVault,szEntry,szTempValue,charsmax(szTempValue),iTimestamp)
	iModeStatus=str_to_num(szTempValue)

	if(!iModeStatus) {
		return false
	}

	return true
}

public cmdReady(id) {
	if(g_bVoteInProcess) {
		client_print(id,print_chat,"%s Voting has already started.",PREFIX)
	} else if(g_bMatchActive) {
		client_print(id,print_chat,"%s Match has already started.",PREFIX)
	} else if(g_bPlayerReady[id]) {
		client_print(id,print_chat,"%s You are already ready.",PREFIX)
	} else if(!bPlayerInTeam(id)) {
		client_print(id,print_chat,"%s You must be in a team.",PREFIX)
	} else {
		g_bPlayerReady[id]=true
	}
}

public client_command(id) {
	static szCommand[10]

	read_argv(0,szCommand,charsmax(szCommand))

	if(equali(szCommand,g_szShieldCMD)) {
		Message_No_Shield(id)
		return PLUGIN_HANDLED
	} else if(equali(szCommand,g_szJoinCMD)) {
		if(g_bVoteInProcess) {
			client_print(id,print_chat,"%s Cannot switch/join team when a vote is active.",PREFIX)
			return PLUGIN_HANDLED
		} else if(g_bPlayerReady[id]) {
			g_bPlayerReady[id]=false
		}
	}

	return PLUGIN_CONTINUE
}
