var/image/contamination_overlay = image('icons/effects/contamination.dmi')

/pl_control
	var/PHORON_DMG = 3
	var/PHORON_DMG_NAME = "Phoron Damage Amount"
	var/PHORON_DMG_DESC = "Self Descriptive"

	var/CLOTH_CONTAMINATION = 1
	var/CLOTH_CONTAMINATION_NAME = "Cloth Contamination"
	var/CLOTH_CONTAMINATION_DESC = "If this is on, phoron does damage by getting into cloth."

	var/PHORONGUARD_ONLY = 0
	var/PHORONGUARD_ONLY_NAME = "\"PhoronGuard Only\""
	var/PHORONGUARD_ONLY_DESC = "If this is on, only biosuits and spacesuits protect against contamination and ill effects."

	var/GENETIC_CORRUPTION = 0
	var/GENETIC_CORRUPTION_NAME = "Genetic Corruption Chance"
	var/GENETIC_CORRUPTION_DESC = "Chance of genetic corruption as well as toxic damage, X in 10,000."

	var/SKIN_BURNS = 0
	var/SKIN_BURNS_DESC = "Phoron has an effect similar to mustard gas on the un-suited."
	var/SKIN_BURNS_NAME = "Skin Burns"

	var/EYE_BURNS = 1
	var/EYE_BURNS_NAME = "Eye Burns"
	var/EYE_BURNS_DESC = "Phoron burns the eyes of anyone not wearing eye protection."
	
	var/MINOR_EXPOSURE_CHANCE = 2
	var/MINOR_EXPOSURE_CHANCE_NAME = "Minor Exposure Burn Rate"
	var/MINOR_EXPOSURE_CHANCE_DESC = "Affects how badly a someone will be burned with just minor exposure (hands, feet). 100 means they will get the same burns as major exposure (head, body)."

	var/MINOR_CONTAMINATION_CHANCE = 1
	var/MINOR_CONTAMINATION_CHANCE_NAME = "Minor Exposure Contamination Chance"
	var/MINOR_CONTAMINATION_CHANCE_DESC = "The chance that fucking phoron will get in through openings in a not adequately sealed suit (hands, head, feet) and contaminate everything inside."
	
	var/CONTAMINATION_LOSS = 0.02
	var/CONTAMINATION_LOSS_NAME = "Contamination Loss"
	var/CONTAMINATION_LOSS_DESC = "How much toxin damage is dealt from contaminated clothing" //Per tick?  ASK ARYN

	var/PHORON_HALLUCINATION = 0
	var/PHORON_HALLUCINATION_NAME = "Phoron Hallucination"
	var/PHORON_HALLUCINATION_DESC = "Does being in phoron cause you to hallucinate?"

	var/N2O_HALLUCINATION = 1
	var/N2O_HALLUCINATION_NAME = "N2O Hallucination"
	var/N2O_HALLUCINATION_DESC = "Does being in sleeping gas cause you to hallucinate?"


obj/var/contaminated = 0


/obj/item/proc/can_contaminate()
	//Clothing and backpacks can be contaminated.
	if(flags & PHORONGUARD) return 0
	else if(istype(src,/obj/item/weapon/storage/backpack)) return 0 //Cannot be washed :(
	else if(istype(src,/obj/item/clothing)) return 1

/obj/item/proc/contaminate()
	//Do a contamination overlay? Temporary measure to keep contamination less deadly than it was.
	if(!contaminated)
		contaminated = 1
		overlays += contamination_overlay

/obj/item/proc/decontaminate()
	contaminated = 0
	overlays -= contamination_overlay

/mob/proc/contaminate()

/mob/living/carbon/human/contaminate()
	//See if anything can be contaminated.
	var/will_contaminate = 0
	if(!pl_suit_protected())
		will_contaminate = 1
	else
		//Phoron can sometimes get through such an open suit.
		//more points of exposure means more chance of exposure
		if(!pl_head_protected() && prob(vsc.plc.MINOR_CONTAMINATION_CHANCE)) will_contaminate = 1
		if(!pl_hands_protected() && prob(vsc.plc.MINOR_CONTAMINATION_CHANCE)) will_contaminate = 1
		if(!pl_feet_protected() && prob(vsc.plc.MINOR_CONTAMINATION_CHANCE)) will_contaminate = 1
		if(!pl_tail_protected() && prob(vsc.plc.MINOR_CONTAMINATION_CHANCE)) will_contaminate = 1
	
	if (will_contaminate)
		suit_contamination()

//Cannot wash backpacks currently.
//	if(istype(back,/obj/item/weapon/storage/backpack))
//		back.contaminate()

/mob/proc/pl_effects()

