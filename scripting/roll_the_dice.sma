#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <fun>

#define PREFIX "[RollTheDice]"

#define AMOUNT_CD 120.0
#define GLOBAL_CD 10

#define CDTask 9116
#define BombTask 8116
#define BurnTask 7116
#define IgniteTask 6116

#define PRIZE_CHICKENS 1
#define PRIZE_NOCLIP 2
#define PRIZE_GODMODE 3
#define PRIZE_SKYWALKER 4
#define PRIZE_ZUES 5
#define PRIZE_LIGHTNING 6
#define PRIZE_RACECAR 7
#define PRIZE_SLAP 8
#define PRIZE_TIMEBOMB 9
#define PRIZE_BURN 0 // BROKEN // SET TO 10 WHEN FIXED

#define AMOUNT_CHICKEN 100
#define AMOUNT_NOCLIP 15
#define AMOUNT_GODMODE 15
#define AMOUNT_SKYWALKER 20
#define AMOUNT_ZUES 20
#define AMOUNT_RACECAR 17
#define AMOUNT_SLAP 20
#define AMOUNT_TIMEBOMB 5.0
#define AMOUNT_BURN 20

new bool:g_bCoolDown[33]
new g_szRoller[32]
new g_iRoller
new g_iCount
new g_iPrize
new g_szPrize[32]
new g_iGlobalCD

new mdlChicken
new sprSaber
new sprLightning
new sprSmoke
new sprWhite
new sprMflash
new sprFire
new mdlC4bomb
new mdlGibs

new g_msgShake
new g_msgDamage

new Float:BOMBKILL_RANGE = 450.0

public plugin_init() {
	register_plugin("roll_the_dice","0.0.4a","Firippu")

	g_msgShake = get_user_msgid("ScreenShake")
	g_msgDamage = get_user_msgid("Damage")

	RegisterHam(Ham_Spawn,"player","fwdPlayerSpawn",1)
	RegisterHam(Ham_Killed,"player","fwdPlayerKilled",1)

	register_touch("player","player","fwdPlayerTouchPlayer")

	register_concmd("say rtd","cmdRollTheDice")
	register_concmd("say /rtd","cmdRollTheDice")
	register_concmd("say rollthedice","cmdRollTheDice")
	register_concmd("say dados","cmdRollTheDice")
	register_concmd("say suerte","cmdRollTheDice")
	register_concmd("say_team rtd","cmdRollTheDice")
	register_concmd("say_team /rtd","cmdRollTheDice")
	register_concmd("say_team rollthedice","cmdRollTheDice")
	register_concmd("say_team dados","cmdRollTheDice")
	register_concmd("say_team suerte","cmdRollTheDice")
}

public ignite_effects(iTaskID) {
	new id=(iTaskID-BurnTask)

	if(is_user_alive(id)) {
		static korigin[3]
		get_user_origin(id,korigin)

		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(17)
		write_coord(korigin[0])
		write_coord(korigin[1])
		write_coord(korigin[2])
		write_short(sprMflash)
		write_byte(20)
		write_byte(200)
		message_end()

		message_begin(MSG_BROADCAST,SVC_TEMPENTITY,korigin)
		write_byte(5)
		write_coord(korigin[0])
		write_coord(korigin[1])
		write_coord(korigin[2])
		write_short(sprSmoke)
		write_byte(20)
		write_byte(15)
		message_end()

		set_task(0.2,"ignite_effects",(BurnTask+id))
	}
}

public ignite_player(iTaskID) {
	new id=(iTaskID-IgniteTask)

	if(is_user_alive(id)) {
		static korigin[3]
		get_user_origin(id,korigin)

		fakedamage(id,"player",5.0,DMG_BURN)

		message_begin(MSG_ONE,g_msgDamage,{0,0,0},id)
		write_byte(30)
		write_byte(30)
		write_long(1<<21)
		write_coord(korigin[0])
		write_coord(korigin[1])
		write_coord(korigin[2])
		message_end()

		emit_sound(id,CHAN_ITEM,"ambience/flameburst1.wav",0.6,ATTN_NORM,0,PITCH_NORM)
		emit_sound(id,CHAN_WEAPON,"scientist/scream07.wav",1.0,ATTN_NORM,0,PITCH_HIGH)

		set_task(2.0,"ignite_player",(IgniteTask+id))
	}
}

