class_name UiCheckEffects
extends RefCounted
## The checks of the effects for ui_check.gd: the warp start, the coins of the report,
## the smoke of scrap, the slide trail (SPEC Sections 20.3, 20.4, 21.1, and 21.5), and
## at the station the flight of new freight and the bounce of a clamp (SPEC Section 21.1).


## At the station: an accepted contract flies its freight to the dock, and a placed
## clamp bounces. Each change is taken back with an undo. A cargo with an offset (the
## slide of a warp) draws a trail. The warp of the check is too fast to draw one.
static func station(ui: Node, station: StationScreen) -> void:
	var hold := station.hold_view
	for c: Dictionary in hold.cargo:
		if c["in_hold"]:
			hold.trail_drawn = false
			hold.offsets[c["id"]] = Vector2(1, 0)
			hold.queue_redraw()
			await ui.get_tree().process_frame
			hold.offsets.clear()
			hold.queue_redraw()
			ui._check(hold.trail_drawn, "a sliding cargo has a trail (SPEC Section 21.1)")
			break
	var run: Dictionary = GameState.view()["run"]
	for k: Dictionary in run["contracts"]:
		if not k["accepted"] and GameState.accept_contract(k["index"]) == "":
			ui._check(
				station._fx.played.has("fly"),
				"the freight of an accepted contract flies to the dock (SPEC Section 21.1)"
			)
			GameState.undo()
			break
	run = GameState.view()["run"]
	if run["free_clamps"] <= 0:
		return
	for c: Dictionary in run["cargo"]:
		if c["in_hold"] and not c["clamped"] and GameState.clamp_cargo(c["id"]) == "":
			ui._check(
				station.hold_view.clamp_bounces.has(c["id"]),
				"a placed clamp bounces (SPEC Section 21.1)"
			)
			GameState.undo()
			break


## After a warp: the jump effect, a coin for each delivered freight, and smoke for
## each new scrap.
static func warp(ui: Node, warp: WarpScreen, warp_log: Dictionary) -> void:
	ui._check(
		warp._top_fx.played.has("jump"),
		"the warp starts with stretched stars and a soft flash (SPEC Section 20.3)"
	)
	var delivered := warp._hold.checks.size()
	ui._check(
		warp._top_fx.coin_flights == delivered,
		(
			"a coin flies from each delivered freight: %d of %d (SPEC Section 20.4)"
			% [warp._top_fx.coin_flights, delivered]
		)
	)
	var scrap := false
	for step: Dictionary in warp_log.get("steps", []):
		for r: Dictionary in step["reactions"]:
			scrap = scrap or r.get("result", "") == Defs.RESULT_SCRAP
	if scrap:
		ui._check(
			warp._fx.played.has("smoke"),
			"a freight that becomes scrap puffs gray smoke (SPEC Section 21.5)"
		)
