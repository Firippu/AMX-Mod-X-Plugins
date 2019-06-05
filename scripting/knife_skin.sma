/* Description;
	simple method to change the knife skin
*/

#include <amxmodx>
#include <cstrike>
#include <fakemeta>

#define KNIFE_MODEL "models/dir/v_modelname.mdl"

public plugin_init() {
	register_plugin("knife_skin","0.1","Firippu")

	register_event("CurWeapon","WeaponSwitch","be","1=1")
}

public WeaponSwitch(id) {
	switch(read_data(2)) {
		case CSW_KNIFE: {
			set_pev(id,pev_viewmodel2,KNIFE_MODEL)
		}
	}
}

public plugin_precache() {
	precache_model(KNIFE_MODEL)
}
