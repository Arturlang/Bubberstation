/mob/dead/new_player/Login()
	if(!client)
		return

	if(CONFIG_GET(flag/use_exp_tracking))
		client?.set_exp_from_db()
		client?.set_db_player_flags()
		if(!client)
			// client disconnected during one of the db queries
			return FALSE

	if(!mind)
		mind = new /datum/mind(key)
		mind.active = TRUE
		mind.set_current(src)

	// Check if user should be added to interview queue
	if (!client.holder && CONFIG_GET(flag/panic_bunker) && CONFIG_GET(flag/panic_bunker_interview) && !(client.ckey in GLOB.interviews.approved_ckeys))
		var/required_living_minutes = CONFIG_GET(number/panic_bunker_living)
		var/living_minutes = client.get_exp_living(TRUE)
		if (required_living_minutes >= living_minutes)
			client.interviewee = TRUE

	. = ..()
	if(!. || !client)
		return FALSE

	var/motd = global.config.motd
	if(motd)
		to_chat(src, "<div class=\"motd\">[motd]</div>", handle_whitespace=FALSE)

	if(GLOB.admin_notice)
		to_chat(src, span_notice("<b>Admin Notice:</b>\n \t [GLOB.admin_notice]"))

	//SKYRAT EDIT ADDITION
	var/soft_player_cap = CONFIG_GET(number/player_soft_cap)
	if(soft_player_cap && TGS_CLIENT_COUNT >= soft_player_cap)
		INVOKE_ASYNC(src, PROC_REF(connect_to_second_server))
	//SKYRAT EDIT END

	var/spc = CONFIG_GET(number/soft_popcap)
	if(spc && living_player_count() >= spc)
		to_chat(src, span_notice("<b>Server Notice:</b>\n \t [CONFIG_GET(string/soft_popcap_message)]"))

	add_sight(SEE_TURFS)

	client.playtitlemusic()

	var/datum/asset/asset_datum = get_asset_datum(/datum/asset/simple/lobby)
	asset_datum.send(client)
	if(!client) // client disconnected during asset transit
		return FALSE

	// The parent call for Login() may do a bunch of stuff, like add verbs.
	// Delaying the register_for_interview until the very end makes sure it can clean everything up
	// and set the player's client up for interview.
	if(client.interviewee)
		register_for_interview()
		return

	if(SSticker.current_state < GAME_STATE_SETTING_UP)
		var/tl = SSticker.GetTimeLeft()
		to_chat(src, "Please set up your character and select \"Ready\". The game will start [tl > 0 ? "in about [DisplayTimeText(tl)]" : "soon"].")

	if(GLOB.unrecommended_builds[num2text(client.byond_build)])
		INVOKE_ASYNC(src, PROC_REF(unrcommended_build_alert))

#ifdef AUTO_OBSERVE
	// Rendering-parity builds only: drop straight into the world as an observer
	// so BYOND and OpenDream can be captured side by side without a human
	// clicking through the lobby. Never defined in a normal build.
	INVOKE_ASYNC(src, PROC_REF(auto_observe))
#endif

#ifdef AUTO_OBSERVE
/mob/dead/new_player/proc/auto_observe()
	// Wait for the round to actually be running, otherwise there is no observer
	// landmark to teleport to yet.
	for(var/i in 1 to 600)
		if(SSticker?.current_state >= GAME_STATE_PLAYING)
			break
		sleep(1 SECONDS)
	if(QDELETED(src) || !client)
		return
	var/client/observer_client = client
	make_me_an_observer(skip_confirmation = TRUE)
	sleep(10 SECONDS)
	dump_lighting_values()
#ifdef AUTO_WALK
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(auto_walk_north_south), observer_client)
#endif

#ifdef AUTO_WALK
/// Walks the observer north and south forever so movement artifacts can be
/// reproduced and captured without a human at the keyboard. Separate from
/// AUTO_OBSERVE because a self-walking observer is surprising if you only
/// wanted to skip the lobby.
/proc/auto_walk_north_south(client/walker)
	while(walker?.mob)
		for(var/i in 1 to 5)
			step(walker.mob, NORTH)
			sleep(2)
		for(var/i in 1 to 5)
			step(walker.mob, SOUTH)
			sleep(2)
#endif

/// Logs the lighting values the SERVER computed, so BYOND and OpenDream can be
/// compared as data rather than as pixels: the renderer only ever draws what
/// these colour matrices say. Sampled around the observer landmark so both
/// engines report the same turfs.
/proc/dump_lighting_values()
	var/obj/effect/landmark/observer_start/start = locate(/obj/effect/landmark/observer_start) in GLOB.landmarks_list
	var/turf/origin = start ? get_turf(start) : locate(1, 1, 1)
	if(!origin)
		return
	// Separate files per engine: DreamDaemon's world.log goes to its own window
	// rather than stdout, and both servers run at once.
#ifdef OPENDREAM
	var/dumpfile = file("lightdump-od.txt")
#else
	var/dumpfile = file("lightdump-by.txt")
#endif
	fdel(dumpfile)
	dumpfile << "LIGHTDUMP origin=([origin.x],[origin.y],[origin.z])"
	for(var/dx in -4 to 4)
		for(var/dy in -4 to 4)
			var/turf/probe = locate(origin.x + dx, origin.y + dy, origin.z)
			if(!probe)
				continue
			var/atom/movable/lighting_object/lo = probe.lighting_object
			if(!lo)
				dumpfile << "LIGHTDUMP ([dx],[dy]) NO_LIGHTING_OBJECT"
				continue
			dumpfile << "LIGHTDUMP ([dx],[dy]) state=[lo.icon_state || "null"] color=[json_encode(lo.color)]"
#endif

/mob/dead/new_player/proc/unrcommended_build_alert()
	var/warning = "Hey! The build of byond you are running ([client.byond_build]) has one or more potential issues that may cause major gameplay disruptions.\n\n\
		You may continue to play, but be aware you may encounter the following issue while playing:\n\"[GLOB.unrecommended_builds[num2text(client.byond_build)]]\"\n\n\
		If possible, we recommend updating your BYOND version.\nIf you are on the latest version, download an earlier release instead from www.byond.com/download/build."
	alert(src, warning, "Bad BYOND Build", "OK")
