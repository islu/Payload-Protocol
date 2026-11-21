class_name UiCheckBay
## The stasis bay part of the UI check (ui_check.gd). It is in its own file, so that
## ui_check.gd stays under the line limit of gdlint.


## Buys the stasis bay. A drop of freight on it is not valid, and a kit goes in it
## (SPEC Sections 17.2 and 31). The kit stays there, so that the warp shows the stasis bay too.
static func check(ui: Node, state: Node, station: StationScreen) -> void:
	ui._check(not station.bay_view.visible, "before the purchase, the station shows no stasis bay")
	ui._check(state.buy_shock_bay() == "", "buy the stasis bay (SPEC Section 17.2)")
	await ui.get_tree().process_frame
	ui._check(
		station.bay_view.visible,
		"after the purchase, the station shows the stasis bay (SPEC Section 31.2)"
	)
	var bay := station.bay_view.get_global_rect()
	var hold := station.hold_view
	var grid := Rect2(
		hold.global_position + hold.grid_origin(), Vector2(hold.columns, hold.rows) * hold.cell
	)
	ui._check(
		(
			bay.end.x <= grid.position.x
			and bay.get_center().y > grid.position.y
			and bay.get_center().y < grid.end.y
		),
		"the stasis bay is at the left of the hold: %s, grid %s (SPEC Section 31.2)" % [bay, grid]
	)
	var bay_grid := Rect2(
		station.bay_view.global_position + station.bay_view.grid_origin(),
		Vector2(station.bay_view.columns, station.bay_view.rows) * station.bay_view.cell
	)
	ui._check(
		absf(bay_grid.get_center().y - grid.get_center().y) < 2.0,
		(
			"the stasis bay is at the vertical center of the hold: %d, %d (SPEC Section 31.2)"
			% [bay_grid.get_center().y, grid.get_center().y]
		)
	)
	var title := station.bay_title
	ui._check(
		(
			title != null
			and title.is_visible_in_tree()
			and ui.tr(StationScreen.BAY_TITLE_TEXT) in title.text
		),
		"a title above the stasis bay names what it takes (SPEC Section 31.2)"
	)
	if title != null:
		title.mouse_entered.emit()
		ui._check(
			station._tip.visible and ui.tr(StationScreen.BAY_RULE_TEXT) in station._tip.text(),
			"the tooltip of the stasis bay shows its rules (SPEC Section 31.2)"
		)
		title.mouse_exited.emit()
	var freight := _on_dock(state, true)
	if not freight.is_empty():
		ui._check(
			not await _drop_in_bay(ui, state, station, freight),
			"a drop of freight on the stasis bay is not valid (SPEC Section 31.1)"
		)
	var kit := _on_dock(state, false)
	if kit.is_empty():
		for o: Dictionary in state.view()["run"]["shop"]["offers"]:
			if o["afford"] and not o["bought"] and o["shape"].size() <= 2:
				ui._check(state.buy_kit(o["index"]) == "", "buy a kit for the stasis bay")
				break
		await ui.get_tree().process_frame
		kit = _on_dock(state, false)
	ui._check(not kit.is_empty(), "the dock has a kit for the stasis bay")
	if not kit.is_empty():
		ui._check(
			await _drop_in_bay(ui, state, station, kit),
			"a drop of a kit on the stasis bay puts it in (SPEC Section 31.1)"
		)
		await _check_bay_hover(ui, state, station, kit)


## The mouse on each cell of a cargo in the stasis bay shows its frame, also at the right
## of the bay, near the hold (SPEC Section 4.2).
static func _check_bay_hover(
	ui: Node, state: Node, station: StationScreen, kit: Dictionary
) -> void:
	var c: Dictionary = {}
	for d: Dictionary in state.view()["run"]["cargo"]:
		if d["id"] == kit["id"]:
			c = d
	if c.is_empty() or not c["in_bay"]:
		return
	for s: Dictionary in c["shape"]:
		var at := station.bay_view.cell_global(
			Vector2(c["x"] + s["x"], c["y"] + s["y"]) + Vector2(0.75, 0.5)
		)
		var motion := InputEventMouseMotion.new()
		motion.position = at
		motion.global_position = at
		ui.get_viewport().push_input(motion, true)
		await ui.get_tree().process_frame
		ui._check(
			station.bay_view.frame_cells().size() == c["shape"].size(),
			"the mouse on a cargo in the stasis bay shows its frame at %s (SPEC Section 4.2)" % at
		)


## Returns a cargo of 2 cells at most on the dock: freight, or kit and scrap.
static func _on_dock(state: Node, freight: bool) -> Dictionary:
	for c: Dictionary in state.view()["run"]["cargo"]:
		if c["in_hold"] or c["in_bay"] or c["shape"].size() > 2:
			continue
		if (c["kind"] == Defs.KIND_FREIGHT) == freight:
			return c
	return {}


## Drags a cargo of the dock onto the stasis bay. Reports whether it is in the stasis bay.
static func _drop_in_bay(ui: Node, state: Node, station: StationScreen, c: Dictionary) -> bool:
	var first: Dictionary = c["rotations"][c["rot"]][0]
	var grab := Vector2(first["x"], first["y"])
	var at := station.bay_view.cell_global(grab + Vector2(0.5, 0.5))
	station._drag.begin_cargo(c["id"], grab)
	station._drag.update()
	station._drag.drop_at(at)
	# A drop from the dock picks up the next cargo (SPEC Section 8.2), and a drop that is
	# not valid keeps the cargo: put it back.
	station._drag.end()
	await ui.get_tree().process_frame
	for d: Dictionary in state.view()["run"]["cargo"]:
		if d["id"] == c["id"]:
			return d["in_bay"]
	return false
