/**
 *	MEZMERIZE
 *	 Locks a target in place for a certain amount of time.
 *
 * 	Level 2: Additionally mutes
 * 	Level 3: Can be used through face protection
 * 	Level 5: Doesn't need to be facing you anymore
 */

#define MESMERIZE_GLASSES_LEVEL 3
#define MESMERIZE_FACING_LEVEL 5
/datum/action/cooldown/bloodsucker/targeted/mesmerize
	name = "Mesmerize"
	button_icon_state = "power_mez"
	power_flags = NONE
	check_flags = BP_CANT_USE_IN_TORPOR|BP_CANT_USE_IN_FRENZY|AB_CHECK_INCAPACITATED|AB_CHECK_CONSCIOUS
	purchase_flags = BLOODSUCKER_CAN_BUY|VASSAL_CAN_BUY
	bloodcost = 30
	cooldown_time = 20 SECONDS
	target_range = 4
	power_activates_immediately = FALSE
	unset_after_click = FALSE
	prefire_message = "Whom will you subvert to your will?"
	///Our mesmerized target - Prevents several mesmerizes.
	var/datum/weakref/target_ref
	/// How long it takes us to mesmerize our target.
	var/mesmerize_delay = 4 SECONDS
	/// At what level this ability will blind the target at. Level 0 = never.
	var/blind_at_level = 0
	/// if the ability requires you to be physically facing the target
	var/requires_facing_target = TRUE
	/// if the ability requires you to not have your eyes covered
	var/blocked_by_glasses = TRUE

/datum/action/cooldown/bloodsucker/targeted/mesmerize/get_power_desc()
	. = ..()
	. += "Click any person to, after a [DisplayTimeText(mesmerize_delay)] timer, Mesmerize them.<br>"
	. += "This will completely immobilize them for the next [DisplayTimeText(get_power_time())].<br>"
	if(level_current >= MESMERIZE_MUTE_LEVEL)
		. += " Additionally, they will be muted for [DisplayTimeText(get_mute_time())].<br>"
	if(level_current >= MESMERIZE_GLASSES_LEVEL || !blocked_by_glasses)
		. += "Not blocked by glasses.<br>"
	else
		. += "Blocked by glasses.<br>"
	if(level_current >= MESMERIZE_FACING_LEVEL || !requires_facing_target)
		. += "Does not require the victim to be facing you.<br>"
	else
		. += "Requires the victim to be facing you.<br>"

/datum/action/cooldown/bloodsucker/targeted/mesmerize/get_power_explanation()
	. = ..()
	. += "Click any player to attempt to mesmerize them. This will stun them for [DisplayTimeText(get_power_time())].\n\
		You cannot wear anything covering your face, and both parties must be facing eachother. Obviously, both parties need to not be blind. \n\
		Right clicking with the ability will apply a knockdown, but will also confuse your victim.\n\
		If your target is already mesmerized or a Monster Hunter, the Power will fail.\n\
		Once mesmerized, the target will be unable to move for a certain amount of time, scaling with level.\n\
		At level [MESMERIZE_MUTE_LEVEL], your target will additionally be muted for [DisplayTimeText(get_mute_time())].\n\
		At level [MESMERIZE_GLASSES_LEVEL], you will be able to use the power through items covering your face.\n\
		At level [MESMERIZE_FACING_LEVEL], you will be able to mesmerize regardless of your target's direction.\n\
		Higher levels will increase the time of the mesmerize's freeze.\n\
		Additionally it works on silicon lifeforms, causing a EMP effect instead of a freeze."

/datum/action/cooldown/bloodsucker/targeted/mesmerize/can_use(mob/living/carbon/user, trigger_flags)
	. = ..()
	if(!.) // Default checks
		return FALSE
	if(!user.get_organ_slot(ORGAN_SLOT_EYES))
		// Cant use balloon alert, they've got no eyes!
		to_chat(user, span_warning("You have no eyes with which to mesmerize."))
		return FALSE
	// Check: Eyes covered?
	if(blocked_by_glasses && istype(user) && (user.is_eyes_covered() && level_current <= 2) || !isturf(user.loc))
		user.balloon_alert(user, "your eyes are concealed from sight.")
		return FALSE
	return TRUE

/datum/action/cooldown/bloodsucker/targeted/mesmerize/CheckValidTarget(atom/target_atom)
	. = ..()
	if(!.)
		return FALSE
	return isliving(target_atom)

