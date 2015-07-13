
/obj/effect/liquidjet
	name = "liquid jet"
	var/lit_temperature		//if the liquid jet has been lit on fire
	var/throw_counter = 0	//how far we need to move before we start splashing liquidfuel
	var/transfer_amount		//How much liquid fuel to drop each step

/obj/effect/liquidjet/New(var/newloc, var/volume, var/datum/reagents/supply, var/throwrange, var/launch_dist, var/burntemp = 0)
	..(newloc)
	lit_temperature = burntemp //TODO set sprites (and luminosity?) accordingly
	throw_range = throwrange
	transfer_amount = volume/(throw_range - launch_dist)
	throw_counter = launch_dist
	
	create_reagents(volume)
	supply.trans_to_holder(reagents, volume)

/obj/effect/liquidjet/Move()
	. = ..()
	if(.)
		if(throw_counter)
			throw_counter--
		else
			drop_contents(transfer_amount)
		
		var/turf/T = loc
		if(lit_temperature && istype(T))
			T.hotspot_expose(lit_temperature, transfer_amount)
		
		if(!reagents.total_volume)
			qdel(src)

/obj/effect/liquidjet/proc/drop_contents(var/amount)
	var/datum/reagents/splash_holder = new(amount)
	reagents.trans_to_holder(splash_holder, amount)
	splash_holder.splash(loc, amount) //the liquid fuel reagent will handle the puddle creation on it's own

//If we hit something prematurely, splash all of the remaining fuel on it
/obj/effect/liquidjet/throw_impact(atom/hit_atom, var/speed)
	reagents.splash(hit_atom, reagents.total_volume)
	qdel(src)

/obj/item/weapon/gun/launcher/flamethrower
	name = "flamethrower"
	desc = "A liquid fuel flamethrower."
	icon_state = "pneumatic"
	item_state = "pneumatic"
	slot_flags = SLOT_BELT
	w_class = 5
	flags =  CONDUCT
	fire_sound_text = "flamethrower sounds" //TODO
	fire_delay = 50 //TODO
	fire_sound = 'sound/weapons/tablehit1.ogg' //TODO

	// Tank of propellant gas - pressure is used to determine how much fuel is launched and how far it travels.
	// High pressure = welding fuel fire hose, low pressure = squirt gun
	var/obj/item/weapon/tank/tank = null
	var/obj/fuel_supply = null

	var/pressure_setting = 10                           // Percentage of the gas in the tank used to fire the projectile.
	var/possible_pressure_amounts = list(5,10,20,25,50) // Possible pressure settings.

