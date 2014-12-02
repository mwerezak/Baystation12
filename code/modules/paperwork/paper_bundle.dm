#define SHOW_LINK_PREV	1
#define SHOW_LINK_NEXT	2

#undefine

/obj/item/weapon/paperwork/bundle
	name = "paper bundle"
	gender = PLURAL
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "paper"
	item_state = "paper"
	throwforce = 0
	w_class = 1
	throw_range = 2
	throw_speed = 1
	layer = 4
	pressure_resistance = 1
	attack_verb = list("bapped")
	var/page = 1
	var/screen = SHOW_LINK_NEXT

//Attaches a paperwork item to the end of the bundle
/obj/item/weapon/paperwork/bundle/proc/attach_item(obj/item/weapon/paperwork/P, mob/user)
	if (istype(P, /obj/item/weapon/paperwork/paper/carbon))
		var/obj/item/weapon/paperwork/paper/carbon/C = P
		if (!C.iscopy && !C.copied)
			user << "<span class='notice'>Take off the carbon copy first.</span>"
			add_fingerprint(user)
			return 0

	user.drop_from_inventory(P)
	if (!istype(P, /obj/item/weapon/paperwork/bundle))
		P.loc = src
	else
		for(var/obj/O in P)
			O.loc = src
			O.add_fingerprint(user)
		del(P)
	
	update_bundle(1)
	update_icon()
	return 1

//paperwork/create_bundle() won't work when src is a bundle (src gets deleted) so override it.
//I don't think create_bundle is ever called on a paper bundle but it's better to be safe.
/obj/item/weapon/paperwork/bundle/create_bundle(obj/item/weapon/paperwork/other, mob/user)
	attach_item(other, user)

/obj/item/weapon/paperwork/bundle/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if(istype(W, /obj/item/weapon/paperwork))
		if (attach_item(W, user))
			user << "<span class='notice'>You add \the [W] to \the [src].</span>"

	else if(istype(W, /obj/item/weapon/pen) || istype(W, /obj/item/toy/crayon))
		usr << browse(null, "window=[name]") //Closes the dialog
		var/obj/item/weapon/paperwork/P = src[page]
		P.attackby(W, user)
	
	//Stamp the first page, since that's the only one for which stamps are visible
	else if(istype(W, /obj/item/weapon/stamp))
		var/obj/item/weapon/paperwork/P = src[1]
		P.attackby(W, user)
		update_icon()
	
	else
		..()

//Render the page's content
/obj/item/weapon/paperwork/bundle/render_content(mob/user=null, var/show_page=null)
	if (isnull(show_page))
		show_page = page
	
	//generate page contents
	if (istype(src[show_page], /obj/item/weapon/paperwork))
		var/obj/item/weapon/paperwork/P = src[show_page]
		return P.render_content(user)
	return ""

/obj/item/weapon/paperwork/bundle/show_content(mob/user)
	//generate header
	var/dat = ""

	dat+= "<DIV STYLE='float:left; text-align:left; width:33.33333%'>[(screen & SHOW_LINK_PREV)? "<A href='?src=\ref[src];prev_page=1'>Previous Page</A>" : ""]</DIV>"
	dat+= "<DIV STYLE='float:left; text-align:center; width:33.33333%'><A href='?src=\ref[src];remove=1'>Remove Page</A></DIV>"
	dat+= "<DIV STYLE='float:left; text-align:right; width:33.33333%'>[(screen & SHOW_LINK_NEXT)? "<A href='?src=\ref[src];next_page=1'>Next Page</A>" : ""]</DIV>"

	dat += "<BR><HR>[render_content(user, page)]"

	user << browse(dat, "window=[name]")
	onclose(user, "[name]")

/obj/item/weapon/paperwork/bundle/show_content_admin(datum/admins/admin)
	//so that admins can view faxed bundles without interfering with each other
	var/data = "<center><B><U></B>[name]</U></center><BR><BR>"

	for (var/page in 1 to contents.len)
		var/obj/pageobj = contents[page]
		data += "Page [page] - <A href='?src=\ref[src];admin_view_page=[page];admin_holder=\ref[admin]'>[pageobj.name]</A><BR>"

	admin.owner << browse(data, "window=[name]")