public fwdPlayerTouchPlayer(iTouched,iToucher) {
	if(g_iPrize==PRIZE_BURN) {
		if(g_iRoller==iToucher) {
			if(!task_exists(IgniteTask+iTouched)) {
				set_task(0.1,"ignite_effects",(BurnTask+iTouched))
				set_task(0.1,"ignite_player",(IgniteTask+iTouched))
			}
		}
	}
}

public fwdPlayerSpawn(id) {
	if(is_user_alive(id)) {
		set_user_rendering(id,kRenderFxNone,0,0,0,kRenderNormal,16)
	}
}

public RemovePrize(bool:bInterrupted) {
	g_iGlobalCD = (get_systime()+GLOBAL_CD)
	set_user_maxspeed(g_iRoller,250.0)
	set_user_godmode(g_iRoller,0)
	set_user_noclip(g_iRoller,0)
	set_user_rendering(g_iRoller,kRenderFxNone,0,0,0,kRenderNormal,16)

	if(bPlayerStuck(g_iRoller)) fakedamage(g_iRoller,"player",10000.0,DMG_GENERIC)

	g_iRoller=0
	g_iCount=0
	g_iPrize=0

	if(bInterrupted) client_print(0,print_chat,"%s %s left, %s duration was interrupted.",PREFIX,g_szRoller,g_szPrize)

	g_szRoller[0]='^0'
	g_szPrize[0]='^0'
}

public client_disconnect(id) {
	if(g_iRoller==id) {
		RemovePrize(true)
	}
}

public fwdPlayerKilled(id) {
	if(g_iRoller==id) {
		if(g_iPrize==PRIZE_TIMEBOMB) {
			if(task_exists(BombTask)) {
				remove_task(BombTask)
				fnEndBomb()
			}
		} else if(g_iPrize==PRIZE_BURN) {
			if(task_exists(IgniteTask+id)) remove_task(IgniteTask+id)
			if(task_exists(BurnTask+id)) remove_task(BurnTask+id)
			emit_sound(id,CHAN_AUTO,"scientist/scream21.wav",0.6,ATTN_NORM,0,PITCH_HIGH)
		}

		RemovePrize(false)
	}
}

