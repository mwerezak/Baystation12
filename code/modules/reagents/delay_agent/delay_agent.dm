/datum/reagent/delay_agent
	name = "Delay Agent"
	id = "delay_agent"
	description = "TODO"
	reagent_state = SOLID
	color = "#C0CBCF"
	metabolism = 0
	taste_description = "burnt plastic"
	scannable = 1
	//glass_icon_state = "glass_clear"
	//glass_name = "glass of water"
	//glass_desc = "The father of all refreshments."

/datum/chemical_reaction/delay_agent_prepare
	required_reagents = list("delay_agent") //technically it only "requires" itself
	catalysts = list("phoron" = 1)