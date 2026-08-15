/**
 * Skin state dumper for BYOND/OpenDream parity checking.
 *
 * The skin is interpreted entirely client-side, so the only way to see what an engine
 * actually did with skin.dmf is to ask it. winget() is that oracle: it reports the
 * computed geometry of every element after anchoring, splitting and layout.
 *
 * Run "Dump Skin State" under DreamSeeker and again under the OpenDream client, at the
 * same window size, then diff the two files with tools/winget_parity/compare_skin_dumps.py.
 *
 * Only the engine's own answers are recorded here - no interpretation, so that the
 * comparison happens in one place.
 */

#ifdef OPENDREAM
#define WINGET_PARITY_ENGINE "opendream"
#else
#define WINGET_PARITY_ENGINE "byond"
#endif

/// Marker used to split "<element>.type=<value>" wildcard results.
#define WINGET_TYPE_MARKER ".type="

/// Queried for every control. Geometry first, since that is what breaks visibly.
GLOBAL_LIST_INIT(winget_parity_common_params, list(
	"type",
	"pos",
	"size",
	"anchor1",
	"anchor2",
	"is-visible",
	"is-disabled",
	"background-color",
))

/// Queried for every window and pane, in addition to the common params.
GLOBAL_LIST_INIT(winget_parity_window_params, list(
	"inner-size",
	"outer-size",
	"is-pane",
	"can-resize",
	"titlebar",
	"statusbar",
	"is-maximized",
	"is-minimized",
))

/// Queried only for controls of the matching type, to avoid asking for params that
/// an element does not have (which logs noise on OpenDream).
GLOBAL_LIST_INIT(winget_parity_type_params, list(
	"CHILD" = list("splitter", "show-splitter", "is-vert", "left", "right"),
	"MAP" = list("zoom", "zoom-mode", "view-size", "icon-size", "letterbox"),
	"OUTPUT" = list("max-lines", "style"),
	"INPUT" = list("is-multi-line", "no-command"),
	"BROWSER" = list("auto-format", "show-history"),
	"BUTTON" = list("text", "is-flat", "is-checked", "button-type"),
	"LABEL" = list("text", "align"),
	"BAR" = list("value", "width", "dir", "is-slider"),
	"GRID" = list("cells", "is-list", "show-lines"),
	"TAB" = list("current-tab", "tabs"),
	"INFO" = list("tab-text-color", "highlight-color"),
))

/**
 * Collects every skin element's reported state.
 *
 * Returns an assoc list ready for json_encode().
 */
/client/proc/collect_skin_state()
	var/list/state = list()

	state["engine"] = WINGET_PARITY_ENGINE
	state["byond_version"] = "[world.byond_version].[world.byond_build]"
	state["dm_version"] = "[DM_VERSION].[DM_BUILD]"
	// Recorded so the differ can refuse to compare dumps taken at different sizes.
	state["reference_window_size"] = winget(src, "mainwindow", "size")
	state["dpi"] = winget(src, null, "dpi")

	var/list/containers = list()
	for(var/container_kind in list("windows", "panes"))
		var/raw = winget(src, null, container_kind)
		if(!length(raw))
			continue

		for(var/candidate in splittext(raw, ";"))
			var/container_id = trim(candidate)
			if(length(container_id))
				containers |= container_id

	state["containers"] = containers

	var/list/elements = list()
	for(var/container_id in containers)
		elements[container_id] = collect_skin_element(container_id, is_container = TRUE)

		for(var/list/child in discover_child_controls(container_id))
			elements[child["id"]] = collect_skin_element(child["id"], element_type = child["type"])

	state["elements"] = elements
	return state

/**
 * Expands "<window>.*" to its child controls.
 *
 * Queries "type" specifically because its values (MAP, CHILD, ...) can never contain the
 * ";" or "=" used as separators, which keeps the result safe to split.
 *
 * Returns a list of assoc lists with "id" and "type" keys.
 */
/client/proc/discover_child_controls(container_id)
	var/list/children = list()
	var/raw_types = winget(src, "[container_id].*", "type")
	if(!length(raw_types))
		return children

	for(var/entry in splittext(raw_types, ";"))
		var/marker = findtext(entry, WINGET_TYPE_MARKER)
		if(!marker)
			continue

		var/element_id = trim(copytext(entry, 1, marker))
		var/element_type = trim(copytext(entry, marker + length(WINGET_TYPE_MARKER)))
		if(!length(element_id))
			continue

		children += list(list("id" = element_id, "type" = element_type))

	return children

/**
 * Queries the params relevant to a single element.
 *
 * Values are stored exactly as the engine returned them; normalisation is the differ's job.
 */
/client/proc/collect_skin_element(element_id, element_type, is_container = FALSE)
	var/list/wanted = GLOB.winget_parity_common_params.Copy()

	if(is_container)
		wanted |= GLOB.winget_parity_window_params
	else
		var/list/type_params = GLOB.winget_parity_type_params[element_type]
		if(type_params)
			wanted |= type_params

	var/list/params = list()
	for(var/param in wanted)
		params[param] = winget(src, element_id, param)

	return params

ADMIN_VERB(dump_skin_state, R_DEBUG, "Dump Skin State", "Dumps every skin element's winget state to JSON, for BYOND/OpenDream parity comparison.", ADMIN_CATEGORY_DEBUG)
	var/list/state = user.collect_skin_state()
	var/filename = "data/winget_parity_[state["engine"]].json"

	fdel(filename)
	text2file(json_encode(state), filename)

	to_chat(user, span_notice("Skin state for [length(state["elements"])] elements written to [filename]."))
	to_chat(user, span_notice("Reference window size: [state["reference_window_size"]]. Take the other engine's dump at the same size."))

#undef WINGET_PARITY_ENGINE
#undef WINGET_TYPE_MARKER
