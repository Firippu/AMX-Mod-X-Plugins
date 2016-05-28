#include <amxmodx>
#include <hamsandwich>
#include <engine>

#define VERSION "1.1"

#define PREFIX "[NoKillZones]"

#define CONFIG_DIR "NoKillZones"
#define FILE_EXT "ini"

#define MAX_COORDS 10

#define DMG_HEGRENADE (1<<24)

new Float:g_flCoords[2][MAX_COORDS][3]

new g_iZone
new g_iFor

public plugin_init() {
	register_plugin("NoKillZones",VERSION,"Firippu")

	new szMapName[32]
	get_mapname(szMapName,31)

	new szFile[128],szConfigsDir[64]
	get_localinfo("amxx_configsdir",szConfigsDir,charsmax(szConfigsDir))
	format(szFile,charsmax(szFile),"%s/%s/%s.%s",szConfigsDir,CONFIG_DIR,szMapName,FILE_EXT)

	if(!file_exists(szFile)) {
		log_amx("%s coordinate file not found: %s",PREFIX,szMapName)
		return PLUGIN_HANDLED
	}

	log_amx("%s coordinate file found: %s",PREFIX,szMapName)

	new hFile=fopen(szFile,"rt")
	if(!hFile) {
		log_amx("%s coordinate file could not open: %s",PREFIX,szMapName)
		return PLUGIN_HANDLED
	}

	log_amx("%s coordinate file opened: %s",PREFIX,szMapName)

	new szCoord[6][6]
	while(!feof(hFile)) {
		if(g_iZone>=MAX_COORDS) {
			log_amx("%s maximum (%d) coordinates occurred; ending parse.",PREFIX,MAX_COORDS)
			break
		}

		static szLine[128]
		fgets(hFile,szLine,charsmax(szLine))

		for(g_iFor=0; g_iFor<6; g_iFor++) {
			szCoord[g_iFor][0]='^0'
		}

		parse(szLine,szCoord[0],5,szCoord[1],5,szCoord[2],5,szCoord[3],5,szCoord[4],5,szCoord[5],5)

		for(g_iFor=0; g_iFor<3; g_iFor++) {
			if(str_to_num(szCoord[g_iFor]) >= str_to_num(szCoord[g_iFor+3])) {
				goto skip;
			}
		}

		g_flCoords[0][g_iZone][0] = str_to_float(szCoord[0]); g_flCoords[0][g_iZone][1] = str_to_float(szCoord[1]); g_flCoords[0][g_iZone][2] = str_to_float(szCoord[2])
		g_flCoords[1][g_iZone][0] = str_to_float(szCoord[3]); g_flCoords[1][g_iZone][1] = str_to_float(szCoord[4]); g_flCoords[1][g_iZone][2] = str_to_float(szCoord[5])

		log_amx("%s coordinate loaded: %f %f %f %f %f %f",PREFIX,g_flCoords[0][g_iZone][0],g_flCoords[0][g_iZone][1],g_flCoords[0][g_iZone][2],g_flCoords[1][g_iZone][0],g_flCoords[1][g_iZone][1],g_flCoords[1][g_iZone][2])
		g_iZone++

		skip:
	}

	fclose(hFile)

	if(!g_iZone) {
		log_amx("%s no valid coordinates detected.",PREFIX)
		return PLUGIN_HANDLED
	}

	RegisterHam(Ham_TraceAttack,"player","fwdTraceAttack")
	RegisterHam(Ham_TakeDamage,"player","fwdTakeDamage")

	return PLUGIN_CONTINUE
}

public fwdTakeDamage(iVictim,iInflictor,iAttacker,Float:damage,damagebits) {
	if(damagebits == DMG_HEGRENADE) {
		return fwdTraceAttack(iVictim,iAttacker)
	}

	return HAM_IGNORED
}

public fwdTraceAttack(iVictim,iAttacker) {
	static Float:flVictimOrigin[3],Float:flAttackerOrigin[3]

	entity_get_vector(iVictim,EV_VEC_origin,flVictimOrigin)
	entity_get_vector(iAttacker,EV_VEC_origin,flAttackerOrigin)

	for(g_iFor=0; g_iFor<g_iZone; g_iFor++) {
		if(bInSafeZone(g_iFor,flVictimOrigin) || bInSafeZone(g_iFor,flAttackerOrigin)) {
			engclient_print(iAttacker,engprint_center,"%s Prevented Outgoing Damage",PREFIX)
			engclient_print(iVictim,engprint_center,"%s Prevented Incoming Damage",PREFIX)

			return HAM_SUPERCEDE
		}
	}

	return HAM_IGNORED
}

public bool:bInSafeZone(iZone,Float:flPlayerOrigin[3]) {
	if(flPlayerOrigin[0]>g_flCoords[0][iZone][0] && flPlayerOrigin[0]<g_flCoords[1][iZone][0]
	&& flPlayerOrigin[1]>g_flCoords[0][iZone][1] && flPlayerOrigin[1]<g_flCoords[1][iZone][1]
	&& flPlayerOrigin[2]>g_flCoords[0][iZone][2] && flPlayerOrigin[2]<g_flCoords[1][iZone][2]) {
		return true
	}

	return false
}
