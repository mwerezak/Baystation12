//a docking port that uses a single door
/obj/machinery/embedded_controller/radio/simple_docking_controller
	name = "docking hatch controller"
	var/datum/computer/file/embedded_program/docking/simple/control_prog
	var/tag_door

/obj/machinery/embedded_controller/radio/airlock/airlock_controller/docking_port/initialize()
	control_prog = new/datum/computer/file/embedded_program/docking/simple(src)
	control_prog.tag_door = tag_door
	program = control_prog
	
	spawn(10)
		control_prog.signal_door("update")		//signals connected doors to update their status
/*
/obj/machinery/embedded_controller/radio/airlock/airlock_controller/docking_port/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null)
	var/data[0]

	data = list(
		"chamber_pressure" = round(airlock_prog.memory["chamber_sensor_pressure"]),
		"exterior_status" = airlock_prog.memory["exterior_status"],
		"interior_status" = airlock_prog.memory["interior_status"],
		"processing" = airlock_prog.memory["processing"],
	)

	ui = nanomanager.try_update_ui(user, src, ui_key, ui, data)

	if (!ui)
		ui = new(user, src, ui_key, "simple_airlock_console.tmpl", name, 470, 290)

		ui.set_initial_data(data)

		ui.open()

		ui.set_auto_update(1)

/obj/machinery/embedded_controller/radio/airlock/airlock_controller/docking_port/Topic(href, href_list)
	var/clean = 0
	switch(href_list["command"])	//anti-HTML-hacking checks
		if("cycle_ext")
			clean = 1
		if("cycle_int")
			clean = 1
		if("force_ext")
			clean = 1
		if("force_int")
			clean = 1
		if("abort")
			clean = 1

	if(clean)
		program.receive_user_command(href_list["command"])

	return 1
*/


//A docking controller for a simple door based docking port
/datum/computer/file/embedded_program/docking/simple
	var/tag_door

/datum/computer/file/embedded_program/docking/simple/New()
	memory["door_status"] = list(state = "closed", lock = "locked")		//assume closed and locked in case the doors dont report in
	memory["door_status"] = list(state = "closed", lock = "locked")

/datum/computer/file/embedded_program/docking/simple/receive_signal(datum/signal/signal, receive_method, receive_param)
	var/receive_tag = signal.data["tag"]
	if(!receive_tag) return
	
	if(receive_tag==tag_exterior_door)
		memory["exterior_status"]["state"] = signal.data["door_status"]
		memory["exterior_status"]["lock"] = signal.data["lock_status"]
	
	..(signal, receive_method, receive_param)
	
/datum/computer/file/embedded_program/docking/simple/receive_user_command(command)
	if (!override_enabled) return	//only allow manually controlling the door when the override is enabled.
	
	switch(command)
		if("force_open")
			open_door()
		if("force_close")
			close_door()	
	
/datum/computer/file/embedded_program/docking/simple/proc/signal_door(var/command)
	var/datum/signal/signal = new
	signal.data["tag"] = tag_door
	signal.data["command"] = command
	post_signal(signal)

/datum/computer/file/embedded_program/docking/simple/proc/open_door()
	if(memory["door_status"]["state"] == "closed")
		signal_door("secure_open")
	else if(memory["door_status"]["lock"] == "unlocked")
		signal_door("lock")

/datum/computer/file/embedded_program/docking/simple/proc/close_door()
	if(memory["door_status"]["state"] == "open")
		signal_door("secure_close")
	else if(memory["door_status"]["lock"] == "unlocked")
		signal_door("lock")

//tell the docking port to start getting ready for docking - e.g. pressurize
/datum/computer/file/embedded_program/docking/simple/prepare_for_docking()
	return		//don't need to do anything

//are we ready for docking?
/datum/computer/file/embedded_program/docking/simple/ready_for_docking()
	return 1	//don't need to do anything

//we are docked, open the doors or whatever.
/datum/computer/file/embedded_program/docking/airlock/finish_docking()
	open_door()

//tell the docking port to start getting ready for undocking - e.g. close those doors.
/datum/computer/file/embedded_program/docking/airlock/prepare_for_undocking()
	close_door()

//are we ready for undocking?
/datum/computer/file/embedded_program/docking/airlock/ready_for_undocking()
	return (door_override || (memory["door_status"]["state"] == "closed" && memory["door_status"]["lock"] == "locked"))

/datum/computer/file/embedded_program/docking/airlock/reset()
	close_door()
	..()