public fnEndCoolDown(iTaskID) {
	new id=(iTaskID-CDTask)
	g_bCoolDown[id]=false

	if(is_user_connected(id)) client_print(id,print_chat,"%s Your cooldown has expired.",PREFIX)
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

public cmdRollTheDice(id) {
	if(!is_user_alive(id)) {
		client_print(id,print_chat,"%s You must be alive.",PREFIX)
		return PLUGIN_HANDLED
	} else if(g_iRoller) {
		client_print(id,print_chat,"%s %s still has a prize %s.",PREFIX,g_szRoller,g_szPrize)
		return PLUGIN_HANDLED
	} else if(g_iGlobalCD>get_systime()) {
		client_print(id,print_chat,"%s Global cooldown still active.",PREFIX)
		return PLUGIN_HANDLED
	} else if(g_bCoolDown[id]) {
		client_print(id,print_chat,"%s You're still on cooldown.",PREFIX)
		return PLUGIN_HANDLED
	}

	g_bCoolDown[id]=true
	set_task(AMOUNT_CD,"fnEndCoolDown",(CDTask+id))

	g_iRoller=id
	get_user_name(g_iRoller,g_szRoller,31)
	switch(random_num(1,9)) {
		case PRIZE_CHICKENS: {
			g_iPrize=PRIZE_CHICKENS
			copy(g_szPrize,31,"100Chickens")
			client_print(0,print_chat,"%s %s won %d chickens.",PREFIX,g_szRoller,AMOUNT_CHICKEN)
			emit_sound(g_iRoller,CHAN_ITEM,"misc/chicken4.wav",1.0,ATTN_NORM,0,PITCH_NORM)
			set_task(0.3,"fnThrowChickens")
		}
		case PRIZE_NOCLIP: {
			g_iPrize=PRIZE_NOCLIP
			copy(g_szPrize,31,"NoClip")
			client_print(0,print_chat,"%s %s won noclip for %d seconds.",PREFIX,g_szRoller,AMOUNT_NOCLIP)
			set_user_noclip(g_iRoller,1)
			set_user_maxspeed(g_iRoller,700.0)
			set_user_rendering(g_iRoller,kRenderFxGlowShell,random(256),random(256),random(256),kRenderNormal,16)
			emit_sound(g_iRoller,CHAN_ITEM,"misc/kotosting.wav",1.0,ATTN_NORM,0,PITCH_NORM)
			set_task(0.1,"fnNoClip")
		}
		case PRIZE_GODMODE: {
			g_iPrize=PRIZE_GODMODE
			copy(g_szPrize,31,"GodMode")
			client_print(0,print_chat,"%s %s won godmode for %d seconds.",PREFIX,g_szRoller,AMOUNT_GODMODE)
			set_user_godmode(g_iRoller,1)
			set_user_rendering(g_iRoller,kRenderFxGlowShell,random(256),random(256),random(256),kRenderNormal,16)
			emit_sound(g_iRoller,CHAN_ITEM,"misc/stinger12.wav",1.0,ATTN_NORM,0,PITCH_NORM)
			set_task(0.1,"fnGodMode")
		}
		case PRIZE_SKYWALKER: {
			g_iPrize=PRIZE_SKYWALKER
			copy(g_szPrize,31,"SkyWalker")
			client_print(0,print_chat,"%s %s won luke skywalker for %d seconds.",PREFIX,g_szRoller,AMOUNT_SKYWALKER)
			set_user_godmode(g_iRoller,1)
			set_task(1.0,"LightSaberTimer")
			set_task(0.1,"fnLightSaber")
			emit_sound(g_iRoller,CHAN_ITEM,"ambience/zapmachine.wav",1.0,ATTN_NORM,0,PITCH_NORM)
		}
		case PRIZE_ZUES: {
			g_iPrize=PRIZE_ZUES
			copy(g_szPrize,31,"ZuesMode")
			client_print(0,print_chat,"%s %s won zuesmode for %d seconds.",PREFIX,g_szRoller,AMOUNT_ZUES)
			set_user_godmode(g_iRoller,1)
			set_user_noclip(g_iRoller,1)
			set_user_maxspeed(g_iRoller,700.0)
			set_user_rendering(g_iRoller,kRenderFxGlowShell,random(256),random(256),random(256),kRenderNormal,16)
			emit_sound(g_iRoller,CHAN_ITEM,"misc/risamalo.wav",1.0,ATTN_NORM,0,PITCH_NORM)
			set_task(1.0,"fnZuesMode")
		}
		case PRIZE_LIGHTNING: {
			g_iPrize=PRIZE_LIGHTNING
			copy(g_szPrize,31,"Lightning")
			client_print(0,print_chat,"%s %s was struck by lightning!",PREFIX,g_szRoller)
			new origin[3]
			get_user_origin(g_iRoller,origin)
			origin[2] = origin[2] - 26
			new sorigin[3]
			sorigin[0] = origin[0] + 150; sorigin[1] = origin[1] + 150; sorigin[2] = origin[2] + 400
			lightning(sorigin,origin)
			emit_sound(g_iRoller,CHAN_ITEM,"ambience/thunder_clap.wav",1.0,ATTN_NORM,0,PITCH_NORM)
			fakedamage(g_iRoller,"player",10000.0,DMG_GENERIC)
		}
		case PRIZE_RACECAR: {
			g_iPrize=PRIZE_RACECAR
			copy(g_szPrize,31,"RaceCar")
			set_user_health(g_iRoller,150)
			emit_sound(g_iRoller,CHAN_ITEM,"misc/bipbip.wav",1.0,ATTN_NORM,0,PITCH_NORM)
			set_user_maxspeed(g_iRoller,1000.0)
			set_user_rendering(g_iRoller,kRenderFxGlowShell,random(256),random(256),random(256),kRenderNormal,16)
			set_task(0.1,"RaceCarTimer")
		}
		case PRIZE_SLAP: {
			g_iPrize=PRIZE_SLAP
			copy(g_szPrize,31,"SlapDisease")
			client_print(0,print_chat,"%s %s now has slap disease.",PREFIX,g_szRoller)
			set_task(0.1,"SlapTimer")
		}
		case PRIZE_TIMEBOMB: {
			g_iPrize=PRIZE_TIMEBOMB
			copy(g_szPrize,31,"TimeBomb")
			client_print(0,print_chat,"%s %s is now a timebomb!",PREFIX,g_szRoller)
			client_cmd(0,"spk ^"warning _comma detonation device activated^"")
			player_attachment(g_iRoller)
			set_task(AMOUNT_TIMEBOMB,"fnEndBomb",BombTask)
		}
		case PRIZE_BURN: {
			g_iPrize=PRIZE_BURN
			copy(g_szPrize,31,"Burn")
			client_print(0,print_chat,"%s %s caught on fire!",PREFIX,g_szRoller)
			set_task(0.1,"ignite_effects",(BurnTask+g_iRoller))
			set_task(0.1,"ignite_player",(IgniteTask+g_iRoller))
		}
	}

	return PLUGIN_HANDLED
}

public fnEndBomb() {
	new origin[3]
	get_user_origin(g_iRoller,origin)
	origin[2] = origin[2]-26

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY,{0,0,0},g_iRoller)
	write_byte(107)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_coord(175)
	write_short(mdlGibs)
	write_short(25)
	write_byte(100)
	message_end()

	entity_set_int(g_iRoller,EV_INT_effects,entity_get_int(g_iRoller,EV_INT_effects) | EF_NODRAW)

	new players[32],player,num = find_sphere_class(g_iRoller,"player",BOMBKILL_RANGE,players,sizeof(players))
	for(--num; num>=0; num--) {
		player = players[num]
		user_kill(player,1)
		explode(origin,player)

		message_begin(MSG_ONE,g_msgShake,{0,0,0},player)
		write_short(1<<14)
		write_short(1<<14)
		write_short(1<<14)
		message_end()
    }
}

