/obj/machinery/embedded_controller/radio/airlock/dock
	var/datum/computer/file/embedded_program/airlock/docking/program

/obj/machinery/embedded_controller/radio/airlock/dock/initialize()
	set_frequency(frequency)
	
	var/datum/computer/file/embedded_program/airlock/docking/new_prog = new

	new_prog.id_tag = id_tag
	new_prog.tag_exterior_door = tag_exterior_door
	new_prog.tag_interior_door = tag_interior_door
	new_prog.tag_airpump = tag_airpump
	new_prog.tag_chamber_sensor = tag_chamber_sensor
	new_prog.tag_exterior_sensor = tag_exterior_sensor
	new_prog.tag_interior_sensor = tag_interior_sensor
	new_prog.memory["secure"] = tag_secure

	new_prog.master = src
	program = new_prog

	spawn(10)
		program.signalDoor(tag_exterior_door, "update")		//signals connected doors to update their status
		program.signalDoor(tag_interior_door, "update")

/obj/machinery/embedded_controller/radio/airlock/dock/proc/dock(var/id_tag)
	return

/obj/machinery/embedded_controller/radio/airlock/dock/proc/undock(var/id_tag)
	return
