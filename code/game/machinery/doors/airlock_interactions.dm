/*
	Moved the non-airlock procs in airlock.dm to here.
*/

//*** Blocking Airlocks

/atom/movable/proc/blocks_airlock()
	return density

/obj/machinery/door/blocks_airlock()
	return 0

/obj/structure/window/blocks_airlock()
	return 0

/obj/machinery/mech_sensor/blocks_airlock()
	return 0

/mob/living/blocks_airlock()
	return 1

//*** Airlock Crushing

#define AIRLOCK_CRUSH_DIVISOR 8 // Damage caused by airlock crushing a mob is split into multiple smaller hits. Prevents things like cut off limbs, etc, while still having quite dangerous injury.
#define CYBORG_AIRLOCKCRUSH_RESISTANCE 4 // Damage caused to silicon mobs (usually cyborgs) from being crushed by airlocks is divided by this number. Unlike organics cyborgs don't have passive regeneration, so even one hit can be devastating for them.

/atom/movable/proc/airlock_crush(var/crush_damage)
	return 0

/obj/structure/window/airlock_crush(var/crush_damage)
	ex_act(2)//Smashin windows

/obj/machinery/portable_atmospherics/canister/airlock_crush(var/crush_damage)
	. = ..()
	health -= crush_damage
	healthcheck()

/obj/effect/energy_field/airlock_crush(var/crush_damage)
	Stress(crush_damage)

/obj/structure/closet/airlock_crush(var/crush_damage)
	..()
	damage(crush_damage)
	for(var/atom/movable/AM in src)
		AM.airlock_crush()
	return 1

/mob/living/airlock_crush(var/crush_damage)
	. = ..()
	for(var/i = 1, i <= AIRLOCK_CRUSH_DIVISOR, i++)
		adjustBruteLoss(round(crush_damage / AIRLOCK_CRUSH_DIVISOR))
	SetStunned(5)
	SetWeakened(5)
	var/turf/T = get_turf(src)
	T.add_blood(src)
	var/list/valid_turfs = list()
	for(var/dir_to_test in cardinal)
		var/turf/new_turf = get_step(T, dir_to_test)
		if(!new_turf.contains_dense_objects())
			valid_turfs |= new_turf

	while(valid_turfs.len)
		T = pick(valid_turfs)
		valid_turfs -= T
		// Try to move us to the turf. If all turfs fail for some reason we will stay on this tile.
		if(src.Move(T))
			return

/mob/living/carbon/airlock_crush(var/crush_damage)
	. = ..()
	if (!(species && (species.flags & NO_PAIN)))
		emote("scream")

/mob/living/silicon/robot/airlock_crush(var/crush_damage)
	return ..(round(crush_damage / CYBORG_AIRLOCKCRUSH_RESISTANCE))