public player_attachment(id) {
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY,{0,0,0},id)
	write_byte(124)
	write_byte(id)
	write_coord(7)
	write_short(mdlC4bomb)
	write_short(255)
	message_end()
}

public explode(vec1[3],id) {
	// blast circles 
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY,vec1);
	write_byte(21); write_coord(vec1[0]); write_coord(vec1[1]); write_coord(vec1[2] + 16); write_coord(vec1[0]); write_coord(vec1[1]);
	write_coord(vec1[2] + 1936); write_short(sprWhite); write_byte(0); write_byte(0); write_byte(3); write_byte(20); write_byte(0);
	write_byte(188); write_byte(220); write_byte(255); write_byte(255); write_byte(0); message_end(); 
    
	// Explosion2 
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); write_byte(12); write_coord(vec1[0]);
	write_coord(vec1[1]); write_coord(vec1[2]); write_byte(188); write_byte(10); message_end();

	// TE_Explosion 
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY,vec1); write_byte(3); write_coord(vec1[0]); write_coord(vec1[1]); write_coord(vec1[2]);
	write_short(sprFire); write_byte(65); write_byte(10); write_byte(0); message_end();

	// TE_KILLPLAYERATTACHMENTS
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY,{0,0,0},id); write_byte(125); write_byte(id); message_end()

	// Smoke 
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY,vec1); write_byte(5); write_coord(vec1[0]); write_coord(vec1[1]); write_coord(vec1[2]);
	write_short(sprSmoke); write_byte(50); write_byte(10); message_end();
}

public SlapTimer() {
	if(!g_iRoller) return PLUGIN_CONTINUE

	user_slap(g_iRoller,5)
	if(is_user_alive(g_iRoller)) {
		set_user_rendering(g_iRoller,kRenderFxGlowShell,random(256),random(256),random(256),kRenderNormal,16)

		if(g_iCount<AMOUNT_SLAP) {
			set_task(1.0,"SlapTimer")
			g_iCount++
		} else {
			client_print(0,print_chat,"%s %s no longer has slap disease.",PREFIX,g_szRoller)
			RemovePrize(false)
		}
	}

	return PLUGIN_CONTINUE
}

public RaceCarTimer() {
	if(!g_iRoller) return PLUGIN_CONTINUE

	client_cmd(g_iRoller,"cl_forwardspeed 1000")

	if(g_iCount<AMOUNT_RACECAR) {
		set_task(1.0,"RaceCarTimer")
		g_iCount++
	} else {
		client_print(0,print_chat,"%s %s no longer has racecar.",PREFIX,g_szRoller)
		RemovePrize(false)
	}

	return PLUGIN_CONTINUE
}

