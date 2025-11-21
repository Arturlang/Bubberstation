#ifndef DISABLE_DEMOS
/obj/item/melee_attack_chain(mob/user, atom/target, list/modifiers, list/attack_modifiers = list())
	. = ..()
	SSdemo.mark_dirty(src)
	if(isturf(target))
		SSdemo.mark_turf(target)
	else
		SSdemo.mark_dirty(target)//Proxy replaces src cause it returns an atom that will attack the target on our behalf

/proc/to_chat_immediate()
	. = ..()
	if(!confidential)
		SSdemo.write_chat(target, message)

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

/atom/New(loc, ...)
	. = ..()
	SSdemo.mark_dirty(src)

/atom/Destroy(force)
	demo_last_appearance = null
	return ..()

/atom/update_icon(updates=ALL)
	. = ..()
	SSdemo.mark_dirty(src)

/atom/update_overlays
	. = ..()
	SSdemo.mark_dirty(src)

/atom/movable
	var/atom/demo_last_loc

/atom/movable/Destroy(force)
	demo_last_loc = null
	return ..()

/client/New()
	SSdemo?.write_event_line("login [ckey]")
	return ..()

/client/Destroy()
	. = ..()
	SSdemo?.write_event_line("logout [ckey]")

/turf/setDir()
	. = ..()
	SSdemo.marked_turfs?[src] = TRUE

/turf/ChangeTurf(path, list/new_baseturfs, flags)
	. = ..()
	SSdemo.mark_turf(new_turf)

/atom/movable/setDir()
	. = ..()
	SSdemo.mark_dirty(src)

/datum/controller/subsystem/chat/queue(queue_target, list/message_data)
	. = ..()
	var/scraped = message_data["html"]
	SSdemo.write_chat(target, scraped)

/atom/movable/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	SSdemo.mark_dirty(src)

#endif
