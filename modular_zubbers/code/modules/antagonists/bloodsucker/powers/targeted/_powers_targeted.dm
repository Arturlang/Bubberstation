// NOTE: All Targeted spells are Toggles! We just don't bother checking here.
/datum/action/cooldown/bloodsucker/targeted
	power_flags = BP_AM_TOGGLE
	click_to_activate = TRUE
	///If set, how far the target has to be for the power to work.
	var/target_range
	///Message sent to chat when clicking on the power, before you use it.
	var/prefire_message
	///Most powers happen the moment you click. Some, like Mesmerize, require time and shouldn't cost you if they fail.
	var/power_activates_immediately = TRUE
	///Is this power LOCKED due to being used?
	var/power_in_use = FALSE

/// Modify description to add notice that this is aimed.
/datum/action/cooldown/bloodsucker/targeted/New(Target)
	desc += "<br>\[<i>Targeted Power</i>\]"
	return ..()

/datum/action/cooldown/bloodsucker/targeted/Remove(mob/living/remove_from)
	. = ..()
	if(remove_from.click_intercept == src)
		unset_click_ability(remove_from)

/datum/action/cooldown/bloodsucker/targeted/Trigger(trigger_flags, atom/target)
	. = ..()
	if(!.)
		return FALSE
	if(prefire_message)
		to_chat(owner, span_announce("[prefire_message]"))
	. = FireTargetedPower(target, trigger_flags)

/datum/action/cooldown/bloodsucker/targeted/DeactivatePower(refund_cooldown)
	if(power_flags & BP_AM_TOGGLE)
		STOP_PROCESSING(SSprocessing, src)
	active = FALSE
	// unset_click_ability(owner, refund_cooldown)

/// Check if target is VALID (wall, turf, or character?)
/datum/action/cooldown/bloodsucker/targeted/proc/CheckValidTarget(atom/target_atom)
	if(target_atom == owner)
		return FALSE
	return TRUE

/// Check if valid target meets conditions
/datum/action/cooldown/bloodsucker/targeted/proc/CheckCanTarget(atom/target_atom)
	if(target_range)
		// Out of Range
		if(!(target_atom in view(target_range, owner)))
			if(target_range > 1) // Only warn for range if it's greater than 1. Brawn doesn't need to announce itself.
				owner.balloon_alert(owner, "out of range.")
			return FALSE
	return istype(target_atom)

/// Click Target
/datum/action/cooldown/bloodsucker/targeted/PreActivate(atom/target)
	. = ..()
	// CANCEL RANGED TARGET check
	if(power_in_use || !CheckValidTarget(target))
		return FALSE
	// Valid? (return true means DON'T cancel power!)
	if(!can_pay_cost() || !can_use(owner) || !CheckCanTarget(target))
		return TRUE
	power_in_use = TRUE // Lock us into this ability until it successfully fires off. Otherwise, we pay the blood even if we fail.
	if(power_activates_immediately)
		PowerActivatedSuccesfully() // Mesmerize pays only after success.
	power_in_use = FALSE
	return TRUE

/datum/action/cooldown/bloodsucker/targeted/proc/FireTargetedPower(atom/target, params)
	return FALSE

/// Mostly unused for trigger powers, if you're coding a new bloodsucker ability, use TargetedActivate instead.
/datum/action/cooldown/bloodsucker/targeted/Activate(atom/target)
	. = ..()
	log_combat(owner, target, "used [name] on")

/// The power went off! We now pay the cost of the power.
/datum/action/cooldown/bloodsucker/targeted/proc/PowerActivatedSuccesfully(cooldown_override)
	unset_click_ability(owner)
	pay_cost()
	StartCooldown(cooldown_override)
	DeactivatePower()

// /datum/action/cooldown/bloodsucker/targeted/InterceptClickOn(mob/living/caller, params, atom/target)
// 	. = ..()
	// click_with_power(target)