/*
/obj/item/weapon/gun/launcher/pneumatic/New()
	..()

/obj/item/weapon/gun/launcher/pneumatic/verb/set_pressure() //set amount of tank pressure.
	set name = "Set Valve Pressure"
	set category = "Object"
	set src in range(0)
	var/N = input("Percentage of tank used per shot:","[src]") as null|anything in possible_pressure_amounts
	if (N)
		pressure_setting = N
		usr << "You dial the propellant valve to [pressure_setting]%."

/obj/item/weapon/gun/launcher/pneumatic/proc/eject_tank(mob/user) //Remove the tank.
	if(!tank)
		user << "There's no tank in [src]."
		return

	user << "You twist the valve and pop the tank out of [src]."
	user.put_in_hands(tank)
	tank = null
	update_icon()

/obj/item/weapon/gun/launcher/pneumatic/proc/unload_hopper(mob/user)
	if(item_storage.contents.len > 0)
		var/obj/item/removing = item_storage.contents[item_storage.contents.len]
		item_storage.remove_from_storage(removing, src.loc)
		user.put_in_hands(removing)
		user << "You remove [removing] from the hopper."
	else
		user << "There is nothing to remove in \the [src]."

/obj/item/weapon/gun/launcher/pneumatic/attack_hand(mob/user as mob)
	if(user.get_inactive_hand() == src)
		unload_hopper(user)
	else
		return ..()

/obj/item/weapon/gun/launcher/pneumatic/attackby(obj/item/W as obj, mob/user as mob)
	if(!tank && istype(W,/obj/item/weapon/tank))
		user.drop_from_inventory(W, src)
		tank = W
		user.visible_message("[user] jams [W] into [src]'s valve and twists it closed.","You jam [W] into [src]'s valve and twist it closed.")
		update_icon()
	else if(istype(W) && item_storage.can_be_inserted(W))
		item_storage.handle_item_insertion(W)

/obj/item/weapon/gun/launcher/pneumatic/attack_self(mob/user as mob)
	eject_tank(user)

/obj/item/weapon/gun/launcher/pneumatic/consume_next_projectile(mob/user=null)
	if(!item_storage.contents.len)
		return null
	if (!tank)
		user << "There is no gas tank in [src]!"
		return null

	var/environment_pressure = 10
	var/turf/T = get_turf(src)
	if(T)
		var/datum/gas_mixture/environment = T.return_air()
		if(environment)
			environment_pressure = environment.return_pressure()

	fire_pressure = (tank.air_contents.return_pressure() - environment_pressure)*pressure_setting/100
	if(fire_pressure < 10)
		user << "There isn't enough gas in the tank to fire [src]."
		return null

	var/obj/item/launched = item_storage.contents[1]
	item_storage.remove_from_storage(launched, src)
	return launched

/obj/item/weapon/gun/launcher/pneumatic/examine(mob/user)
	if(!..(user, 2))
		return
	user << "The valve is dialed to [pressure_setting]%."
	if(tank)
		user << "The tank dial reads [tank.air_contents.return_pressure()] kPa."
	else
		user << "Nothing is attached to the tank valve!"

/obj/item/weapon/gun/launcher/pneumatic/update_release_force(obj/item/projectile)
	if(tank)
		release_force = ((fire_pressure*tank.volume)/projectile.w_class)/force_divisor //projectile speed.
		if(release_force > 80) release_force = 80 //damage cap.
	else
		release_force = 0

/obj/item/weapon/gun/launcher/pneumatic/handle_post_fire()
	if(tank)
		var/lost_gas_amount = tank.air_contents.total_moles*(pressure_setting/100)
		var/datum/gas_mixture/removed = tank.air_contents.remove(lost_gas_amount)

		var/turf/T = get_turf(src.loc)
		if(T) T.assume_air(removed)
	..()

/obj/item/weapon/gun/launcher/pneumatic/update_icon()
	if(tank)
		icon_state = "pneumatic-tank"
		item_state = "pneumatic-tank"
	else
		icon_state = "pneumatic"
		item_state = "pneumatic"

	if (ismob(src.loc))
		var/mob/M = src.loc
		M.update_inv_r_hand()
		M.update_inv_l_hand()

//Constructable pneumatic cannon.

/obj/item/weapon/cannonframe
	name = "pneumatic cannon frame"
	desc = "A half-finished pneumatic cannon."
	icon_state = "pneumatic0"
	item_state = "pneumatic"

	var/buildstate = 0

/obj/item/weapon/cannonframe/update_icon()
	icon_state = "pneumatic[buildstate]"

/obj/item/weapon/cannonframe/examine(mob/user)
	..(user)
	switch(buildstate)
		if(1) user << "It has a pipe segment installed."
		if(2) user << "It has a pipe segment welded in place."
		if(3) user << "It has an outer chassis installed."
		if(4) user << "It has an outer chassis welded in place."
		if(5) user << "It has a transfer valve installed."

/obj/item/weapon/cannonframe/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W,/obj/item/pipe))
		if(buildstate == 0)
			user.drop_from_inventory(W)
			qdel(W)
			user << "<span class='notice'>You secure the piping inside the frame.</span>"
			buildstate++
			update_icon()
			return
	else if(istype(W,/obj/item/stack/material/steel))
		if(buildstate == 2)
			var/obj/item/stack/material/steel/M = W
			if(M.use(5))
				user << "<span class='notice'>You assemble a chassis around the cannon frame.</span>"
				buildstate++
				update_icon()
			else
				user << "<span class='notice'>You need at least five metal sheets to complete this task.</span>"
			return
	else if(istype(W,/obj/item/device/transfer_valve))
		if(buildstate == 4)
			user.drop_from_inventory(W)
			qdel(W)
			user << "<span class='notice'>You install the transfer valve and connect it to the piping.</span>"
			buildstate++
			update_icon()
			return
	else if(istype(W,/obj/item/weapon/weldingtool))
		if(buildstate == 1)
			var/obj/item/weapon/weldingtool/T = W
			if(T.remove_fuel(0,user))
				if(!src || !T.isOn()) return
				playsound(src.loc, 'sound/items/Welder2.ogg', 100, 1)
				user << "<span class='notice'>You weld the pipe into place.</span>"
				buildstate++
				update_icon()
		if(buildstate == 3)
			var/obj/item/weapon/weldingtool/T = W
			if(T.remove_fuel(0,user))
				if(!src || !T.isOn()) return
				playsound(src.loc, 'sound/items/Welder2.ogg', 100, 1)
				user << "<span class='notice'>You weld the metal chassis together.</span>"
				buildstate++
				update_icon()
		if(buildstate == 5)
			var/obj/item/weapon/weldingtool/T = W
			if(T.remove_fuel(0,user))
				if(!src || !T.isOn()) return
				playsound(src.loc, 'sound/items/Welder2.ogg', 100, 1)
				user << "<span class='notice'>You weld the valve into place.</span>"
				new /obj/item/weapon/gun/launcher/pneumatic(get_turf(src))
				qdel(src)
		return
	else
		..()
*/