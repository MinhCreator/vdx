-- windowrule: hl.window_rule({name=, match=, ...})
-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/

hl.window_rule({
	name = "filepicker",
	match = { title = ".*wants to open.*" },
	float = false,
})
