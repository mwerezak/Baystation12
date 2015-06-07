
//Shuttle command base type
/datum/shuttle_command
	var/datum/shuttle/shuttle

//Binds the command to a shuttle. Subtypes can override to perform initialization here,
//however they should not accept any additional arguments. Use New for specifying command parameters.
/datum/shuttle_command/proc/setup(datum/shuttle/host)
	shuttle = host

/datum/shuttle_command/Destroy()
	shuttle = null

//Should be overriden by subtypes
/datum/shuttle_command/proc/process()
	return

//Return 1 if the command has completed.
//If it returns 1, then process() will not be called.
/datum/shuttle_command/proc/is_complete()
	return 1

//returns 0 if cancelling is not permitted,
//otherwise 1 if the command was cancelled successfully
/datum/shuttle_command/proc/cancel()
	return 1


//Moves the shuttle to a destination area
/datum/shuttle_command/jump
	var/moving_status = SHUTTLE_IDLE

	var/area/destination = null
	var/launch_time

/datum/shuttle_command/jump/New(area/destination)
	..()
	src.destination = destination

/datum/shuttle_command/jump/setup(datum/shuttle/host)
	..()
	launch_time = world.time + shuttle.warmup_time*10
	moving_status = SHUTTLE_WARMUP

/datum/shuttle_command/jump/process()
	if(moving_status == SHUTTLE_WARMUP && world.time >= launch_time)
		moving_status = SHUTTLE_INTRANSIT
		move(shuttle.current_loc, destination, shuttle.transit_dir)
		moving_status = SHUTTLE_IDLE

/datum/shuttle_command/jump/is_complete()
	return moving_status == SHUTTLE_IDLE

/datum/shuttle_command/jump/cancel()
	moving_status == SHUTTLE_IDLE
	return 1

//Moves the shuttle to a transit area for a certain amount of time,
//before proceeding to the destination
/datum/shuttle_command/jump/long
	var/area/transit_area
	var/travel_time //in seconds

/datum/shuttle_command/jump/long/New(area/destination, area/transit_area, travel_time)
	..()
	src.transit_area = transit_area
	src.travel_time = travel_time

/datum/shuttle_command/jump/process()
	if(world.time < launch_time)
		return

	switch(moving_status)
		if(SHUTTLE_WARMUP)
			moving_status = SHUTTLE_INTRANSIT
			move(shuttle.current_loc, transit_area, shuttle.transit_dir)
			launch_time = world.time + travel_time*10
		if(SHUTTLE_INTRANSIT)
			move(shuttle.current_loc, destination, shuttle.transit_dir)
			moving_status = SHUTTLE_IDLE

/datum/shuttle_command/jump/long/cancel()
	if(moving_status == SHUTTLE_WARMUP)
		moving_status = SHUTTLE_IDLE
		return 1
	return 0
