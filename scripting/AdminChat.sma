/*
description:
	allows admins to see chat messages from both teams

commands:
	"say /adminchat" // toggles the feature
*/

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>

#define VERSION "0.0.5a"
#define ADMRFLAG ADMIN_KICK
#define PREFIX "[Admin-Chat]"
#define MAX_NOTIFY 2

new g_iMaxPlayers
new g_MsgSayText
new g_TeamInfo

new bool:g_bEnabled[33]
new g_iNotified[33]

public plugin_init() {
	register_plugin("AdminChat",VERSION,"Firippu")

	g_iMaxPlayers=get_maxplayers()
	g_MsgSayText=get_user_msgid("SayText")
	g_TeamInfo=get_user_msgid("TeamInfo")

	RegisterHam(Ham_Spawn,"player","fwdPlayerSpawn",1)

	register_clcmd("say","cmd_say")
	register_clcmd("say_team","cmd_sayteam")
}

public fwdPlayerSpawn(id) {
	if(is_user_alive(id)) {
		if((get_user_flags(id) & ADMRFLAG) && (g_iNotified[id]<MAX_NOTIFY)) {
			g_iNotified[id]++
			client_print(id,print_chat,"%s Need to monitor all chat messages? type /adminchat",PREFIX)
		}
	}
}

public cmd_say(id) return say_hook(id,false)
public cmd_sayteam(id) return say_hook(id,true)

public changeTeamInfo(player,team[]) {
	message_begin(MSG_ONE,g_TeamInfo,_,player)
	write_byte(player)
	write_string(team)
	message_end()
}

public SendMsg(iSender,iSender_Team,iReceiver,iReceiver_Team,szMessage[]) {
	switch(iSender_Team) {
		case 1: changeTeamInfo(iReceiver,"TERRORIST")
		case 2: changeTeamInfo(iReceiver,"CT")
		case 3: changeTeamInfo(iReceiver,"SPECTATOR")
	}

	message_begin(MSG_ONE,g_MsgSayText,{0,0,0},iReceiver)
	write_byte(iReceiver)
	write_string(szMessage)
	message_end()

	switch(iReceiver_Team) {
		case 1: changeTeamInfo(iReceiver,"TERRORIST")
		case 2: changeTeamInfo(iReceiver,"CT")
		case 3: changeTeamInfo(iReceiver,"SPECTATOR")
	}
}

public client_disconnect(id) g_bEnabled[id]=false
public client_authorized(id) {
	g_bEnabled[id]=false
	g_iNotified[id]=0
}

public say_hook(iSender,bSayTeam) {
	new iSender_Team=get_user_team(iSender)
	new iReceiver_Team

	static szMessage[128]
	read_args(szMessage,charsmax(szMessage))
	remove_quotes(szMessage)

	if(strlen(szMessage)<1) {
		return PLUGIN_HANDLED
	}

	static szMessage2[128]
	szMessage2[0]='^0'
	static szCommand[128]
	szCommand[0]='^0'

	strcat(szMessage2,szMessage,127)
	strbreak(szMessage2,szCommand,charsmax(szCommand),szMessage2,charsmax(szMessage2))

	if(equali(szCommand,"/adminchat")) {
		if((get_user_flags(iSender) & ADMRFLAG) || g_bEnabled[iSender]) {
			g_bEnabled[iSender]=!g_bEnabled[iSender]
			if(g_bEnabled[iSender]) {
				client_print(iSender,print_chat,"%s Enabled",PREFIX)
			} else {
				client_print(iSender,print_chat,"%s Disabled",PREFIX)
			}
		} else {
			client_print(iSender,print_chat,"%s You do not meet conditions.",PREFIX)
		}

		return PLUGIN_HANDLED
	}

	new bool:bSenderAlive=false
	new bool:bReceiverAlive=false

	if(is_user_alive(iSender)) bSenderAlive=true

	static szUserName[32]
	get_user_name(iSender,szUserName,31)

	static message[192]

	for(new iReceiver=1; iReceiver<=g_iMaxPlayers; iReceiver++) {
		if(is_user_connected(iReceiver)) {
			if(iSender_Team==3 && !(get_user_flags(iReceiver) & ADMRFLAG)) {
				return PLUGIN_CONTINUE
			} else {
				message[0]='^0'
				iReceiver_Team=get_user_team(iReceiver)
				bReceiverAlive=false
				if(is_user_alive(iReceiver)) bReceiverAlive=true
				if((get_user_flags(iReceiver) & ADMRFLAG) && (iSender!=iReceiver) && g_bEnabled[iReceiver]) {
					if(bSayTeam) {
						format(message,191,"^x01%s ^x03%s ^x01:  %s",bSenderAlive ? (iSender_Team==1 ? "(Terrorist)":"(Counter-Terrorist)"):(iSender_Team==1 ? "*DEAD*(Terrorist)":"*DEAD*(Counter-Terrorist)"),szUserName,szMessage)
					} else {
						format(message,191,"^x01%s ^x03%s ^x01:  %s",bSenderAlive ? "":"*DEAD*",szUserName,szMessage)
					}

					SendMsg(iSender,iSender_Team,iReceiver,iReceiver_Team,message)
				} else if(bSayTeam) {
					if(iSender_Team==iReceiver_Team) {
						if((bSenderAlive && !bReceiverAlive) || (bSenderAlive && bReceiverAlive)) {
							format(message,191,"^x01%s ^x03%s ^x01:  %s",iSender_Team==1 ? "(Terrorist)":"(Counter-Terrorist)",szUserName,szMessage)
						} else if(!bSenderAlive && !bReceiverAlive) {
							format(message,191,"^x01*DEAD*%s ^x03%s ^x01:  %s",iSender_Team==1 ? "(Terrorist)":"(Counter-Terrorist)",szUserName,szMessage)
						}

						SendMsg(iSender,iSender_Team,iReceiver,iReceiver_Team,message)
					}
				} else {
					if((bSenderAlive && !bReceiverAlive) || (bSenderAlive && bReceiverAlive)) {
						format(message,191,"^x03%s ^x01:  %s",szUserName,szMessage)
					} else if((!bSenderAlive && !bReceiverAlive)) {
						format(message,191,"^x01*DEAD* ^x03%s ^x01:  %s",szUserName,szMessage)
					}

					SendMsg(iSender,iSender_Team,iReceiver,iReceiver_Team,message)
				}
			}
		}
	}

	return PLUGIN_HANDLED_MAIN
}