/obj/item/weapon/paperwork/bundle/Topic(href, href_list)
	..()
	if(href_list["admin_view_page"])
		//TODO#paperwork Check rights or something
		var/datum/admins/A = locate(href_list["admin_holder"])
		if (A)
			var/obj/item/weapon/paperwork/P = src[href_list["admin_view"]]
			P.show_content_admin(A)
	
	if((src in usr.contents) || (istype(src.loc, /obj/item/weapon/folder) && (src.loc in usr.contents)))
		usr.set_machine(src)
		if(href_list["next_page"])
			set_page(page+1)
			playsound(src.loc, "pageturn", 50, 1)
			add_fingerprint(usr)

		if(href_list["prev_page"])
			set_page(page-1)
			playsound(src.loc, "pageturn", 50, 1)
			add_fingerprint(usr)

		if(href_list["remove"])
			var/obj/item/weapon/W = src[page]
			usr.put_in_hands(W)
			usr << "<span class='notice'>You remove the [W.name] from the bundle.</span>"
			add_fingerprint(usr)

			update_bundle()
			update_icon()
	else
		usr << "<span class='notice'>You need to hold \the [src] in your hands!</span>"

	//refresh the browser window
	if (istype(usr, /mob))
		src.attack_self(usr)
		updateUsrDialog()

//sets the current page
/obj/item/weapon/paperwork/bundle/proc/set_page(var/newpage)
	if (newpage != page)
		page = newpage
		
		//ensure page is within bounds
		page = between(1, page, contents.len)
		screen = 0
		if (page > 1)
			screen |= SHOW_LINK_PREV
		if (page < contents.len)
			screen |= SHOW_LINK_NEXT
		
		update_page_icon()

/obj/item/weapon/paperwork/bundle/verb/remove_all()
	set name = "Loosen Bundle"
	set category = "Object"
	set src in usr

	usr << "<span class='notice'>You take apart the bundle.</span>"
	for(var/obj/O in src)
		O.loc = usr.loc
		O.layer = initial(O.layer)
		O.add_fingerprint(usr)
	usr.drop_from_inventory(src)
	usr << browse(null, "window=[name]") //close the browser window
	del(src)
	return

//Should be called when the bundle is modified
//added var overrides the contents.len check so that bundles are not immediately destroyed when adding the very first item.
/obj/item/weapon/paperwork/bundle/proc/update_bundle(var/added=0)
	//can't have a bundle of 1
	if(!added && contents.len == 1)
		var/obj/item/weapon/paperwork/paper/P = src[1]
		usr.drop_from_inventory(src)
		usr.put_in_hands(P)
		usr << browse(null, "window=[name]") //close the browser window
		del(src)
	
	//ensure page is still within bounds
	page = between(1, page, contents.len)
	screen = 0
	if (page > 1)
		screen |= SHOW_LINK_PREV
	if (page < contents.len)
		screen |= SHOW_LINK_NEXT
	
	updateUsrDialog()
	
	desc = "[contents.len] pages clipped to each other."
	switch (contents.len)
		if (1 to 2)
			throwforce = 0
			w_class = 1
			throw_range = 1
			throw_speed = 1
		if (3 to 4)
			throwforce = 0
			w_class = 1
			throw_range = 2
			throw_speed = 1
		if (5 to 8)
			throwforce = 0
			w_class = 2
			throw_range = 3
			throw_speed = 1
		if (9 to 16)
			desc = "A huge stack of papers."
			throwforce = 3
			w_class = 3
			throw_range = 5
			throw_speed = 2
		if (17 to INFINITY)
			desc = "An enormous stack of papers!"
			throwforce = 5
			w_class = 4
			throw_range = 7
			throw_speed = 3

/obj/item/weapon/paperwork/bundle/update_icon()
	update_page_icon()
	
	var/papercount = 1
	for(var/obj/item/weapon/paperwork/O in contents)
		if (O == src[page]) continue
		
		var/image/img = image(O.icon)
		img.icon_state = O.icon_state
		img.pixel_x -= min(1*papercount, 2)
		img.pixel_y -= min(1*papercount, 2)
		pixel_x = min(0.5*papercount, 1)
		pixel_y = min(  1*papercount, 2)
		underlays += img
		papercount++

/obj/item/weapon/paperwork/bundle/proc/update_page_icon()
	var/obj/item/weapon/paperwork/P = src[page]
	icon = P.icon
	icon_state = P.icon_state
	overlays = P.overlays
	overlays += image('icons/obj/bureaucracy.dmi', "clip")