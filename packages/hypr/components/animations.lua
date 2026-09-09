-- bezier: hl.curve(name, {type="bezier", points={{x1,y1},{x2,y2}}})
-- animation: hl.animation({leaf=, enabled=, speed=, bezier=, style=})
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/

hl.config({
	animations = {
		enabled = true,
	},
})

hl.curve("smooth", { type = "bezier", points = { { 0.25, 0.1 }, { 0.25, 1 } } })
hl.curve("smoothOut", { type = "bezier", points = { { 0.5, 0.7 }, { 0.1, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 1, bezier = "smoothOut", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 1, bezier = "smoothOut", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1, bezier = "smooth", style = "slide" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1, bezier = "smoothOut", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "smooth" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "smooth" })
