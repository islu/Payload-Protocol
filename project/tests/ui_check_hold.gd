class_name UiCheckHold
extends RefCounted
## The checks of the look of the hold for ui_check.gd: the lights of the bulkhead
## (SPEC Section 21.6).


## At the station, each bulkhead has 2 lights, and each light is dark blue. A light
## flashes 3 times each second or less.
static func station(ui: Node, hold: HoldView) -> void:
	var walls := {}
	for l: Dictionary in hold.lights:
		walls[l["wall"]] = walls.get(l["wall"], 0) + 1
	ui._check(
		hold.lights.size() == 8 and walls.values().all(func(n: int) -> bool: return n == 2),
		"each bulkhead has 2 lights: %s (SPEC Section 21.6)" % [walls]
	)
	ui._check(
		hold.lights.all(
			func(l: Dictionary) -> bool: return hold.light_color(l) == HoldView.LIGHT_IDLE
		),
		"at the station, the lights are dark blue (SPEC Section 21.6)"
	)
	hold.light_log.clear()
	hold.light_wall(Defs.DIR_LEFT, HoldView.LIGHT_HIT, 0.2)
	hold.light_wall(Defs.DIR_LEFT, HoldView.LIGHT_HIT, 0.2)
	var shown: Array = hold.light_log.map(func(e: Dictionary) -> bool: return e["shown"])
	ui._check(
		shown == [true, false],
		"a light flashes 3 times each second or less: %s (SPEC Section 21.6)" % [shown]
	)
	hold.lights_off()
	hold.light_log.clear()


## After a warp, the log of the lights has each light of the warp log.
static func warp(ui: Node, hold: HoldView, warp_log: Dictionary) -> void:
	var log := hold.light_log
	var has := func(target: String, color: Color) -> bool:
		return log.any(
			func(e: Dictionary) -> bool: return e["target"] == target and e["color"] == color
		)
	var alarm := false
	var near := {}
	var events: Array = warp_log.get("steps", []).duplicate()
	var inc: Dictionary = warp_log.get("incident", {})
	if not inc.is_empty():
		events.append(inc)
		alarm = inc.get("kind", "") in [Defs.INCIDENT_METEOR, Defs.INCIDENT_HULL_BREACH]
	for step: Dictionary in warp_log.get("steps", []):
		var d: String = step["direction"]
		ui._check(
			has.call(d, HoldView.LIGHT_STEP),
			"a shift step lights its front wall amber: %s (SPEC Section 21.6)" % d
		)
		if step["hits"].any(func(h: Dictionary) -> bool: return h.get("wall", false)):
			ui._check(
				has.call(d, HoldView.LIGHT_HIT),
				"a hit on a wall flashes the lights of that wall white (SPEC Section 21.6)"
			)
	for e: Dictionary in events:
		for r: Dictionary in e.get("reactions", []):
			match r["kind"]:
				Defs.REACT_EXPLOSION:
					alarm = true
				Defs.REACT_LEAK:
					near[HoldView.LIGHT_LEAK] = true
				Defs.REACT_SHORT:
					near[HoldView.LIGHT_SHORT] = true
	if alarm:
		ui._check(
			has.call(HoldView.LIGHT_ALL, HoldView.LIGHT_ALARM),
			"an explosion, a meteor, and a hull breach turn all lights red (SPEC Section 21.6)"
		)
	for color: Color in near:
		ui._check(
			has.call(HoldView.LIGHT_NEAR, color),
			"a leak or a short flashes the nearest light blue or cyan (SPEC Section 21.6)"
		)
