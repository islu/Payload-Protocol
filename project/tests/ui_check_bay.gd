class_name UiCheckBay
## The shock bay part of the UI check (ui_check.gd). It is in its own file, so that
## ui_check.gd stays under the line limit of gdlint.


## Buys the shock bay and drags a cargo of the dock into it (SPEC Sections 17.2 and 31).
## The cargo stays there, so that the warp shows the shock bay too.
static func check(ui: Node, state: Node, station: StationScreen) -> void:
	ui._check(not station.bay_view.visible, "before the purchase, the station shows no shock bay")
	ui._check(state.buy_shock_bay() == "", "buy the shock bay (SPEC Section 17.2)")
	await ui.get_tree().process_frame
	ui._check(
		station.bay_view.visible,
		"after the purchase, the shock bay hangs above the hold (SPEC Section 31.2)"
	)
	var run: Dictionary = state.view()["run"]
	for c: Dictionary in run["cargo"]:
		if c["in_hold"] or c["in_bay"] or c["shape"].size() > 2:
			continue
		var first: Dictionary = c["rotations"][c["rot"]][0]
		var grab := Vector2(first["x"], first["y"])
		var bay: HoldView = station.bay_view
		var at := bay.cell_global(grab + Vector2(0.5, 0.5))
		station._drag.begin_cargo(c["id"], grab)
		station._drag.update()
		station._drag.drop_at(at)
		# A drop from the dock picks up the next cargo (SPEC Section 8.2): put it back.
		station._drag.end()
		await ui.get_tree().process_frame
		var moved := false
		for d: Dictionary in state.view()["run"]["cargo"]:
			if d["id"] == c["id"]:
				moved = d["in_bay"]
		ui._check(moved, "a drop on the shock bay puts the cargo in it (SPEC Section 31.1)")
		return
