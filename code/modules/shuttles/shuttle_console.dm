#define IDLE_STATE		0
#define WAIT_LAUNCH		1
#define WAIT_ARRIVE		2
#define WAIT_FINISH		3

/obj/machinery/computer/shuttle_control
	name = "shuttle control console"
	icon = 'icons/obj/computer.dmi'
	icon_state = "shuttle"
	req_access = list(access_engine)
	circuit = "/obj/item/weapon/circuitboard/engineering_shuttle"
	
	var/shuttle_tag  // Used to coordinate data in shuttle controller.
	var/hacked = 0   // Has been emagged, no access restrictions.
	
	var/process_state = IDLE_STATE

/obj/machinery/computer/shuttle_control/proc/launch_shuttle()
	var/datum/shuttle/shuttle = shuttles[shuttle_tag]
	
	if (shuttle.in_use && !skip_checks())
		return
	
	shuttle.in_use = 1	//obtain an exclusive lock on the shuttle
	
	process_state = WAIT_LAUNCH
	shuttle.undock()

/obj/machinery/computer/shuttle_control/process()
	if (!shuttles || !(shuttle_tag in shuttles))
		return

	var/datum/shuttle/shuttle = shuttles[shuttle_tag]

	switch(process_state)
		if (WAIT_LAUNCH)
			if (skip_checks() || shuttle.docking_controller.can_launch())
				shuttle.short_jump()
				process_state = WAIT_ARRIVE
		if (WAIT_ARRIVE)
			if (shuttle.moving_status == SHUTTLE_IDLE)
				shuttle.dock()
				process_state = WAIT_FINISH
		if (WAIT_FINISH)
			if (skip_checks() || shuttle.docking_controller.docked())
				process_state = IDLE_STATE
				shuttle.in_use = 0	//release lock

/obj/machinery/computer/shuttle_control/proc/skip_checks()
	var/datum/shuttle/shuttle = shuttles[shuttle_tag]

	if (!shuttle.docking_controller || !shuttle.current_dock_target())
		return 1	//shuttles without docking controllers or at locations without docking ports act like old-style shuttles

	return shuttle.docking_controller.override_enabled	//override pretty much lets you do whatever you want


/obj/machinery/computer/shuttle_control/Del()
	var/datum/shuttle/shuttle = shuttles[shuttle_tag]
	
	if (process_state != IDLE_STATE)
		shuttle.in_use = 0	//shuttle may not dock properly if this gets deleted while in transit, but its not a big deal

/obj/machinery/computer/shuttle_control/attack_hand(user as mob)
	if(..(user))
		return
	//src.add_fingerprint(user)	//shouldn't need fingerprints just for looking at it.

	ui_interact(user)

/obj/machinery/computer/shuttle_control/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null)
	var/data[0]
	var/datum/shuttle/shuttle = shuttles[shuttle_tag]

	var/shuttle_state
	switch(shuttle.moving_status)
		if(SHUTTLE_IDLE) shuttle_state = "idle"
		if(SHUTTLE_WARMUP) shuttle_state = "warmup"
		if(SHUTTLE_INTRANSIT) shuttle_state = "in_transit"

	var/shuttle_status
	if (process_state == IDLE_STATE)
		if (!shuttle.location)
			shuttle_status = "Standing-by at station."
		else
			shuttle_status = "Standing-by at offsite location."
		
	else
		shuttle_status = "Busy."
	
	if (shuttle.docking_controller)
		data = list(
			"shuttle_status" = shuttle_status,
			"shuttle_state" = shuttle_state,
			"has_docking" = 1,
			"docking_status" = shuttle.docking_controller.get_docking_status(),
			"override_enabled" = shuttle.docking_controller.override_enabled,
		)
	else
		data = list(
			"shuttle_status" = shuttle_status,
			"shuttle_state" = shuttle_state,
			"has_docking" = 0,
			"docking_status" = null,
			"override_enabled" = null,
		)

	ui = nanomanager.try_update_ui(user, src, ui_key, ui, data)

	if (!ui)
		ui = new(user, src, ui_key, "shuttle_control_console.tmpl", "[shuttle_tag] Shuttle Control", 470, 290)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)

//TODO: Canceling launches, dock overrides using the console, forcing dock/undock
/obj/machinery/computer/shuttle_control/Topic(href, href_list)
	if(..())
		return
	
	var/datum/shuttle/shuttle = shuttles[shuttle_tag]
	
	usr.set_machine(src)
	src.add_fingerprint(usr)

	if(href_list["move"])
		if (shuttle.moving_status == SHUTTLE_IDLE)
			usr << "\blue [shuttle_tag] Shuttle recieved message and will be sent shortly."
			launch_shuttle()
		else
			usr << "\blue [shuttle_tag] Shuttle is already moving."


/obj/machinery/computer/shuttle_control/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if (istype(W, /obj/item/weapon/card/emag))
		src.req_access = list()
		hacked = 1
		usr << "You short out the console's ID checking system. It's now available to everyone!"
	else
		..()

/obj/machinery/computer/shuttle_control/bullet_act(var/obj/item/projectile/Proj)
	visible_message("[Proj] ricochets off [src]!")