/datum/action/cooldown/bloodsucker/targeted/mesmerize/CheckCanTarget(atom/target_atom)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/current_target = target_atom // We already know it's carbon due to CheckValidTarget()
	// No mind
	if(!current_target.mind)
		owner.balloon_alert(owner, "[current_target] is mindless.")
		return FALSE
	// Bloodsucker
	if(IS_BLOODSUCKER(current_target))
		owner.balloon_alert(owner, "bloodsuckers are immune to [src].")
		return FALSE
	// Dead/Unconscious
	if(current_target.stat > CONSCIOUS)
		owner.balloon_alert(owner, "[current_target] is not [(current_target.stat == DEAD || HAS_TRAIT(current_target, TRAIT_FAKEDEATH)) ? "alive" : "conscious"].")
		return FALSE
	// Target has eyes?
	if(!current_target.get_organ_slot(ORGAN_SLOT_EYES) && !issilicon(current_target))
		owner.balloon_alert(owner, "[current_target] has no eyes.")
		return FALSE
	// Target blind?
	if(current_target.is_blind() && !issilicon(current_target))
		owner.balloon_alert(owner, "[current_target] is blind.")
		return FALSE
	// Facing target?
	if(requires_facing_target && !is_source_facing_target(owner, current_target)) // in unsorted.dm
		owner.balloon_alert(owner, "you must be facing [current_target].")
		return FALSE
	// Target facing me? (On the floor, they're facing everyone)
	if(((current_target.mobility_flags & MOBILITY_STAND) && requires_facing_target && !is_source_facing_target(current_target, owner) && level_current <= 4))
		owner.balloon_alert(owner, "[current_target] must be facing you.")
		return FALSE

	// Gone through our checks, let's mark our guy.
	target_ref = WEAKREF(current_target)
	return TRUE

/datum/action/cooldown/bloodsucker/targeted/mesmerize/FireTargetedPower(atom/target, params)
	var/mob/living/user = owner
	var/mob/living/carbon/mesmerized_target = target_ref?.resolve()
	if(!mesmerized_target)
		CRASH("mesmerized_target is null")

	perform_indicators(mesmerized_target, mesmerize_delay)

	if(issilicon(mesmerized_target))
		var/mob/living/silicon/mesmerized = mesmerized_target
		mesmerized.emp_act(EMP_HEAVY)
		owner.balloon_alert(owner, "temporarily shut [mesmerized] down.")
		PowerActivatedSuccesfully() // PAY COST! BEGIN COOLDOWN!
		return
	// slow them down during the mesmerize
	mesmerized_target.add_movespeed_modifier(/datum/movespeed_modifier/mesmerize)
	if(level_current >= MESMERIZE_MUTE_LEVEL)
		mute_target(mesmerized_target)
	if(!do_after(user, mesmerize_delay, mesmerized_target, IGNORE_USER_LOC_CHANGE | IGNORE_TARGET_LOC_CHANGE, TRUE, extra_checks = CALLBACK(src, PROC_REF(ContinueActive), user, mesmerized_target)))
		mesmerized_target.remove_movespeed_modifier(/datum/movespeed_modifier/mesmerize)
		StartCooldown(cooldown_time * 0.5)
		return
	mesmerized_target.remove_movespeed_modifier(/datum/movespeed_modifier/mesmerize)
	// Can't quite time it here, but oh well
	to_chat(mesmerized_target, "[src]'s eyes look into yours, and [span_hypnophrase("you feel your mind slipping away")]...")
	/*if(IS_MONSTERHUNTER(mesmerized_target))
		to_chat(mesmerized_target, span_notice("You feel your eyes burn for a while, but it passes."))
		return*/
	if(HAS_TRAIT_FROM_ONLY(mesmerized_target, TRAIT_NO_TRANSFORM, MESMERIZE_TRAIT))
		owner.balloon_alert(owner, "[mesmerized_target] is already in a hypnotic gaze.")
		return
	owner.balloon_alert(owner, "successfully mesmerized [mesmerized_target].")
	mesmerize_effects(user, mesmerized_target)
	PowerActivatedSuccesfully() // PAY COST! BEGIN COOLDOWN!

/datum/action/cooldown/bloodsucker/targeted/mesmerize/FireSecondaryTargetedPower(atom/target, params)
	if(!isliving(target))
		CRASH("[src] somehow casted on a non-living target, should have been stopped by CheckCanTarget.")
	var/mob/living/mesmerized_target = target
	owner.balloon_alert(owner, "gazing [mesmerized_target]...")
	perform_indicators(mesmerized_target, 3 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(combat_mesmerize_effects), owner, mesmerized_target), 2 SECONDS)

