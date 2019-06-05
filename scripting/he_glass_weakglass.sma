/* Description;
	This plugin allows the weakening & breaking of glass when a player stands on it
*/

#include <amxmodx>
#include <engine>

public plugin_init() {
	register_plugin("weakglass","1.0","Firippu")

	new mapname[10]
	get_mapname(mapname,9)

	if(equali(mapname,"he_glass")) {
		register_touch("func_breakable","player","fwdPlayerTouch")
	}
}

public fwdPlayerTouch(iEntity) {
	fakedamage(iEntity,"func_breakable",1.0,0)
}