lightning(vec1[3],vec2[3]) {
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(0)
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_coord(vec2[0])
	write_coord(vec2[1])
	write_coord(vec2[2])
	write_short(sprLightning)
	write_byte(1)
	write_byte(5)
	write_byte(2)
	write_byte(20)
	write_byte(30)
	write_byte(200)
	write_byte(200)
	write_byte(200)
	write_byte(200)
	write_byte(200)
	message_end()

	message_begin(MSG_PVS,SVC_TEMPENTITY,vec2)
	write_byte(9)
	write_coord(vec2[0])
	write_coord(vec2[1])
	write_coord(vec2[2])
	message_end()
  
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY,vec2)
	write_byte(5)
	write_coord(vec2[0])
	write_coord(vec2[1])
	write_coord(vec2[2])
	write_short(sprSmoke)
	write_byte(10)
	write_byte(10)
	message_end()
}

public fnZuesMode() {
	if(!g_iRoller) return PLUGIN_CONTINUE

	client_cmd(g_iRoller,"cl_forwardspeed 700")

	if(g_iCount<AMOUNT_ZUES) {
		set_task(1.0,"fnZuesMode")
		g_iCount++
	} else {
		client_print(0,print_chat,"%s %s no longer has zuesmode.",PREFIX,g_szRoller)
		RemovePrize(false)
	}

	return PLUGIN_CONTINUE
}

public LightSaberTimer() {
	if(!g_iRoller) return PLUGIN_CONTINUE

	if(g_iCount<AMOUNT_SKYWALKER) {
		set_task(1.0,"LightSaberTimer")
		g_iCount++
	} else {
		client_print(0,print_chat,"%s %s is no longer luke skywalker.",PREFIX,g_szRoller)
		RemovePrize(false)
	}

	return PLUGIN_CONTINUE
}

public sqrt(num) {
	new div = num
	new result = 1

	while (div > result) {
		div = (div + result) / 2
		result = num / div
	}

	return div
}

public fnLightSaber() {
	if(!g_iRoller) return PLUGIN_CONTINUE

	new vec[3],aimvec[3],lseffvec[3],length,speed=65,vorigin[3]
	get_user_origin(g_iRoller,vec,1)
	get_user_origin(g_iRoller,aimvec,2)
	lseffvec[0]=aimvec[0]-vec[0]
	lseffvec[1]=aimvec[1]-vec[1]
	lseffvec[2]=aimvec[2]-vec[2]
	length=sqrt(lseffvec[0]*lseffvec[0]+lseffvec[1]*lseffvec[1]+lseffvec[2]*lseffvec[2])
	lseffvec[0]=lseffvec[0]*speed/length
	lseffvec[1]=lseffvec[1]*speed/length
	lseffvec[2]=lseffvec[2]*speed/length

	for(new id=1; id<=32; id++) {
		if(is_user_alive(id)) {
			if(id!=g_iRoller) {
				get_user_origin(id,vorigin)
				if(get_distance(vec,vorigin)<100) {
					if(get_user_team(g_iRoller)!=get_user_team(id)) {
						kill_player(id,g_iRoller)
						switch(random_num(0,3)) {
							case 0: emit_sound(id,CHAN_VOICE,"misc/gemido01.wav",VOL_NORM,ATTN_NORM,0,PITCH_NORM)
							case 1: emit_sound(id,CHAN_VOICE,"misc/gemido02.wav",VOL_NORM,ATTN_NORM,0,PITCH_NORM)
							case 2: emit_sound(id,CHAN_VOICE,"misc/gemido03.wav",VOL_NORM,ATTN_NORM,0,PITCH_NORM)
							case 3: emit_sound(id,CHAN_VOICE,"misc/gemido04.wav",VOL_NORM,ATTN_NORM,0,PITCH_NORM)
						}
					}
				}
			}
		}
	}

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(1)
	write_short(g_iRoller)
	write_coord(lseffvec[0]+vec[0])
	write_coord(lseffvec[1]+vec[1])
	write_coord(lseffvec[2]+vec[2]+10)
	write_short(sprSaber)
	write_byte(0)
	write_byte(15)
	write_byte(1)
	write_byte(20)
	write_byte(5)
	write_byte(0)
	write_byte(255)
	write_byte(0)
	write_byte(255)
	write_byte(10)
	message_end()

	set_task(0.1,"fnLightSaber")

	return PLUGIN_CONTINUE;
}

