/*
 * Paper
 * also scraps of paper
 */

/obj/machinery/photocopier
	name = "photocopier"
	desc = "stub"

/obj/machinery/faxmachine
	name = "faxmachine"
	desc = "stub"
	var/department

/obj/machinery/photocopier/faxmachine
	desc = "stub"
	var/department

	proc/recievefax(var/P)

/obj/item/device/toner
	name = "toner"
	desc = "stub"

/obj/item/weapon/paperwork/paper/carbon
	desc = "stub"
	var/iscopy
	var/copied

/obj/item/weapon/paperwork/paper
	name = "paper"
	gender = PLURAL
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "paper"
	throwforce = 0
	w_class = 1.0
	throw_range = 1
	throw_speed = 1
	layer = 4
	pressure_resistance = 1
	slot_flags = SLOT_HEAD
	body_parts_covered = HEAD
	attack_verb = list("bapped")

	var/list/text_content = list()
	var/tmp/cached_content //caches the content that is displayed when the paper is viewed
	var/tmp/cached_content_edit //caches the content that is displayed the paper is being edited

	var/info = null	//backwards compatibility
	
	//TODO#paperwork
	var/stamps = "stub"
	var/ico[0]      //Icons and
	var/offset_x[0] //offsets stored for later
	var/offset_y[0] //usage by the photocopier

/obj/item/weapon/paperwork/paper/New()
	..()
	pixel_y = rand(-8, 8)
	pixel_x = rand(-9, 9)
	update_icon()

/obj/item/weapon/paperwork/paper/initialize()
	update_icon()

/obj/item/weapon/paperwork/paper/attackby(obj/item/weapon/P as obj, mob/user as mob)
	if(istype(P, /obj/item/weapon/pen) || istype(P, /obj/item/toy/crayon))
		show_content(user, editing=1)
	else
		..()

//TODO#paperwork Stamps
/obj/item/weapon/paperwork/paper/render_content(mob/user=null, var/editing=0)
	//backwards compatibility with code that sets info
	if (!isnull(info))
		text_content = list( new/datum/writing/text_content(info) )
		info = null
		regenerate_cached_content()

	if (isnull(cached_content) || (editing && isnull(cached_content_edit)))
		regenerate_cached_content()

	if(user && !can_read(user))
		return stars(cached_content)

	if (editing)
		return cached_content_edit
	return cached_content

/obj/item/weapon/paperwork/paper/show_content(var/mob/user, var/editing=0)
	user << browse("<HTML><HEAD><TITLE>[name]</TITLE></HEAD><BODY>[render_content(user, editing)]</BODY></HTML>", "window=[name]")
	onclose(user, "[name]")

//TODO#paperwork Stamps
/obj/item/weapon/paperwork/paper/show_content_admin(datum/admins/admin)
	admin.owner << browse("<HTML><HEAD><TITLE>[name]</TITLE></HEAD><BODY>[render_content(null, 0)]</BODY></HTML>", "window=[name]")
	onclose(admin.owner, "[name]")

/obj/item/weapon/paperwork/paper/proc/set_content(var/new_text)
	text_content = list( new/datum/writing/text_content(info) )
	regenerate_cached_content()
	update_icon()

/obj/item/weapon/paperwork/paper/proc/clear_content()
	text_content = list()
	cached_content = ""
	info = null
	update_icon()

//This should be called whenever the content of the paper is changed
/obj/item/weapon/paperwork/paper/proc/regenerate_cached_content()
	var/list/L = list()
	for (var/datum/writing/W in text_content)
		L += W.render(editing=0)
	cached_content = list2text(L)

	L.Cut()
	for (var/i in 1 to text_content.len)
		var/datum/writing/W = text_content[i]
		L += W.render(sequence=i, editing=1, handler=src)
	cached_content_edit = list2text(L)
	
	if (stamped && stamped.len)
		var/stamp_content = "<hr>"
		for (var/datum/stamp/S in stamped)
			stamp_content += "<i>This paper has been stamped with the [S.stamp_name].</i><br>"
		
		cached_content += stamp_content
		cached_content_edit += stamp_content

/obj/item/weapon/paperwork/paper/update_icon()
	if((text_content && text_content.len) || info)
		icon_state = "paper_words"
	else
		icon_state = "paper"

/obj/item/weapon/paperwork/paper/Topic(href, href_list)
	if (href_list["write_content"])
		if(!usr || usr.stat || usr.restrained() || !can_read(usr))
			return

		// if paper is not in usr, then it must be near them, or in a clipboard or folder, which must be in or near usr
		if(src.loc != usr && !src.Adjacent(usr) && !((istype(src.loc, /obj/item/weapon/clipboard) || istype(src.loc, /obj/item/weapon/folder)) && (src.loc.loc == usr || src.loc.Adjacent(usr)) ) )
			return

		//get the new content
		var/obj/item/I = usr.get_active_hand()
		var/list/new_content = paperwork_input(usr, I)
		if (!new_content)
			return

		//insert the new content. The first and last elements of the new content gets merged with neighboring elements in text_content
		if (href_list["write_content"] == "end")
			append_content(text_content, new_content)
		else
			//easiest way to do this is to split text_content
			var/i = text2num(href_list["write_content"])
			var/list/tail = text_content.Copy(i+1)
			text_content.Cut(i+1)
			
			append_content(text_content, new_content)
			append_content(text_content, tail)
		
		update_icon()
		regenerate_cached_content()
		show_content(usr, editing=1)
		return
	
	..()
