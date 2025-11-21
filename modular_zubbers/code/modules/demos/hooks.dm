#ifndef DISABLE_DEMOS
/obj/item/melee_attack_chain(mob/user, atom/target, list/modifiers, list/attack_modifiers = list())
	. = ..()
	SSdemo.mark_dirty(src)
	if(isturf(target))
		SSdemo.mark_turf(target)
	else
		SSdemo.mark_dirty(target)//Proxy replaces src cause it returns an atom that will attack the target on our behalf

/to_chat_immediate(
	target,
	html,
	type = null,
	text = null,
	avoid_highlighting = FALSE,
	// FIXME: These flags are now pointless and have no effect
	handle_whitespace = TRUE,
	trailing_newline = TRUE,
	confidential = FALSE
)
	. = ..()
	if(!confidential)
		if(html)
			SSdemo.write_chat(target, html)
		else
			SSdemo.write_chat(target, text)

/to_chat(
	target,
	html,
	type = null,
	text = null,
	avoid_highlighting = FALSE,
	// FIXME: These flags are now pointless and have no effect
	handle_whitespace = TRUE,
	trailing_newline = TRUE,
	confidential = FALSE
)
	. = ..()
	if(!confidential)
		if(html)
			SSdemo.write_chat(target, html)
		else
			SSdemo.write_chat(target, text)

/mob/Login()
	. = ..()
	SSdemo.write_event_line("setmob [client.ckey] \ref[src]")
	log_mob_tag("NEW OWNER: [key_name(src)]")

/client/New(TopicData)
	. = ..()
	SSdemo.write_event_line("login [ckey]")

/client/Destroy()
	. = ..()
	SSdemo.write_event_line("logout [ckey]")

/atom/movable/onShuttleMove(turf/newT, turf/oldT, list/movement_force, move_dir, obj/docking_port/stationary/old_dock, obj/docking_port/mobile/moving_dock)
	. = ..()
	SSdemo.mark_dirty(src)

/atom
	var/image/demo_last_appearance

/atom/Destroy(force)
	demo_last_appearance = null
	return ..()

/atom/update_icon(updates=ALL)
	. = ..()
	SSdemo.mark_dirty(src)

/atom/update_overlays()
	. = ..()
	SSdemo.mark_dirty(src)

/atom/movable
	var/atom/demo_last_loc

/atom/movable/Destroy(force)
	demo_last_loc = null
	return ..()

/client/New()
	SSdemo.write_event_line("login [ckey]")
	return ..()

/client/Destroy()
	. = ..()
	SSdemo.write_event_line("logout [ckey]")

/client/ooc(msg as text)
	. = ..()
	SSdemo.write_chat_global("<span class='oocplain'><font color='[GLOB.OOC_COLOR]'><b>[span_prefix("OOC:")] <EM>[holder.fakekey ? holder.fakekey : key] <span class='message linkify'>[msg]</span></b></font></span>")

/turf/setDir()
	. = ..()
	SSdemo.mark_turf(src)

/turf/ChangeTurf(path, list/new_baseturfs, flags)
	. = ..()
	SSdemo.mark_turf(.)

/atom/movable/setDir()
	. = ..()
	SSdemo.mark_dirty(src)

/datum/controller/subsystem/chat/queue(queue_target, list/message_data)
	. = ..()
	var/scraped = message_data["html"]
	SSdemo.write_chat(queue_target, scraped)

/atom/movable/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	SSdemo.mark_dirty(src)

/datum/component/overlay_lighting/clean_old_turfs()
	. = ..()
	SSdemo.mark_multiple_turfs(affected_turfs)

/datum/component/overlay_lighting/get_new_turfs()
	. = ..()
	SSdemo.mark_multiple_turfs(affected_turfs)

/datum/light_source/remove_lum()
	. = ..()

/mob/dview
	flags_1 = parent_type::flags_1 | DEMO_IGNORE_1

/mob/oranges_ear
	flags_1 = parent_type::flags_1 | DEMO_IGNORE_1

/mob/living/carbon/human/dummy
	flags_1 = parent_type::flags_1 | DEMO_IGNORE_1

/obj/effect/spawner
	flags_1 = parent_type::flags_1 | DEMO_IGNORE_1

/obj/effect/countdown
	flags_1 = parent_type::flags_1 | DEMO_IGNORE_1

/obj/effect/turf_decal
	flags_1 = parent_type::flags_1 | DEMO_IGNORE_1

/obj/effect/mapping_helpers
	flags_1 = parent_type::flags_1 | DEMO_IGNORE_1

/obj/effect/abstract/name_tag
	flags_1 = parent_type::flags_1 | DEMO_IGNORE_1

/obj/effect/abstract/marker
	flags_1 = parent_type::flags_1 | DEMO_IGNORE_1

/obj/effect/abstract/info
	flags_1 = parent_type::flags_1 | DEMO_IGNORE_1

/obj/effect/abstract/chasm_storage
	flags_1 = parent_type::flags_1 | DEMO_IGNORE_1

/obj/structure/disposalholder
	flags_1 = parent_type::flags_1 | DEMO_IGNORE_1

#endif
