extends RuleTest
## The shock bay (SPEC Section 31). The fixture sells it at 20 (2×2), then 30 (3×2).


## Buys the shock bay of 2×2.
func _bay() -> void:
	run.credits = 100
	eq(run.buy_shock_bay(), "", "buy the shock bay")


## Puts a new cargo in the shock bay at a place.
func _put_bay(def_id: String, x: int, y: int) -> Cargo:
	var c := run.new_cargo(run.cat.cargo[def_id])
	eq(run.place_cargo(c.id, Vector2i(x, y), 0, true), "", "place %s in the shock bay" % def_id)
	check(c.in_bay and not c.in_hold, "%s is in the shock bay, not in the hold" % def_id)
	return c


func test_buy() -> void:
	eq(run.bay_size, Vector2i.ZERO, "a run starts with no shock bay (SPEC Section 31.1)")
	run.credits = 100
	eq(run.buy_shock_bay(), "", "buy the shock bay")
	eq(
		[run.bay_size, run.credits],
		[Vector2i(2, 2), 80],
		"the first purchase gives 2×2 for 20 (SPEC Section 17.2)"
	)
	eq(run.buy_shock_bay(), "", "buy the second size")
	eq(
		[run.bay_size, run.credits],
		[Vector2i(3, 2), 50],
		"the second purchase gives 3×2 for 30 (SPEC Section 17.2)"
	)
	eq(run.buy_shock_bay(), Run.BAY_MAXED_TEXT, "3×2 is the maximum (SPEC Section 31.1)")


func test_place() -> void:
	var box := on_dock("box")
	eq(
		run.place_cargo(box.id, Vector2i(0, 0), 0, true),
		Run.NO_FIT_TEXT,
		"with no shock bay, nothing goes in it (SPEC Section 31.1)"
	)
	_bay()
	var vase := _put_bay("vase", 1, 1)
	check(
		vase.in_bay and not vase.in_hold and not vase.id in run.dock,
		"a cargo goes from the dock into the shock bay (SPEC Section 31.1)"
	)
	var bar := on_dock("bar")
	eq(
		run.place_cargo(bar.id, Vector2i(1, 0), 0, true),
		Run.NO_FIT_TEXT,
		"a cell outside the shock bay is not valid (SPEC Section 8.3)"
	)
	eq(
		run.place_cargo(box.id, Vector2i(1, 1), 0, true),
		Run.NO_FIT_TEXT,
		"a cell with a different cargo is not valid (SPEC Section 8.3)"
	)
	eq(
		run.place_cargo(box.id, Vector2i(1, 1), 0),
		"",
		"the hold has its own cells: (1, 1) of the hold is free (SPEC Section 31.1)"
	)
	eq(run.dock_cargo(vase.id), "", "a cargo goes from the shock bay to the dock")
	check(not vase.in_bay and vase.id in run.dock, "the cargo is on the dock (SPEC Section 8.2)")


func test_no_shift() -> void:
	_bay()
	var glass := _put_bay("glass", 0, 0)
	var vase := _put_bay("vase", 1, 1)
	var logs := shift([Defs.DIR_RIGHT, Defs.DIR_DOWN])
	eq(
		[glass.pos, vase.pos],
		[Vector2i(0, 0), Vector2i(1, 1)],
		"cargo in the shock bay does not slide (SPEC Section 31.1)"
	)
	eq(
		[hits_of(logs[0], glass.id), hits_of(logs[1], vase.id)],
		[[], []],
		"cargo in the shock bay takes no hits and no wall jolts (SPEC Section 31.1)"
	)
	eq([glass.kind, vase.kind], [Defs.KIND_FREIGHT, Defs.KIND_FREIGHT], "both stay intact")


func test_blast_stays_in_hold() -> void:
	# The heavy bomb slides 1 cell to the left wall of the hold: force 3, and it
	# explodes at (0, 0) of the hold. The vase is at (0, 0) of the shock bay.
	_bay()
	var vase := _put_bay("vase", 0, 0)
	var bomb := put("bigbomb", 1, 0)
	shift([Defs.DIR_LEFT])
	check(gone(bomb), "the bomb explodes")
	eq(vase.kind, Defs.KIND_FREIGHT, "the blast does not reach the shock bay (SPEC Section 31.1)")


func test_no_incident() -> void:
	_bay()
	var chip := _put_bay("chip", 0, 0)
	Shift.incident(run, {"kind": Defs.INCIDENT_ION_PULSE, "y": 0})
	var out := Shift.incident(run, {"kind": Defs.INCIDENT_HULL_BREACH, "x": 0, "y": 0})
	eq(chip.kind, Defs.KIND_FREIGHT, "an incident does not reach the shock bay (SPEC Section 31.1)")
	check(
		out["debris"] != 0, "the hull breach is in the hold: a debris appears (SPEC Section 29.2)"
	)
	run.leg = 3
	run.jump = 1
	for s in 10:
		run.rng.seed = s
		var inc := Route.make_incident(run)
		check(
			inc.get("x", 0) < run.columns and inc.get("y", 0) < run.rows,
			"the place of an incident is in the hold, seed %d (SPEC Section 29.1)" % s
		)


