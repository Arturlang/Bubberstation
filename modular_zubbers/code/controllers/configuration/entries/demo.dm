
/world/SetupLogs()
	. = ..()
	var/override_dir = params[OVERRIDE_LOG_DIRECTORY_PARAMETER]
	if(!override_dir)
		GLOB.demo_directory = "data/replays"
	else
		GLOB.demo_directory = "data/logs/[override_dir]
	GLOB.demo_log = "[GLOB.demo_directory]/[GLOB.round_id]_demo.log"

/datum/config_entry/flag/demos_enabled
	default = FALSE
