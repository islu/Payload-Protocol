extends RuleTest


func test_new_cargo_goes_to_the_dock() -> void:
	on_dock("box")
	eq(run.dock.size(), 1, "new cargo goes to the dock first (SPEC Section 8.1)")


func test_drop_from_dock_to_hold() -> void:
	var c := on_dock("bar")
	eq(
		run.place_cargo(c.id, Vector2i(4, 5), 0),
		"",
		"a drop moves a cargo to the hold (SPEC Section 8.2)"
	)
	check(run.dock.is_empty() and c.in_hold, "the cargo leaves the dock (SPEC Section 8.2)")


func test_drop_outside_is_not_valid() -> void:
	var c := on_dock("bar")
	check(
		not run.can_place(c.id, Vector2i(5, 0), 0),
		"a cell outside the hold is not valid (SPEC Section 8.3)"
	)
	eq(
		run.place_cargo(c.id, Vector2i(5, 0), 0),
		Run.NO_FIT_TEXT,
		"the drop fails (SPEC Section 8.3)"
	)
	check(not c.in_hold, "the cargo goes back to its last place (SPEC Section 8.3)")


func test_drop_on_other_cargo_is_not_valid() -> void:
	put("box", 1, 0)
	var c := on_dock("bar")
	eq(
		run.place_cargo(c.id, Vector2i(0, 0), 0),
		Run.NO_FIT_TEXT,
		"a cell with a different cargo is not valid (SPEC Section 8.3)"
	)


func test_move_onto_own_cells() -> void:
	var c := put("bar", 0, 0)
	eq(
		run.place_cargo(c.id, Vector2i(1, 0), 0),
		"",
		"a cargo can move onto its own old cells (SPEC Section 8.2)"
	)


func test_rotate_in_place() -> void:
	var c := put("bar", 0, 0)
	eq(run.rotate_cargo(c.id), "", "a rotation in place that fits works (SPEC Section 8.2)")
	eq(c.rot, 1, "the cargo turns (SPEC Section 8.2)")
	eq(c.pos, Vector2i(0, 0), "a rotation that fits does not move the cargo (SPEC Section 8.2)")


func test_rotate_kicks() -> void:
	# The bar at (2,5) is on the bottom row. Upright at (2,5), its second cell is outside.
	# Left (1,5) and right (3,5) are outside too. Up (2,4) fits.
	var d := put("bar", 2, 5)
	eq(run.rotate_cargo(d.id), "", "a rotation that does not fit moves 1 cell (SPEC Section 8.2)")
	eq(
		[d.rot, d.pos],
		[1, Vector2i(2, 4)],
		"the cargo goes to the first place that fits (SPEC Section 8.2)"
	)


func test_rotate_kick_order() -> void:
	# The bar at (4,0) turns upright: (4,0) (4,1). The box at (4,1) blocks it.
	# Left (3,0) and right (5,0) both fit. Left comes first.
	var bar := put("bar", 4, 0)
	put("box", 4, 1)
	eq(run.rotate_cargo(bar.id), "", "the rotation moves the cargo (SPEC Section 8.2)")
	eq(bar.pos, Vector2i(3, 0), "left comes before right (SPEC Section 8.2)")


func test_rotate_kick_fails() -> void:
	# The bar at (0,5) turns upright and its second cell is outside. Up (0,4) and
	# up-right (1,4) have boxes. Each other place is outside the hold.
	var bar := put("bar", 0, 5)
	put("box", 0, 4)
	put("box", 1, 4)
	eq(
		run.rotate_cargo(bar.id),
		Run.NO_FIT_TEXT,
		"no place fits: the rotation fails (SPEC Section 8.2)"
	)
	eq(
		[bar.rot, bar.pos],
		[0, Vector2i(0, 5)],
		"a rotation that fails changes nothing (SPEC Section 8.2)"
	)


func test_scrap_stays_in_the_hold() -> void:
	var c := put("box", 0, 0)
	c.kind = Defs.KIND_SCRAP
	eq(
		run.dock_cargo(c.id),
		Run.SCRAP_TO_DOCK_TEXT,
		"scrap cannot go on the dock (SPEC Section 6.4)"
	)
	eq(
		run.place_cargo(c.id, Vector2i(3, 3), 0),
		"",
		"scrap can move inside the hold (SPEC Section 6.4)"
	)


func test_moves_only_at_a_station() -> void:
	var c := put("box", 0, 0)
	run.phase = Defs.PHASE_ARRIVAL
	eq(
		run.place_cargo(c.id, Vector2i(1, 1), 0),
		Run.NOT_AT_STATION_TEXT,
		"the player moves cargo only at a station (SPEC Section 8.2)"
	)


func test_clamp_on_hold_cargo() -> void:
	var c := put("box", 0, 0)
	eq(run.clamp_cargo(c.id), "", "a clamp goes on a cargo in the hold (SPEC Section 13)")
	eq(run.free_clamps(), 0, "the clamp is used (SPEC Section 13)")
	eq(
		run.clamp_cargo(put("box", 1, 0).id),
		Run.NO_FREE_CLAMP_TEXT,
		"no clamp goes on when none is free (SPEC Section 13)"
	)


func test_clamp_not_on_dock() -> void:
	eq(
		run.clamp_cargo(on_dock("box").id),
		Run.NOT_IN_HOLD_TEXT,
		"a clamp cannot go on a cargo on the dock (SPEC Section 13)"
	)


func test_one_clamp_per_cargo() -> void:
	run.clamps = 2
	var c := put("box", 0, 0)
	run.clamp_cargo(c.id)
	eq(
		run.clamp_cargo(c.id),
		Run.CLAMPED_TEXT,
		"a cargo can have one clamp at most (SPEC Section 13)"
	)


func test_clamp_moves_with_cargo() -> void:
	var c := put("box", 0, 0)
	run.clamp_cargo(c.id)
	run.place_cargo(c.id, Vector2i(2, 2), 0)
	check(c.clamped, "a clamped cargo can move, and its clamp moves with it (SPEC Section 8.2)")


func test_clamp_comes_back() -> void:
	var c := put("box", 0, 0)
	run.clamp_cargo(c.id)
	run.dock_cargo(c.id)
	eq(run.free_clamps(), 1, "a cargo that goes to the dock gives its clamp back (SPEC Section 13)")
	var d := put("box", 3, 3)
	run.clamp_cargo(d.id)
	eq(run.unclamp_cargo(d.id), "", "a click takes the clamp off (SPEC Section 13)")
	eq(run.free_clamps(), 1, "the clamp is free again (SPEC Section 13)")


func test_clamp_on_scrap() -> void:
	var c := put("box", 0, 0)
	c.kind = Defs.KIND_SCRAP
	eq(run.clamp_cargo(c.id), "", "a clamp can go on scrap (SPEC Section 13)")
