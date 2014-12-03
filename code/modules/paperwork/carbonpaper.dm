/obj/item/weapon/paperwork/paper/carbon
	name = "paper"
	icon_state = "paper_stack"
	item_state = "paper"
	var copied = 0

/obj/item/weapon/paperwork/paper/carbon/update_icon()
	..()
	if (!copied)
		switch (icon_state)
			if("paper")
				icon_state = "paper_stack_words"
			if("paper_words")
				icon_state = "paper_stack"

//the paper you get from tearing off the back of carbon paper
/obj/item/weapon/paperwork/paper/copy
	name = "paper"
	icon_state = "cpaper"
	item_state = "paper"

/obj/item/weapon/paperwork/paper/copy/update_icon()
	..()
	switch (icon_state)
		if("paper")
			icon_state = "cpaper_words"
		if("paper_words")
			icon_state = "cpaper"

/obj/item/weapon/paperwork/paper/carbon/verb/removecopy()
	set name = "Remove carbon-copy"
	set category = "Object"
	set src in usr

	if (copied == 0)
		var/obj/item/weapon/paperwork/paper/carbon/c = src
		var/copycontents = html_decode(c.info)
		var/obj/item/weapon/paperwork/paper/carbon/copy = new /obj/item/weapon/paperwork/paper/carbon (usr.loc)
		copycontents = replacetext(copycontents, "<font face=\"[c.deffont]\" color=", "<font face=\"[c.deffont]\" nocolor=")	//state of the art techniques in action
		copycontents = replacetext(copycontents, "<font face=\"[c.crayonfont]\" color=", "<font face=\"[c.crayonfont]\" nocolor=")	//This basically just breaks the existing color tag, which we need to do because the innermost tag takes priority.
		copy.info += copycontents
		copy.info += "</font>"
		copy.name = "Copy - " + c.name
		copy.fields = c.fields
		copy.updateinfolinks()
		usr << "<span class='notice'>You tear off the carbon-copy!</span>"
		c.copied = 1
		copy.iscopy = 1
		copy.update_icon()
		c.update_icon()
	else
		usr << "There are no more carbon copies attached to this paper!"