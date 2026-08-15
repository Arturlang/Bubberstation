/datum/asset/simple/namespaced/tgfont
	assets = list(
#ifndef OPENDREAM
		// IE-only font format, needed only by BYOND's legacy webview.
		"tgfont.eot" = file("tgui/packages/tgfont/static/tgfont.eot"),
#endif
		"tgfont.woff2" = file("tgui/packages/tgfont/static/tgfont.woff2"),
	)
	parents = list(
		"tgfont.css" = file("tgui/packages/tgfont/static/tgfont.css"),
	)
