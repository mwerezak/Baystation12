//a docking port based on an airlock
/obj/machinery/embedded_controller/radio/airlock/airlock_controller/docking_port
	name = "docking port controller"

/obj/machinery/embedded_controller/radio/airlock/airlock_controller/docking_port/initialize()
	var/datum/computer/file/embedded_program/airlock/docking/airlock_controller = new/datum/computer/file/embedded_program/airlock/docking(src)

	airlock_controller.tag_exterior_door = tag_exterior_door
	airlock_controller.tag_interior_door = tag_interior_door
	airlock_controller.tag_airpump = tag_airpump
	airlock_controller.tag_chamber_sensor = tag_chamber_sensor
	airlock_controller.tag_exterior_sensor = tag_exterior_sensor
	airlock_controller.tag_interior_sensor = tag_interior_sensor
	airlock_controller.memory["secure"] = 1
	
	program = new/datum/computer/file/embedded_program/docking_controller/airlock/(src, airlock_controller)
	
	spawn(10)
		airlock_controller.signalDoor(tag_exterior_door, "update")		//signals connected doors to update their status
		airlock_controller.signalDoor(tag_interior_door, "update")


//A docking controller for an airlock based docking port
/datum/computer/file/embedded_program/docking_controller/airlock
	var/datum/computer/file/embedded_program/airlock/docking/airlock_prog
	var/airlock_override = 0

/datum/computer/file/embedded_program/docking_controller/airlock/New(var/obj/machinery/embedded_controller/M, var/datum/computer/file/embedded_program/airlock/docking/A)
	..(M)
	airlock_prog = A
	airlock_prog.master_prog = src

/datum/computer/file/embedded_program/docking_controller/airlock/receive_user_command(command)
	..(command)
	airlock_prog.receive_user_command(command)	//pass along to subprograms

/datum/computer/file/embedded_program/docking_controller/airlock/receive_signal(datum/signal/signal, receive_method, receive_param)
	..(signal, receive_method, receive_param)
	airlock_prog.receive_signal(signal, receive_method, receive_param)	//pass along to subprograms

//tell the docking port to start getting ready for docking - e.g. pressurize
/datum/computer/file/embedded_program/docking_controller/airlock/prepare_for_docking()
	airlock_prog.begin_cycle_in()

//are we ready for docking?
/datum/computer/file/embedded_program/docking_controller/airlock/ready_for_docking()
	return (airlock_prog.done_cycling() || airlock_override)

//we are docked, open the doors or whatever.
/datum/computer/file/embedded_program/docking_controller/airlock/finish_docking()
	airlock_prog.open_doors()

//tell the docking port to start getting ready for undocking - e.g. close those doors.
/datum/computer/file/embedded_program/docking_controller/airlock/prepare_for_undocking()
	airlock_prog.stop_cycling()
	airlock_prog.close_doors()

//are we ready for undocking?
/datum/computer/file/embedded_program/docking_controller/airlock/ready_for_undocking()
	return (airlock_prog.check_doors_closed() || airlock_override)

/datum/computer/file/embedded_program/docking_controller/airlock/reset()
	airlock_prog.stop_cycling()
	airlock_prog.close_doors()
	airlock_override = 0
	..()

//An airlock controller to be used by the airlock-based docking port controller.
//Same as a regular airlock controller but allows disabling of the regular airlock functions when docking
/datum/computer/file/embedded_program/airlock/docking
	
	var/datum/computer/file/embedded_program/docking_controller/airlock/master_prog

/datum/computer/file/embedded_program/airlock/docking/receive_user_command(command)
	if (master_prog.undocked() || master_prog.airlock_override)
		..(command)

/datum/computer/file/embedded_program/airlock/docking/proc/open_doors()
	toggleDoor(memory["interior_status"], tag_interior_door, memory["secure"], "open")
	toggleDoor(memory["exterior_status"], tag_exterior_door, memory["secure"], "open")

/datum/computer/file/embedded_program/airlock/docking/cycleDoors(var/target)
	if (master_prog.undocked() || master_prog.airlock_override)
		..(target)