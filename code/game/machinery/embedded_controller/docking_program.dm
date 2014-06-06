
#define STATE_UNDOCKED		0
#define STATE_DOCKING		1
#define STATE_UNDOCKING		2
#define STATE_DOCKED		3

#define MODE_NONE			0
#define MODE_SERVER			1
#define MODE_CLIENT			2	//The one who initiated the docking, and who can initiate the undocking. The server cannot initiate undocking. (Think server == station, client == shuttle)

/*
	*** STATE TABLE ***
	
	MODE_CLIENT|STATE_UNDOCKED		sent a request for docking and now waiting for a reply.
	MODE_CLIENT|STATE_DOCKING		server told us they are OK to dock, waiting for our docking port to be ready.
	MODE_CLIENT|STATE_DOCKED		idle - docked as client.
	MODE_CLIENT|STATE_UNDOCKING		we are either waiting for our docking port to be ready or for the server to give us the OK to undock.
	
	MODE_SERVER|STATE_UNDOCKED		should never happen.
	MODE_SERVER|STATE_DOCKING		someone requested docking, we are waiting for our docking port to be ready.
	MODE_SERVER|STATE_DOCKED		idle - docked as server
	MODE_SERVER|STATE_UNDOCKING		client requested undocking, we are waiting for our docking port to be ready.
	
	MODE_NONE|STATE_UNDOCKED		idle - not docked.
	MODE_NONE|anything else			should never happen.
*/


/datum/computer/file/embedded_program/docking_controller
	var/tag_target				//the tag of the docking controller that we are trying to dock with
	var/dock_state = STATE_UNDOCKED
	var/control_mode = MODE_NONE
	var/response_sent = 0		//so we don't spam confirmation messages

/datum/computer/file/embedded_program/docking_controller/receive_signal(datum/signal/signal, receive_method, receive_param)
	var/receive_tag = signal.data["tag"]		//for docking signals, this is the sender id
	var/command = signal.data["command"]
	var/recipient = signal.data["recipient"]	//the intended recipient of the docking signal
	
	if (recipient != id_tag)
		return	//this signal is not for us
	
	switch (command)
		if ("confirm_dock")
			if (control_mode == MODE_CLIENT && dock_state == STATE_UNDOCKED && receive_tag == tag_target)
				dock_state = STATE_DOCKING
				prepare_for_docking()
			else if (control_mode == MODE_SERVER && dock_state == STATE_DOCKING && receive_tag == tag_target)	//client just sent us the confirmation back, we're done with the docking process
				dock_state = STATE_DOCKED
				finish_docking()	//server done docking!
				response_sent = 0
			else
				send_docking_command(tag_target, "abort_dock")	//not expecting confirmation for anything - tell the other guy.
		
		if ("request_dock")
			if (control_mode == MODE_NONE && dock_state == STATE_UNDOCKED)
				control_mode = MODE_SERVER
				dock_state = STATE_DOCKING
				tag_target = receive_tag
				prepare_for_docking()
		
		if ("confirm_undock")
			if (control_mode == MODE_CLIENT && dock_state == STATE_UNDOCKING && receive_tag == tag_target)
				send_docking_command(tag_target, "confirm_undock")
				reset()		//client is done undocking!
		
		if ("request_undock")
			if (control_mode == MODE_SERVER && dock_state == STATE_DOCKED && receive_tag == tag_target)
				dock_state = STATE_UNDOCKING
				prepare_for_undocking()
	
		if ("abort_dock")
			if (dock_state == STATE_DOCKING && receive_tag == tag_target)
				reset()
		
		if ("abort_undock")
			if (dock_state == STATE_UNDOCKING && receive_tag == tag_target)
				dock_state = STATE_DOCKING	//redock
				prepare_for_docking()
		
		if ("dock_error")
			if (receive_tag == tag_target)
				reset()		//something really bad happened

/datum/computer/file/embedded_program/docking_controller/process()
	switch(dock_state)
		if (STATE_DOCKING)	//waiting for our docking port to be ready for docking
			if (ready_for_docking())
				if (!response_sent)
					send_docking_command(tag_target, "confirm_dock")	//tell the other guy we're ready
					response_sent = 1
				
				if (control_mode == MODE_CLIENT)	//client doesn't need to do anything further
					dock_state = STATE_DOCKED
					finish_docking()	//client done docking!
					response_sent = 0
		if (STATE_UNDOCKING)
			if (ready_for_docking())
				if (control_mode == MODE_CLIENT)
					if (!response_sent)
						send_docking_command(tag_target, "request_undock")	//tell the server we want to undock now.
						response_sent = 1
				else if (control_mode == MODE_SERVER)
					send_docking_command(tag_target, "confirm_undock")	//tell the client we are OK to undock.
					reset()		//server is done undocking!
	
	if (dock_state != STATE_DOCKING && dock_state != STATE_UNDOCKING)
		response_sent = 0
	
	//handle invalid states
	if (control_mode == MODE_NONE && dock_state != STATE_UNDOCKED)
		if (tag_target)
			send_docking_command(tag_target, "dock_error")
		reset()
	if (control_mode == MODE_SERVER && dock_state == STATE_UNDOCKED)
		control_mode = MODE_NONE


