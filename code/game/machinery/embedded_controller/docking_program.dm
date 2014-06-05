
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
	var/confirm_sent = 0		//so we don't spam confirmation messages

/datum/computer/file/embedded_program/docking_controller/receive_signal(datum/signal/signal, receive_method, receive_param)
	var/receive_tag = signal.data["tag"]		//for docking signals, this is the sender id
	var/command = signal.data["command"]
	var/recipient = signal.data["recipient"]	//the intended recipient of the docking signal
	
	if (recipient != id_tag)
		return	//this signal is not for us
	
	switch (command)
		if ("confirm_dock")
			if (control_mode == MODE_CLIENT && dock_state == STATE_UNDOCKED && receive_tag == tag_target)
				dock_state == STATE_DOCKING
				prepare_for_docking()
			else if (control_mode == MODE_SERVER && dock_state == STATE_DOCKING && receive_tag == tag_target)	//client just sent us the confirmation back, we're done with the docking process
				dock_state = STATE_DOCKED
				finish_docking()	//server done docking!
				confirm_sent = 0
			else
				send_docking_command(tag_target, "abort_docking")	//not expecting confirmation for anything - tell the other guy.
		
		if ("request_dock")
			if (control_mode == MODE_NONE && dock_state == STATE_UNDOCKED)
				control_mode = MODE_SERVER
				dock_state = STATE_DOCKING
				tag_target = receive_tag
				prepare_for_docking()
		
		if ("confirm_undock")
			if (control_mode == MODE_CLIENT && dock_state == STATE_UNDOCKING && receive_tag = tag_target)
				send_docking_command(tag_target, "confirm_undock")
				reset()		//client is done undocking!
		
		if ("request_undock")
			if (control_mode == MODE_SERVER && dock_state == STATE_DOCKED && receive_tag == tag_target)
				dock_state = STATE_UNDOCKING
				prepare_for_undocking()
	
		if ("abort_docking")
			if (dock_state == STATE_DOCKING && receive_tag = tag_target)
				reset()
		
		if ("abort_undocking")
			if (dock_state == STATE_UNDOCKING && receive_tag = tag_target)
				dock_state = STATE_DOCKING	//redock
				prepare_for_docking()

