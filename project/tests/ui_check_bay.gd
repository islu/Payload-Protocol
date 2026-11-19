class_name UiCheckBay
## The shock bay part of the UI check (ui_check.gd). It is in its own file, so that
## ui_check.gd stays under the line limit of gdlint.


## Buys the shock bay. A drop of freight on it is not valid, and a kit goes in it
## (SPEC Sections 17.2 and 31). The kit stays there, so that the warp shows the shock bay too.
static func check(ui: Node, state: Node, station: StationScreen) -> void:
	ui._check(not station.bay_view.visible, "before the purchase, the station shows no shock bay")
	ui._check(state.buy_shock_bay() == "", "buy the shock bay (SPEC Section 17.2)")
	await ui.get_tree().process_frame
	ui._check(
		station.bay_view.visible,
		"after the purchase, the station shows the shock bay (SPEC Section 31.2)"
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
		"the shock bay is at the left of the hold: %s, grid %s (SPEC Section 31.2)" % [bay, grid]
	)
	var freight := _on_dock(state, true)
	if not freight.is_empty():
		ui._check(
			not await _drop_in_bay(ui, state, station, freight),
			"a drop of freight on the shock bay is not valid (SPEC Section 31.1)"
		)
	var kit := _on_dock(state, false)
	if kit.is_empty():
		for o: Dictionary in state.view()["run"]["shop"]["offers"]:
			if o["afford"] and not o["bought"] and o["shape"].size() <= 2:
				ui._check(state.buy_kit(o["index"]) == "", "buy a kit for the shock bay")
				break
		await ui.get_tree().process_frame
		kit = _on_dock(state, false)
	ui._check(not kit.is_empty(), "the dock has a kit for the shock bay")
	if not kit.is_empty():
		ui._check(
			await _drop_in_bay(ui, state, station, kit),
			"a drop of a kit on the shock bay puts it in (SPEC Section 31.1)"
		)


## Returns a cargo of 2 cells at most on the dock: freight, or kit and scrap.
static func _on_dock(state: Node, freight: bool) -> Dictionary:
	for c: Dictionary in state.view()["run"]["cargo"]:
		if c["in_hold"] or c["in_bay"] or c["shape"].size() > 2:
			continue
		if (c["kind"] == Defs.KIND_FREIGHT) == freight:
			return c
	return {}


## Drags a cargo of the dock onto the shock bay. Reports whether it is in the shock bay.
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
