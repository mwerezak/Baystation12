//These lists are populated in /datum/shuttle_controller/New()
//Shuttle controller is instantiated in master_controller.dm.

//shuttle moving state defines are in setup.dm

/datum/shuttle
	var/warmup_time = 0
	var/datum/shuttle_command/current_command

	var/docking_controller_tag	//tag of the controller used to coordinate docking
	var/datum/computer/file/embedded_program/docking/docking_controller	//the controller itself. (micro-controller, not game controller)

	var/transit_dir
	var/current_loc 
	var/arrive_time = 0	//the time at which the shuttle arrives when long jumping

/datum/shuttle/proc/init_docking_controllers()
	if(docking_controller_tag)
		docking_controller = locate(docking_controller_tag)
		if(!istype(docking_controller))
			world << "<span class='danger'>warning: shuttle with docking tag [docking_controller_tag] could not find it's controller!</span>"
			warning("shuttle with docking tag [docking_controller_tag] could not find it's controller!")

/datum/shuttle/proc/set_command(datum/shuttle_command/new_command)
	if(current_command)
		if(!current_command.is_complete() || !current_command.cancel())
			return 0
	current_command = new_command
	current_command.setup(src)

/datum/shuttle/proc/process()
	if(!current_command)
		return
	
	if(current_command.is_complete())
		current_command = null
	else
		current_command.process()


/datum/shuttle/proc/dock()
	if (!docking_controller)
		return

	var/dock_target = current_dock_target()
	if (!dock_target)
		return

	docking_controller.initiate_docking(dock_target)

/datum/shuttle/proc/undock()
	if (!docking_controller)
		return
	docking_controller.initiate_undocking()

/datum/shuttle/proc/current_dock_target()
	return null

/datum/shuttle/proc/skip_docking_checks()
	if (!docking_controller || !current_dock_target())
		return 1	//shuttles without docking controllers or at locations without docking ports act like old-style shuttles
	return 0

//just moves the shuttle from A to B, if it can be moved
//A note to anyone overriding move in a subtype. move() must absolutely not, under any circumstances, fail to move the shuttle.
//If you want to conditionally cancel shuttle launches, that logic must go in short_jump() or long_jump()
/datum/shuttle/proc/move(var/area/origin, var/area/destination, var/direction=null)

	//world << "move_shuttle() called for [shuttle_tag] leaving [origin] en route to [destination]."

	//world << "area_coming_from: [origin]"
	//world << "destination: [destination]"

	if(origin == destination)
		//world << "cancelling move, shuttle will overlap."
		return

	if (docking_controller && !docking_controller.undocked())
		docking_controller.force_undock()

	var/list/dstturfs = list()
	var/throwy = world.maxy

	for(var/turf/T in destination)
		dstturfs += T
		if(T.y < throwy)
			throwy = T.y

	for(var/turf/T in dstturfs)
		var/turf/D = locate(T.x, throwy - 1, 1)
		for(var/atom/movable/AM as mob|obj in T)
			AM.Move(D)
		if(istype(T, /turf/simulated))
			qdel(T)

	for(var/mob/living/carbon/bug in destination)
		bug.gib()

	for(var/mob/living/simple_animal/pest in destination)
		pest.gib()

	origin.move_contents_to(destination, direction=direction)
	current_loc = destination

	for(var/mob/M in destination)
		if(M.client)
			spawn(0)
				if(M.buckled)
					M << "\red Sudden acceleration presses you into your chair!"
					shake_camera(M, 3, 1)
				else
					M << "\red The floor lurches beneath you!"
					shake_camera(M, 10, 1)
		if(istype(M, /mob/living/carbon))
			if(!M.buckled)
				M.Weaken(3)

	// Power-related checks. If shuttle contains power related machinery, update powernets.
	var/update_power = 0
	for(var/obj/machinery/power/P in destination)
		update_power = 1
		break

	for(var/obj/structure/cable/C in destination)
		update_power = 1
		break

	if(update_power)
		makepowernets()
	return

//returns 1 if the shuttle has a valid arrive time
/datum/shuttle/proc/has_arrive_time()
	return (moving_status == SHUTTLE_INTRANSIT)
