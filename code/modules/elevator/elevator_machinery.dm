
/obj/machinery/elevator
	icon = 'icons/obj/machines/elevator.dmi'
	icon_state = "elevator_mechanism"

	var/obj/machinery/elevator/connection_up
	var/obj/machinery/elevator/connection_down

/obj/machinery/elevator/initialize()
	try_connect(UP)
	try_connect(DOWN)

/obj/machinery/elevator/Destroy()
	connection_up = null
	connection_down = null

	return ..()

/obj/machinery/elevator/proc/try_connect(var/search_dir)
	var/turf/T = get_step(get_turf(src), search_dir)
	if(!T)
		return 0
	var/obj/machinery/elevator/other = locate() in T
	if(!other)
		return 0
	switch(search_dir)
		if(UP)
			connection_up = other
			other.connection_down = src
		if(DOWN)
			connection_down = other
			other.connection_up = src