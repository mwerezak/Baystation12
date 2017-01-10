/*
	The purpose of ceilings is to allow turfs to pair with the turf above so that the two stay together
	during shuttle movement. In addition, if a turf moves into a z-level that does not have another z-level
	above, data about its ceiling (the paired turf) is stored so that the ceiling can be recreated once the
	turf is transported back to a muli-z location.
*/

/turf/simulated/var/ceiling = null

/datum/ceiling
	var/turf/parent

	var/ceiling_type = /turf/simulated/floor/airless
	var/turf/instance
	var/list/instance_data

	var/replaced_type // HACK we rely on the fact that /turf/space and /turf/simulated/open can be recreated identically without storing any information. So we don't need a replaced_data

/datum/ceiling/proc/stow_instance()
	if(!instance)
		return //not deployed, possibly because the turf above wasn't empty

	ceiling_type = instance.type
	instance_data = instance.vars.Copy() //this may not work
	instance = null

	ChangeTurf(replaced_type, 1, 1) //restore the replaced turf

/datum/ceiling/proc/restore_instance()
	var/turf/above = GetAbove()
	if(!above || !empty_turf(above))
		return

	replaced_type = above.type
	instance = above
	instance.ChangeType(ceiling_type, 1, 1)
	for(var/varname in instance_data)
		instance.vars[varname] = instance_data[varname]

/datum/ceiling/proc/empty_turf(var/turf/above) //idk
	if(istype(above, /turf/space) || istype(above, /turf/simulated/open))
		return TRUE
	return FALSE