/datum/action/cooldown/bloodsucker/targeted/mesmerize/proc/mesmerize_effects(mob/living/user, mob/living/mesmerized_target)
	var/power_time = get_power_time()
	mute_target(mesmerized_target)
	mesmerized_target.Immobilize(power_time)
	mesmerized_target.next_move = world.time + power_time // <--- Use direct change instead. We want an unmodified delay to their next move // mesmerized_target.changeNext_move(power_time) // check click.dm
	ADD_TRAIT(mesmerized_target, TRAIT_NO_TRANSFORM, MESMERIZE_TRAIT) // <--- Fuck it. We tried using next_move, but they could STILL resist. We're just doing a hard freeze.
	addtimer(CALLBACK(src, PROC_REF(end_mesmerize), user, mesmerized_target), power_time)

/datum/action/cooldown/bloodsucker/targeted/mesmerize/proc/combat_mesmerize_effects(mob/living/user, mob/living/mesmerized_target)
	if(!ContinueActive(user, mesmerized_target))
		StartCooldown(cooldown_time * 0.5)
		owner.balloon_alert(owner, "failed!")
		return
	to_chat(mesmerized_target, "[src]'s eyes look into yours, and [span_hypnophrase("your head becomes fuzzy for a moment")]...")
	var/effect_time = combat_mesmerize_time()
	var/secondary_effect_time = get_power_time()
	mesmerized_target.adjust_confusion(secondary_effect_time)
	mute_target(mesmerized_target)
	mesmerized_target.Knockdown(effect_time)
	PowerActivatedSuccesfully()

/datum/action/cooldown/bloodsucker/targeted/mesmerize/proc/get_power_time()
	return 9 SECONDS + level_current * 1.5 SECONDS

/datum/action/cooldown/bloodsucker/targeted/mesmerize/proc/get_mute_time()
	return get_power_time() * 2

/datum/action/cooldown/bloodsucker/targeted/mesmerize/proc/combat_mesmerize_time()
	return get_power_time() * 0.3

/datum/action/cooldown/bloodsucker/targeted/mesmerize/proc/blind_target(mob/living/mesmerized_target)
	if(!blind_at_level && level_current < blind_at_level)
		return
	mesmerized_target.become_blind(MESMERIZE_TRAIT)

/datum/action/cooldown/bloodsucker/targeted/mesmerize/proc/mute_target(mob/living/mesmerized_target)
	if(level_current >= MESMERIZE_MUTE_LEVEL)
		mesmerized_target.set_silence_if_lower(get_mute_time())

/datum/action/cooldown/bloodsucker/targeted/mesmerize/DeactivatePower()
	target_ref = null
	. = ..() 

/datum/action/cooldown/bloodsucker/targeted/mesmerize/proc/end_mesmerize(mob/living/user, mob/living/target)
	REMOVE_TRAIT(target, TRAIT_NO_TRANSFORM, MESMERIZE_TRAIT)
	target.cure_blind(MESMERIZE_TRAIT)
	// They Woke Up! (Notice if within view)
	if(istype(user) && target.stat == CONSCIOUS && (target in view(6, get_turf(user))))
		owner.balloon_alert(owner, "[target] snapped out of their trance.")

/datum/action/cooldown/bloodsucker/targeted/mesmerize/ContinueActive(mob/living/user, mob/living/target)
	return ..() && can_use(user) && CheckCanTarget(target)

/datum/action/cooldown/bloodsucker/targeted/mesmerize/proc/perform_indicators(mob/target, duration)
	// Display an animated overlay over our head to indicate what's going on
	eldritch_eye(target, "eye_open", 1 SECONDS)
	var/main_duration = max(duration - 2 SECONDS, 1 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(eldritch_eye), target, "eye_flash", main_duration), 1 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(eldritch_eye), target,  "eye_close", 1 SECONDS), main_duration + 1 SECONDS)

/// Display an animated overlay over our head to indicate what's going on
/datum/action/cooldown/bloodsucker/targeted/mesmerize/proc/eldritch_eye(mob/target, icon_state = "eye_open", duration = 1 SECONDS)
	var/image/image = image('icons/effects/eldritch.dmi', owner, icon_state, ABOVE_ALL_MOB_LAYER, pixel_x = -owner.pixel_x, pixel_y = 28)
	SET_PLANE_EXPLICIT(image, ABOVE_LIGHTING_PLANE, owner)
	flick_overlay_global(image, list(owner?.client, target?.client), duration)

#undef MESMERIZE_GLASSES_LEVEL
#undef MESMERIZE_FACING_LEVEL