/datum/computer/file/embedded_program/docking_controller/process()
	switch(dock_state)
		if (STATE_DOCKING)	//waiting for our docking port to be ready for docking
			if (ready_for_docking())
				if (!confirm_sent)
					send_docking_command(tag_target, "confirm_dock")	//tell the other guy we're ready
					confirm_sent = 1
				
				if (control_mode == MODE_CLIENT)	//client doesn't need to do anything further
					dock_state = STATE_DOCKED
					finish_docking()	//client done docking!
					confirm_sent = 0
		if (STATE_UNDOCKING)
			if (ready_for_docking())
				if (control_mode == MODE_CLIENT)
					if (!confirm_sent)
						send_docking_command(tag_target, "request_undock")	//tell the server we want to undock now.
						confirm_sent = 1
				else if (control_mode == MODE_SERVER)
					send_docking_command(tag_target, "confirm_undock")	//tell the client we are OK to undock.
					reset()		//server is done undocking!
	
	if (dock_state != STATE_DOCKING || dock_state != STATE_UNDOCKING)
		confirm_sent = 0
	
	//handle invalid states
	//write this after
	if (tag_target && (dock_state == STATE_UNDOCKED || control_mode == MODE_NONE)
		send_docking_command(tag_target, "docking_error")
		tag_target = null
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

//returns 1 if we are saftely undocked (and the shuttle can leave)
/datum/computer/file/embedded_program/docking_controller/proc/undocked()
	return 1

/datum/computer/file/embedded_program/docking_controller/proc/initiate_abort()
	switch(dock_state)
		if (STATE_DOCKING)
			send_docking_command(tag_target, "abort_docking")
			reset()
		if (STATE_UNDOCKING)
			send_docking_command(tag_target, "abort_undocking")
			dock_state = STATE_DOCKING	//redock
			prepare_for_docking()

/datum/computer/file/embedded_program/docking_controller/proc/reset()
	state = STATE_UNDOCKED
	control_mode = MODE_NONE
	tag_target = null
	confirm_sent = 0
	
/*
/datum/computer/file/embedded_program/airlock/docking
	var/tag_target				//the tag of the docking controller that we are trying to dock with
	var/airlock_override = 0	//allows use of the docking port as a normal airlock (normally this is only allowed in STATE_UNDOCKED)
	var/dock_state = STATE_UNDOCKED
	var/control_mode = MODE_NONE
	var/dock_master = 0			//are we the initiator of the dock?

/datum/computer/file/embedded_program/airlock/docking/receive_signal(datum/signal/signal, receive_method, receive_param)
	var/receive_tag = signal.data["tag"]	//for docking signals, this is the sender id
	var/command = signal.data["command"]
	var/recipient = signal.data["recipient"]
	
	if (recipient == id_tag)
		switch (command)
			if ("request_dock")
				if (state == STATE_UNDOCKED && control_mode == MODE_NONE)
					tag_target = receive_tag
					begin_dock()
				
			if ("request_undock")
				if(receive_tag == tag_target)
					begin_undock()
			
			if ("confirm_dock")
				if(receive_tag == tag_target)
					dock_master = 1
					begin_dock()
				else
					send_docking_command(receive_tag, "docking_error")	//send an error message
			
			if ("confirm_undock")
				if(receive_tag == tag_target)
					begin_undock()
				
			if ("abort_dock")
				if(receive_tag==tag_target)
					//try to return to a good state
					stop_cycling()
					
					//close the doors
					toggleDoor(memory["interior_status"], tag_interior_door, memory["secure"], "close")
					toggleDoor(memory["exterior_status"], tag_exterior_door, memory["secure"], "close")
					
					state = STATE_UNDOCKED
					tag_target = null
					dock_master = 0
	
	..()

/datum/computer/file/embedded_program/airlock/docking/receive_user_command(command)
	if (state == STATE_UNDOCKED || airlock_override)
		..(command)

/datum/computer/file/embedded_program/airlock/docking/process()
	..()	//process regular airlock stuff first
	
	switch(dock_state)
		if(STATE_DOCKING)
			if(done_cycling() || airlock_override)
				state = STATE_DOCKED
				
				if (!dock_master)
					send_docking_command(tag_target, "confirm_dock")	//send confirmation
				
				//open doors
				toggleDoor(memory["interior_status"], tag_interior_door, memory["secure"], "open")
				toggleDoor(memory["exterior_status"], tag_exterior_door, memory["secure"], "open")
		if(STATE_UNDOCKING)
			if(check_doors_closed() || airlock_override)	//check doors are closed or override
				state = STATE_UNDOCKED
				
				if (!dock_master)
					send_docking_command(tag_target, "confirm_undock")	//send confirmation
				
				dock_master = 0
				tag_target = null

/datum/computer/file/embedded_program/airlock/docking/cycleDoors(var/target)
	if (state == STATE_UNDOCKED || airlock_override)
		..(target)

//get the docking port into a good state for docking.
/datum/computer/file/embedded_program/airlock/docking/proc/begin_dock()
	dock_state = STATE_DOCKING
	begin_cycle_in()

//get the docking port into a good state for undocking.
/datum/computer/file/embedded_program/airlock/docking/proc/begin_undock()
	dock_state = STATE_UNDOCKING
	stop_cycling()
	
	//close the doors
	toggleDoor(memory["interior_status"], tag_interior_door, memory["secure"], "close")
	toggleDoor(memory["exterior_status"], tag_exterior_door, memory["secure"], "close")

/datum/computer/file/embedded_program/airlock/docking/proc/send_docking_command(var/recipient, var/command)
	var/datum/signal/signal = new
	signal.data["tag"] = id_tag
	signal.data["command"] = command
	signal.data["recipient"] = recipient
	post_signal(signal)
*/

#undef STATE_UNDOCKED
#undef STATE_DOCKING
#undef STATE_UNDOCKING
#undef STATE_DOCKED

#undef MODE_NONE
#undef MODE_SERVER
#undef MODE_CLIENT