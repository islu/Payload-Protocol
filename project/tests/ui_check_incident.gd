class_name UiCheckIncident
extends RefCounted
## The checks of the incident in the warp for ui_check.gd (SPEC Section 29.3).

## The number of warps that force() saw.
static var _warps := 0


## Sets the incident of the second warp to an Ion Pulse and of the third to a Hull
## Breach, so that the checks see each kind: the run of seed 11 has meteors only.
## Call it just before the warp: an undo loses the change of GameState.set_up().
static func force() -> void:
	_warps += 1
	var run: Dictionary = GameState.view()["run"]
	var cells := []
	for c: Dictionary in run["cargo"]:
		if c["in_hold"]:
			for s: Dictionary in c["shape"]:
				cells.append(Vector2i(c["x"] + s["x"], c["y"] + s["y"]))
	var at: Vector2i = cells[0] if not cells.is_empty() else Vector2i.ZERO
	match _warps:
		2:
			GameState.set_up(
				func(r: Run) -> void: r.incident = {"kind": Defs.INCIDENT_ION_PULSE, "y": at.y}
			)
		3:
			GameState.set_up(
				func(r: Run) -> void:
					r.incident = {"kind": Defs.INCIDENT_HULL_BREACH, "x": at.x, "y": at.y}
			)


## After a warp with an incident: the mark and the banner stayed until the incident
## ended, and the effect of its kind played.
static func warp(ui: Node, warp: WarpScreen, warp_log: Dictionary) -> void:
	var inc: Dictionary = warp_log.get("incident", {})
	if inc.is_empty():
		return
	var marks := warp.incident_marks
	ui._check(
		marks > 0 and warp._hold.incident_cells.is_empty(),
		"the incident mark stays until the incident ends: %d (SPEC Section 29.3)" % marks
	)
	ui._check(
		warp.incident_banner_held,
		"the banner of the incident shows until the incident ends (SPEC Section 29.3)"
	)
	match inc["kind"]:
		Defs.INCIDENT_METEOR:
			# The fireball stops at the top cargo of the column, or at the floor.
			var want: int = warp._hold.rows
			for h: Dictionary in inc["hits"]:
				want = h["contact"][0]["y"]
			ui._check(
				warp._fx.played.has("meteor") and warp.meteor_stop == want,
				(
					"a fireball falls down the column to row %d, not %d (SPEC Section 29.3)"
					% [want, warp.meteor_stop]
				)
			)
		Defs.INCIDENT_ION_PULSE:
			ui._check(
				warp._fx.played.has("wave") and Sound.requested.has("ion"),
				"a cyan wave with an electric sweep moves along the row (SPEC Section 29.3)"
			)
		Defs.INCIDENT_HULL_BREACH:
			ui._check(
				warp._fx.played.has("crack") and Sound.requested.has("breach"),
				"the deck plate of a Hull Breach cracks with a hiss (SPEC Section 29.3)"
			)
