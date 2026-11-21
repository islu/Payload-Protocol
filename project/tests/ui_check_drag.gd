class_name UiCheckDrag
## The drag feedback part of the UI check (ui_check.gd): the preview, a drop that is
## not valid, and the pick up of the next cargo (SPEC Sections 8.2, 8.3, and 23.1). It
## is in its own file, so that ui_check.gd stays under the line limit of gdlint.

## True after the checks ran one time. They need 3 cargo on the dock.
static var done := false


static func check(ui: Node, station: StationScreen) -> void:
	var run: Dictionary = GameState.view()["run"]
	if done or run["dock"].size() < 3:
		return
	done = true
	var drag := station._drag
	var first: int = run["dock"][0]
	var second: int = run["dock"][1]
	# A drag (not a pick up) of the first dock cargo into the hold.
	var at := _free_place(station, first)
	ui._check(at != Vector2.INF, "setup: the first dock cargo has a place in the hold")
	if at == Vector2.INF:
		return
	drag.begin_cargo(first, _grab(station, first))
	drag.drop_at(at)
	ui._check(
		drag.state.get("id", -1) == second and drag.state.get("held", false),
		"after a drag from the dock into the hold, the next cargo is picked up (SPEC Section 8.2)"
	)
	# The next cargo over the first one: the drop is not valid.
	var hold := station.hold_view
	var over := _cell_center(hold, _first_cell(station, first))
	drag.update(over)
	var p := hold.preview
	ui._check(
		not p.is_empty() and not p["ok"] and first in p.get("blocking", []),
		"the preview frames the cargo in the way (SPEC Section 8.3)"
	)
	ui._check(
		p.get("cells", []).any(func(e: Dictionary) -> bool: return not e["free"]),
		"the preview marks the cells that are not free (SPEC Section 8.3)"
	)
	ui._check(
		p.get("nearest") == null or hold.ghost_cells().size() == p["cells"].size(),
		"the ghost has the shape of the cargo at the nearest place (SPEC Section 8.3)"
	)
	drag.drop_at(over)
	ui._check(
		drag.state.get("id", -1) == second and drag.state.get("held", false),
		"after a drop that is not valid, the player keeps the cargo (SPEC Section 8.3)"
	)
	ui._check(
		GameState.view()["run"]["dock"].has(second),
		"the cargo stays on the dock after a drop that is not valid (SPEC Section 8.3)"
	)
	drag.end()
	# With the setting off, a drop from the dock picks up nothing.
	Settings.set_value("pick_next", false)
	at = _free_place(station, second)
	if at != Vector2.INF:
		drag.begin_cargo(second, _grab(station, second))
		drag.drop_at(at)
		ui._check(
			drag.state.is_empty(),
			"with the setting off, the next cargo is not picked up (SPEC Section 23.1)"
		)
	Settings.set_value("pick_next", true)
	drag.end()


## The grab cell of a cargo: the first cell of its shape in its rotation now.
static func _grab(station: StationScreen, id: int) -> Vector2:
	var c := station.cargo_view(id)
	var first: Dictionary = c["rotations"][c["rot"]][0]
	return Vector2(first["x"], first["y"])


## The first cell of a cargo in the hold.
static func _first_cell(station: StationScreen, id: int) -> Vector2i:
	var c := station.cargo_view(id)
	var s: Dictionary = c["rotations"][c["rot"]][0]
	return Vector2i(c["x"] + s["x"], c["y"] + s["y"])


## The global position of the center of a cell of the hold: the grab cell of a held
## cargo goes there (SPEC Section 8.3).
static func _cell_center(hold: HoldView, at: Vector2i) -> Vector2:
	return hold.cell_global(Vector2(at) + Vector2(0.5, 0.5))


## The global position of a valid drop of a cargo in the hold, or Vector2.INF.
static func _free_place(station: StationScreen, id: int) -> Vector2:
	var grab := _grab(station, id)
	var cell := free_cell(id, station.cargo_view(id)["rot"])
	if cell.x < 0:
		return Vector2.INF
	return _cell_center(station.hold_view, cell + Vector2i(grab))


## Returns the first cell of the hold where a cargo fits in a rotation, or (-1, -1).
## The UI checks use it to place a cargo.
static func free_cell(id: int, rot: int) -> Vector2i:
	var run: Dictionary = GameState.view()["run"]
	for y: int in run["hold"]["rows"]:
		for x: int in run["hold"]["columns"]:
			if GameState.can_place(id, x, y, rot):
				return Vector2i(x, y)
	return Vector2i(-1, -1)