func test_mass() -> void:
	_bay()
	_put_bay("box", 0, 0)
	_put_bay("battery", 1, 0)
	put("heavy", 3, 3)
	eq(
		run.hold_mass(),
		2 + 0 + 3,
		"cargo in the shock bay counts for the hold mass; kit is 0 (SPEC Sections 25 and 31.1)"
	)


func test_delivery() -> void:
	_bay()
	accept(["k_boxes"])
	var ids := run.dock.duplicate()
	eq(run.place_cargo(ids[0], Vector2i(0, 0), 0, true), "", "place a box in the shock bay")
	eq(run.place_cargo(ids[1], Vector2i(1, 0), 0, true), "", "place a box in the shock bay")
	check(run.cargo[ids[0]].in_bay, "the box is in the shock bay")
	warp_with([Defs.DIR_LEFT])
	var states := []
	for p: Dictionary in run.last_arrival["contracts"][0]["pieces"]:
		states.append(p["state"])
	eq(
		states,
		[Defs.PIECE_DELIVERED, Defs.PIECE_DELIVERED],
		"freight in the shock bay is delivered (SPEC Section 31.1)"
	)
	check(not run.cargo.has(ids[0]), "the delivered freight leaves the shock bay")


func test_links_stay_inside() -> void:
	# The Cooler at (0, 0) of the hold and the cheese at (1, 0) of the shock bay have
	# cells next to each other, but they are in different areas.
	_bay()
	put("cooler", 0, 0)
	var cheese := _put_bay("cheese", 1, 0)
	check(
		Arrival.spoil_check(run).has(cheese),
		"a Cooler in the hold does not keep a cargo in the shock bay fresh (SPEC Section 31.1)"
	)
	_put_bay("cooler", 1, 1)
	check(
		not Arrival.spoil_check(run).has(cheese),
		"a Cooler in the shock bay keeps the cargo next to it fresh (SPEC Section 31.1)"
	)
	eq(RunView.links(run).size(), 1, "the view has the link in the shock bay (SPEC Section 12.3)")


func test_no_clamp() -> void:
	_bay()
	var box := _put_bay("box", 0, 0)
	eq(
		run.clamp_cargo(box.id),
		Run.BAY_CLAMP_TEXT,
		"a cargo in the shock bay cannot have a clamp (SPEC Section 31.1)"
	)


func test_zone_bonus() -> void:
	_bay()
	var k: Contract = accept(["k_bars"])[0]
	var bar: Cargo = run.cargo[k.cargo[0]]
	eq(run.place_cargo(bar.id, Vector2i(0, 0), 0, true), "", "place the bar in the shock bay")
	check(
		not Arrival.bonus_met(run, k, [bar]),
		"a piece in the shock bay is outside the zone (SPEC Section 31.1)"
	)
	eq(run.place_cargo(bar.id, Vector2i(0, 5), 0), "", "place the bar in the left columns")
	check(
		Arrival.bonus_met(run, k, [bar]), "in the hold, the zone bonus is met (SPEC Section 15.3)"
	)


func test_sensor() -> void:
	_bay()
	run.hazard = PackedStringArray([Defs.DIR_LEFT, Defs.DIR_UP])
	run.fork_options = PackedStringArray([Defs.DIR_UP, Defs.DIR_RIGHT])
	_put_bay("sensor", 0, 0)
	eq(
		RunView.hazard(run)[1]["known"],
		Defs.DIR_UP,
		"a Sensor in the shock bay shows the fork step (SPEC Section 18.1)"
	)


func test_load_all_skips_bay() -> void:
	_bay()
	for y in run.rows:
		for x in run.columns:
			put("light", x, y)
	var box := on_dock("box")
	eq(run.load_all(), "", "load all")
	check(box.id in run.dock, "Load all does not use the shock bay (SPEC Section 8.1)")


func test_view() -> void:
	var v := RunView.view(run)
	eq(v["shock_bay"], {}, "the view has no shock bay before the purchase (SPEC Section 31.2)")
	eq(
		[v["shop"]["bay"]["now"], v["shop"]["bay"]["after"], v["shop"]["bay"]["price"]],
		[{}, {"columns": 2, "rows": 2}, 20],
		"the service shows none → 2×2 and its price (SPEC Section 20.2)"
	)
	check(
		not v["shop"].has("column_after"), "the hold upgrade is not a service (SPEC Section 17.2)"
	)
	_bay()
	var box := _put_bay("box", 0, 0)
	v = RunView.view(run)
	eq(v["shock_bay"], {"columns": 2, "rows": 2}, "the view has the shock bay (SPEC Section 31.2)")
	var cv: Dictionary = {}
	for c: Dictionary in v["cargo"]:
		if c["id"] == box.id:
			cv = c
	check(cv["in_bay"] and not cv["in_hold"], "the cargo view says the area (SPEC Section 31.2)")
	eq(v["shop"]["bay"]["after"], {"columns": 3, "rows": 2}, "the next size is 3×2")
