#define FORTITUDE_STUN_IMMUNITY_LEVEL 4
/datum/action/cooldown/bloodsucker/fortitude
	name = "Fortitude"
	desc = "Withstand egregious physical wounds and walk away from attacks that would stun, pierce, and dismember lesser beings."
	button_icon_state = "power_fortitude"
	power_flags = BP_AM_TOGGLE|BP_AM_COSTLESS_UNCONSCIOUS
	check_flags = BP_CANT_USE_IN_TORPOR|BP_CANT_USE_IN_FRENZY
	purchase_flags = BLOODSUCKER_CAN_BUY|VASSAL_CAN_BUY
	bloodcost = 30
	cooldown_time = 8 SECONDS
	constant_bloodcost = 0.2
	var/was_running
	var/fortitude_resist // So we can raise and lower your brute resist based on what your level_current WAS.

/datum/action/cooldown/bloodsucker/fortitude/get_power_explanation()
	. = ..()
	. += "Fortitude will provide pierce, stun and dismember immunity."
	. += "You will additionally gain resistance to both brute, burn and stamina damage, scaling with level."
	. += "Fortitude will make you receive [GetFortitudeResist() * 10]% less brute and and stamina and [GetBurnResist() * 10]% less burn damage."
	. += "While using Fortitude, attempting to run will crush you."
	. += "At level [FORTITUDE_STUN_IMMUNITY_LEVEL], you gain complete stun immunity."
	. += "Higher levels will increase Brute and Stamina resistance."

/datum/action/cooldown/bloodsucker/fortitude/ActivatePower(atom/target)
	. = ..()
	owner.balloon_alert(owner, "fortitude turned on.")
	to_chat(owner, span_notice("Your flesh, skin, and muscles become as steel."))
	// Traits & Effects
	owner.add_traits(list(TRAIT_PIERCEIMMUNE, TRAIT_NODISMEMBER, TRAIT_PUSHIMMUNE), BLOODSUCKER_TRAIT)
	if(level_current >= FORTITUDE_STUN_IMMUNITY_LEVEL)
		ADD_TRAIT(owner, TRAIT_STUNIMMUNE, BLOODSUCKER_TRAIT)
	var/mob/living/carbon/human/bloodsucker_user = owner
	if(IS_BLOODSUCKER(owner) || IS_VASSAL(owner))
		fortitude_resist = GetFortitudeResist()
		bloodsucker_user.physiology.brute_mod *= fortitude_resist
		bloodsucker_user.physiology.burn_mod *= GetBurnResist()
		bloodsucker_user.physiology.stamina_mod *= fortitude_resist

	was_running = (bloodsucker_user.move_intent == MOVE_INTENT_RUN)
	if(was_running)
		bloodsucker_user.toggle_move_intent()

/datum/action/cooldown/bloodsucker/fortitude/proc/GetFortitudeResist()
	return max(0.3, 0.7 - level_current * 0.1)

/datum/action/cooldown/bloodsucker/fortitude/proc/GetBurnResist()
	return GetFortitudeResist() + 0.2

/datum/action/cooldown/bloodsucker/fortitude/process(seconds_per_tick)
	// Checks that we can keep using this.
	. = ..()
	if(!.)
		return
	if(!active)
		return
	var/mob/living/carbon/user = owner
	/// Prevents running while on Fortitude
	if(user.move_intent != MOVE_INTENT_WALK)
		user.toggle_move_intent()
		user.balloon_alert(user, "you attempt to run, crushing yourself.")
		user.adjustBruteLoss(rand(5,15))
	/// We don't want people using fortitude being able to use vehicles
	if(user.buckled && istype(user.buckled, /obj/vehicle))
		user.buckled.unbuckle_mob(src, force=TRUE)

/datum/action/cooldown/bloodsucker/fortitude/DeactivatePower(deactivate_flags)
	. = ..()
	if(!. || !ishuman(owner))
		return
	var/mob/living/carbon/human/bloodsucker_user = owner
	if(IS_BLOODSUCKER(owner) || IS_VASSAL(owner) && fortitude_resist)
		bloodsucker_user.physiology.brute_mod /= fortitude_resist
		bloodsucker_user.physiology.burn_mod /= fortitude_resist + 0.2
		bloodsucker_user.physiology.stamina_mod /= fortitude_resist
	// Remove Traits & Effects
	owner.remove_traits(list(TRAIT_PIERCEIMMUNE, TRAIT_NODISMEMBER, TRAIT_PUSHIMMUNE, TRAIT_STUNIMMUNE), BLOODSUCKER_TRAIT)

	if(was_running && bloodsucker_user.move_intent == MOVE_INTENT_WALK)
		bloodsucker_user.toggle_move_intent()
	owner.balloon_alert(owner, "fortitude turned off.")