public kill_player(iVictim,iAttacker) {
	user_silentkill(iVictim)
	message_begin(MSG_ALL,get_user_msgid("DeathMsg"),{0,0,0},0)
	write_byte(iAttacker)
	write_byte(iVictim)
	write_byte(0)
	switch(g_iPrize) {
		case PRIZE_SKYWALKER: write_string("lightsaber")
		default: write_string("blank")
	}
	message_end()
}

public fnGodMode() {
	if(!g_iRoller) return PLUGIN_CONTINUE

	if(g_iCount<AMOUNT_GODMODE) {
		set_task(1.0,"fnGodMode")
		g_iCount++
	} else {
		client_print(0,print_chat,"%s %s no longer has godmode.",PREFIX,g_szRoller)
		RemovePrize(false)
	}

	return PLUGIN_CONTINUE
}

public fnNoClip() {
	if(!g_iRoller) return PLUGIN_CONTINUE

	if(g_iCount<AMOUNT_NOCLIP) {
		set_task(1.0,"fnNoClip")
		g_iCount++
	} else {
		client_print(0,print_chat,"%s %s no longer has noclip.",PREFIX,g_szRoller)
		RemovePrize(false)
	}

	return PLUGIN_CONTINUE
}

public fnThrowChickens() {
	if(!g_iRoller) return PLUGIN_CONTINUE

	static vec[3]
	static aimvec[3]
	static velocityvec[3]

	static speed = 800
	get_user_origin(g_iRoller,vec)
	get_user_origin(g_iRoller,aimvec,2)

	velocityvec[0]=aimvec[0]-vec[0]
	velocityvec[1]=aimvec[1]-vec[1]
	velocityvec[2]=aimvec[2]-vec[2]

	new length=sqrt(velocityvec[0]*velocityvec[0]+velocityvec[1]*velocityvec[1]+velocityvec[2]*velocityvec[2])

	velocityvec[0]=velocityvec[0]*speed/length
	velocityvec[1]=velocityvec[1]*speed/length
	velocityvec[2]=velocityvec[2]*speed/length

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(106)
	write_coord(vec[0])
	write_coord(vec[1])
	write_coord(vec[2]+20)
	write_coord(velocityvec[0])
	write_coord(velocityvec[1])
	write_coord(velocityvec[2]+100)
	write_angle(0)
	write_short(mdlChicken)
	write_byte(2)
	write_byte(255)
	message_end()

	if(g_iCount<AMOUNT_CHICKEN) {
		set_task(0.3,"fnThrowChickens")
		g_iCount++
	} else {
		client_print(0,print_chat,"%s %s ran out of chickens.",PREFIX,g_szRoller)
		RemovePrize(false)
	}

	return PLUGIN_CONTINUE
}

public plugin_precache() {
	mdlChicken = precache_model("models/chick.mdl")
	mdlGibs = precache_model("models/hgibs.mdl")
	precache_sound("misc/chicken4.wav")
	precache_sound("misc/kotosting.wav")
	precache_sound("misc/stinger12.wav")
	precache_sound("misc/gemido01.wav")
	precache_sound("misc/gemido02.wav")
	precache_sound("misc/gemido03.wav")
	precache_sound("misc/gemido04.wav")
	precache_sound("misc/risamalo.wav")
	precache_sound("ambience/flameburst1.wav")
	precache_sound("misc/bipbip.wav")
	precache_sound("ambience/thunder_clap.wav")
	precache_sound("scientist/scream21.wav")
	precache_sound("scientist/scream07.wav")
	sprSmoke = precache_model("sprites/steam1.spr")
	sprLightning = precache_model("sprites/lgtning.spr")
	sprSaber = precache_model("sprites/laserbeam.spr")
	sprFire = precache_model("sprites/explode1.spr")
	sprMflash = precache_model("sprites/muzzleflash.spr")
	sprWhite = precache_model("sprites/white.spr")
	mdlC4bomb = precache_model("models/w_weaponbox.mdl")
}