/datum/computer/file/embedded_program/docking_controller/proc/initiate_docking(var/target)
	if (dock_state != STATE_UNDOCKED || control_mode == MODE_SERVER)	//must be undocked and not serving another request to begin a new docking handshake
		return
	
	tag_target = target
	control_mode = MODE_CLIENT
	
	send_docking_command(tag_target, "request_dock")

/datum/computer/file/embedded_program/docking_controller/proc/initiate_undocking()
	if (dock_state != STATE_DOCKED || control_mode != MODE_CLIENT)		//must be docked and must be client to start undocking
		return
	
	dock_state = STATE_UNDOCKING
	prepare_for_undocking()
	
	send_docking_command(tag_target, "request_undock")


//tell the docking port to start getting ready for docking - e.g. pressurize
/datum/computer/file/embedded_program/docking_controller/proc/prepare_for_docking()
	return

//are we ready for docking?
/datum/computer/file/embedded_program/docking_controller/proc/ready_for_docking()
	return 1

//we are docked, open the doors or whatever.
/datum/computer/file/embedded_program/docking_controller/proc/finish_docking()
	return

//tell the docking port to start getting ready for undocking - e.g. close those doors.
/datum/computer/file/embedded_program/docking_controller/proc/prepare_for_undocking()
	return

//are we ready for undocking?
/datum/computer/file/embedded_program/docking_controller/proc/ready_for_undocking()
	return 1

/datum/computer/file/embedded_program/docking_controller/proc/initiate_abort()
	switch(dock_state)
		if (STATE_DOCKING)
			send_docking_command(tag_target, "abort_dock")
			reset()
		if (STATE_UNDOCKING)
			send_docking_command(tag_target, "abort_undock")
			dock_state = STATE_DOCKING	//redock
			prepare_for_docking()

/datum/computer/file/embedded_program/docking_controller/proc/reset()
	dock_state = STATE_UNDOCKED
	control_mode = MODE_NONE
	tag_target = null
	response_sent = 0

//returns 1 if we are saftely undocked (and the shuttle can leave)
/datum/computer/file/embedded_program/docking_controller/proc/undocked()
	return (dock_state == STATE_UNDOCKED)

/datum/computer/file/embedded_program/docking_controller/proc/send_docking_command(var/recipient, var/command)
	var/datum/signal/signal = new
	signal.data["tag"] = id_tag
	signal.data["command"] = command
	signal.data["recipient"] = recipient
	post_signal(signal)


//for debugging

/datum/computer/file/embedded_program/docking_controller/proc/print_state()
	world << "id_tag: [id_tag]"
	world << "dock_state: [dock_state]"
	world << "control_mode: [control_mode]"
	world << "tag_target: [tag_target]"
	world << "response_sent: [response_sent]"

/datum/computer/file/embedded_program/docking_controller/post_signal(datum/signal/signal, comm_line)
	world << "Program [id_tag] sent a message!"
	print_state()
	world << "[id_tag] sent command \"[signal.data["command"]]\" to \"[signal.data["recipient"]]\""

/obj/machinery/embedded_controller/radio/airlock/airlock_controller/docking_port/verb/view_state()
	set src in view(1)
	src.program:print_state()

/obj/machinery/embedded_controller/radio/airlock/airlock_controller/docking_port/verb/spoof_signal(var/command as text, var/sender as text)
	set src in view(1)
	var/datum/signal/signal = new
	signal.data["tag"] = sender
	signal.data["command"] = command
	signal.data["recipient"] = id_tag

	src.program:receive_signal(signal)

/obj/machinery/embedded_controller/radio/airlock/airlock_controller/docking_port/verb/debug_init_dock(var/target as text)
	set src in view(1)
	src.program:initiate_docking(target)

/obj/machinery/embedded_controller/radio/airlock/airlock_controller/docking_port/verb/debug_init_undock(var/target as text)
	set src in view(1)
	src.program:initiate_undocking()
	
#undef STATE_UNDOCKED
#undef STATE_DOCKING
#undef STATE_UNDOCKING
#undef STATE_DOCKED

#undef MODE_NONE
#undef MODE_SERVER
#undef MODE_CLIENT