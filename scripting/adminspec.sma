#include <amxmodx>
#include <amxmisc>
#include <cstrike>

#define VERSION "0.0.1"

new args[128]

public plugin_init() {
	register_plugin("adminspec",VERSION,"Firippu")

	register_concmd("say","cmd_hook")
}

public cmd_hook(id) {
	if(is_user_admin(id)) {
		read_args(args,charsmax(args))
		remove_quotes(args)

		if(equali(args,"/spec")) {
			user_silentkill(id)
			cs_set_user_team(id,CS_TEAM_SPECTATOR)
			return PLUGIN_HANDLED
		} else if(equali(args,"/te")) {
			user_silentkill(id)
			cs_set_user_team(id,CS_TEAM_T)
			return PLUGIN_HANDLED
		} else if(equali(args,"/ct")) {
			user_silentkill(id)
			cs_set_user_team(id,CS_TEAM_CT)
			return PLUGIN_HANDLED
		}
	}

	return PLUGIN_CONTINUE
}
