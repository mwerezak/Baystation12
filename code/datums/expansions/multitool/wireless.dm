/datum/expansion/multitool/wireless
	var/list/wireless_datums

/datum/expansion/multitool/wireless/New(var/atom/holder, var/wireless, var/list/can_interact_predicates)
	if(islist(wireless))
		var/list/L = wireless
		wireless_datums = L.Copy()
	else
		wireless_datums = list(wireless)

/datum/expansion/multitool/wireless/get_interact_window(var/obj/item/device/multitool/M, var/mob/user)
	. += "<b>Wireless I/O</b><br>"
	for(var/datum/wifi/W in wireless_datums)
		. += "<hr>"
		. += "<b>[W.display_name]: \[[W.id ? W.id : "Unassigned"]\]</b>"

/datum/expansion/multitool/wireless/on_topic(href, href_list, usr)
	return ..()