/mob/living/carbon/human/pl_effects()
	//Handles all the bad things phoron can do.

	//Contamination
	if(vsc.plc.CLOTH_CONTAMINATION) contaminate()

	//Anything else requires them to not be dead.
	if(stat >= 2)
		return

	//Burn skin if exposed.
	if(vsc.plc.SKIN_BURNS)
		var/will_burn = 0
		if(!pl_head_protected() || !pl_suit_protected())	//major areas
			will_burn = 1
		else
			//minor areas
			//more points of exposure means more chance of exposure
			if(!pl_hands_protected() && prob(vsc.plc.MINOR_EXPOSURE_CHANCE)) will_burn = 1
			if(!pl_feet_protected() && prob(vsc.plc.MINOR_EXPOSURE_CHANCE)) will_burn = 1
			if(!pl_tail_protected() && prob(vsc.plc.MINOR_EXPOSURE_CHANCE)) will_burn = 1

		if(will_burn)
			burn_skin(0.75)
			if(prob(20)) src << "\red Your skin burns!"
			updatehealth()
				
	//Burn eyes if exposed.
	if(vsc.plc.EYE_BURNS)
		if(!head)
			if(!wear_mask)
				burn_eyes()
			else
				if(!(wear_mask.flags & MASKCOVERSEYES))
					burn_eyes()
		else
			if(!(head.flags & HEADCOVERSEYES))
				if(!wear_mask)
					burn_eyes()
				else
					if(!(wear_mask.flags & MASKCOVERSEYES))
						burn_eyes()

	//Genetic Corruption
	if(vsc.plc.GENETIC_CORRUPTION)
		if(rand(1,10000) < vsc.plc.GENETIC_CORRUPTION)
			randmutb(src)
			src << "\red High levels of phoron cause you to spontaneously mutate."
			domutcheck(src,null)


/mob/living/carbon/human/proc/burn_eyes()
	//The proc that handles eye burning.
	if(prob(20)) src << "\red Your eyes burn!"
	var/datum/organ/internal/eyes/E = internal_organs["eyes"]
	E.damage += 2.5
	eye_blurry = min(eye_blurry+1.5,50)
	if (prob(max(0,E.damage - 15) + 1) &&!eye_blind)
		src << "\red You are blinded!"
		eye_blind += 20

/mob/living/carbon/human/proc/pl_head_protected()
	//Checks if the head is adequately sealed.
	if(vsc.plc.PHORONGUARD_ONLY)
		if(head && (head.flags & PHORONGUARD))
			return 1
	else
		var/face_protected = 0
		var/eyes_protected = 0
		var/ears_protected = 0
		
		if (wear_mask) 
			if (wear_mask.flags_inv & HIDEFACE) face_protected = 1	//this makes gasmasks able to serve as adequate protection - real ones come with a protective hood anyways.
			if (wear_mask.flags_inv & HIDEEYES) eyes_protected = 1
			if (wear_mask.flags_inv & HIDEEARS) ears_protected = 1
		
		if (head)
			if (head.flags_inv & HIDEMASK) face_protected = 1
			if (head.flags_inv & HIDEEYES) eyes_protected = 1
			if (head.flags_inv & HIDEEARS) ears_protected = 1
		
		return face_protected && eyes_protected && ears_protected
	return 0

/mob/living/carbon/human/proc/pl_hands_protected()
	if(vsc.plc.PHORONGUARD_ONLY)
		if(gloves && (gloves.flags & PHORONGUARD)) return 1
		if(wear_suit && ((wear_suit.flags_inv & HIDEGLOVES) && (wear_suit.flags & PHORONGUARD))) return 1
	else
		if(gloves) return 1
		if(wear_suit && (wear_suit.flags_inv & HIDEGLOVES)) return 1
	return 0

/mob/living/carbon/human/proc/pl_feet_protected()
	if(vsc.plc.PHORONGUARD_ONLY)
		if(shoes && (shoes.flags & PHORONGUARD)) return 1
		if(wear_suit && ((wear_suit.flags_inv & HIDESHOES) && (wear_suit.flags & PHORONGUARD))) return 1
	else
		if(shoes) return 1	//need to do more here. currently this makes sandals and slippers count as adequate foot protection.
		if(wear_suit && (wear_suit.flags_inv & HIDESHOES)) return 1
	return 0

/mob/living/carbon/human/proc/pl_tail_protected()
	if(!(species.flags & HAS_TAIL))
		return 1
	if(wear_suit && (wear_suit.flags_inv & HIDETAIL))
		if(vsc.plc.PHORONGUARD_ONLY)
			if(wear_suit.flags & PHORONGUARD) return 1
		else
			return 1
	return 0

/mob/living/carbon/human/proc/pl_suit_protected()
	//Checks if the suit is adequately sealed.
	if(wear_suit)
		if(vsc.plc.PHORONGUARD_ONLY)
			if(wear_suit.flags & PHORONGUARD) return 1
		else
			if(wear_suit.flags_inv & HIDEJUMPSUIT) return 1
	return 0

/mob/living/carbon/human/proc/suit_contamination()
	//Runs over the things that can be contaminated and does so.
	if(w_uniform) w_uniform.contaminate()
	if(shoes) shoes.contaminate()
	if(gloves) gloves.contaminate()


turf/Entered(obj/item/I)
	. = ..()
	//Items that are in phoron, but not on a mob, can still be contaminated.
	if(istype(I) && vsc.plc.CLOTH_CONTAMINATION)
		var/datum/gas_mixture/env = return_air(1)
		if(!env)
			return
		if(env.phoron > MOLES_PHORON_VISIBLE + 1)
			if(I.can_contaminate())
				I.contaminate()