extends RuleTest
## The stasis bay (SPEC Section 31). The fixture sells it at 20 (2×2), then 30 (2×3).
## Only kit and scrap go in it: the tests use kit, or freight that is scrap.


## Buys the stasis bay of 2×2.
func _bay() -> void:
	run.credits = 100
	eq(run.buy_shock_bay(), "", "buy the stasis bay")


## Puts a new cargo in the stasis bay at a place.
func _put_bay(def_id: String, x: int, y: int) -> Cargo:
	var c := run.new_cargo(run.cat.cargo[def_id])
	eq(run.place_cargo(c.id, Vector2i(x, y), 0, true), "", "place %s in the stasis bay" % def_id)
	check(c.in_bay and not c.in_hold, "%s is in the stasis bay, not in the hold" % def_id)
	return c


## Returns a new scrap of a cargo on the dock.
func _scrap(def_id: String) -> Cargo:
	var c := on_dock(def_id)
	c.kind = Defs.KIND_SCRAP
	return c


func test_buy() -> void:
	eq(run.bay_size, Vector2i.ZERO, "a run starts with no stasis bay (SPEC Section 31.1)")
	run.credits = 100
	eq(run.buy_shock_bay(), "", "buy the stasis bay")
	eq(
		[run.bay_size, run.credits],
		[Vector2i(2, 2), 80],
		"the first purchase gives 2×2 for 20 (SPEC Section 17.2)"
	)
	eq(run.buy_shock_bay(), "", "buy the second size")
	eq(
		[run.bay_size, run.credits],
		[Vector2i(2, 3), 50],
		"the second purchase gives 2×3 for 30 (SPEC Section 17.2)"
	)
	eq(run.buy_shock_bay(), Run.BAY_MAXED_TEXT, "2×3 is the maximum (SPEC Section 31.1)")


func test_place() -> void:
	var foam := on_dock("foam")
	eq(
		run.place_cargo(foam.id, Vector2i(0, 0), 0, true),
		Run.NO_FIT_TEXT,
		"with no stasis bay, nothing goes in it (SPEC Section 31.1)"
	)
	_bay()
	var cooler := _put_bay("cooler", 1, 1)
	check(
		cooler.in_bay and not cooler.in_hold and not cooler.id in run.dock,
		"a kit goes from the dock into the stasis bay (SPEC Section 31.1)"
	)
	var bar := _scrap("bar")
	eq(
		run.place_cargo(bar.id, Vector2i(1, 0), 0, true),
		Run.NO_FIT_TEXT,
		"a cell outside the stasis bay is not valid (SPEC Section 8.3)"
	)
	eq(
		run.place_cargo(bar.id, Vector2i(0, 0), 0, true),
		"",
		"a scrap goes in the stasis bay (SPEC Section 31.1)"
	)
	eq(
		run.place_cargo(foam.id, Vector2i(1, 1), 0, true),
		Run.NO_FIT_TEXT,
		"a cell with a different cargo is not valid (SPEC Section 8.3)"
	)
	eq(
		run.place_cargo(foam.id, Vector2i(1, 1), 0),
		"",
		"the hold has its own cells: (1, 1) of the hold is free (SPEC Section 31.1)"
	)
	eq(run.dock_cargo(cooler.id), "", "a cargo goes from the stasis bay to the dock")
	check(
		not cooler.in_bay and cooler.id in run.dock, "the cargo is on the dock (SPEC Section 8.2)"
	)


func test_no_freight() -> void:
	_bay()
	var box := on_dock("box")
	check(
		not run.can_place(box.id, Vector2i(0, 0), 0, true),
		"a drop of freight on the stasis bay is not valid (SPEC Section 31.1)"
	)
	eq(
		run.place_cargo(box.id, Vector2i(0, 0), 0, true),
		Run.BAY_FREIGHT_TEXT,
		"freight cannot go in the stasis bay (SPEC Section 31.1)"
	)
	check(box.id in run.dock, "the freight stays on the dock")
	var p := RunView.drop_preview(run, box.id, Vector2i(0, 0), 0, true)
	eq(
		[p["ok"], p["cells"][0]["free"], p["nearest"]],
		[false, false, null],
		"the drop preview shows no free cell for freight in the stasis bay (SPEC Section 8.3)"
	)
	eq(run.place_cargo(box.id, Vector2i(0, 0), 0), "", "the freight goes in the hold")
	eq(
		run.place_cargo(box.id, Vector2i(0, 0), 0, true),
		Run.BAY_FREIGHT_TEXT,
		"freight in the hold cannot go in the stasis bay (SPEC Section 31.1)"
	)


func test_no_shift() -> void:
	_bay()
	var cooler := _put_bay("cooler", 0, 0)
	var anchor := _put_bay("anchor", 1, 1)
	var logs := shift([Defs.DIR_RIGHT, Defs.DIR_DOWN])
	eq(
		[cooler.pos, anchor.pos],
		[Vector2i(0, 0), Vector2i(1, 1)],
		"cargo in the stasis bay does not slide (SPEC Section 31.1)"
	)
	eq(
		[hits_of(logs[0], cooler.id), hits_of(logs[1], anchor.id)],
		[[], []],
		"cargo in the stasis bay takes no hits and no wall jolts (SPEC Section 31.1)"
	)


func test_blast_stays_in_hold() -> void:
	# The heavy bomb slides 1 cell to the left wall of the hold: force 3, and it
	# explodes at (0, 0) of the hold. The battery is at (0, 0) of the stasis bay.
	_bay()
	var battery := _put_bay("battery", 0, 0)
	var bomb := put("bigbomb", 1, 0)
	shift([Defs.DIR_LEFT])
	check(gone(bomb), "the bomb explodes")
	eq(battery.kind, Defs.KIND_KIT, "the blast does not reach the stasis bay (SPEC Section 31.1)")


func test_no_incident() -> void:
	_bay()
	var battery := _put_bay("battery", 0, 0)
	Shift.incident(run, {"kind": Defs.INCIDENT_ION_PULSE, "y": 0})
	var out := Shift.incident(run, {"kind": Defs.INCIDENT_HULL_BREACH, "x": 0, "y": 0})
	eq(battery.kind, Defs.KIND_KIT, "an incident does not reach the stasis bay (SPEC Section 31.1)")
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
	var box := _scrap("box")
	eq(run.place_cargo(box.id, Vector2i(0, 0), 0, true), "", "place the scrap in the stasis bay")
	_put_bay("battery", 1, 0)
	var heavy := put("heavy", 3, 3)
	eq(
		run.hold_mass(),
		3,
		"cargo in the stasis bay does not count for the hold mass (SPEC Section 31.1)"
	)
	eq(
		[run.cargo_mass(box), run.cargo_mass(heavy)],
		[0, 3],
		"cargo in the stasis bay has no mass (SPEC Sections 25 and 31.1)"
	)


func test_links_stay_inside() -> void:
	# The Battery at (0, 0) of the hold and the Shield at (1, 0) of the stasis bay have
	# cells next to each other, but they are in different areas.
	_bay()
	put("battery", 0, 0)
	_put_bay("shield", 1, 0)
	eq(
		RunView.links(run).size(),
		0,
		"a Battery in the hold has no link to a Shield in the stasis bay (SPEC Section 31.1)"
	)
	_put_bay("battery", 1, 1)
	eq(RunView.links(run).size(), 1, "the view has the link in the stasis bay (SPEC Section 12.3)")


func test_no_clamp() -> void:
	_bay()
	var cooler := _put_bay("cooler", 0, 0)
	eq(
		run.clamp_cargo(cooler.id),
		Run.BAY_CLAMP_TEXT,
		"a cargo in the stasis bay cannot have a clamp (SPEC Section 31.1)"
	)


func test_sensor() -> void:
	_bay()
	run.hazard = PackedStringArray([Defs.DIR_LEFT, Defs.DIR_UP])
	run.fork_options = PackedStringArray([Defs.DIR_UP, Defs.DIR_RIGHT])
	_put_bay("sensor", 0, 0)
	eq(
		RunView.hazard(run)[1]["known"],
		Defs.DIR_UP,
		"a Sensor in the stasis bay shows the fork step (SPEC Section 18.1)"
	)


func test_load_all_skips_bay() -> void:
	_bay()
	for y in run.rows:
		for x in run.columns:
			put("light", x, y)
	var foam := on_dock("foam")
	eq(run.load_all(), "", "load all")
	check(foam.id in run.dock, "Load all does not use the stasis bay (SPEC Section 8.1)")


func test_view() -> void:
	var v := RunView.view(run)
	eq(v["shock_bay"], {}, "the view has no stasis bay before the purchase (SPEC Section 31.2)")
	eq(
		[v["shop"]["bay"]["now"], v["shop"]["bay"]["after"], v["shop"]["bay"]["price"]],
		[{}, {"columns": 2, "rows": 2}, 20],
		"the service shows none → 2×2 and its price (SPEC Section 20.2)"
	)
	check(
		not v["shop"].has("column_after"), "the hold upgrade is not a service (SPEC Section 17.2)"
	)
	_bay()
	var cooler := _put_bay("cooler", 0, 0)
	v = RunView.view(run)
	eq(v["shock_bay"], {"columns": 2, "rows": 2}, "the view has the stasis bay (SPEC Section 31.2)")
	var cv: Dictionary = {}
	for c: Dictionary in v["cargo"]:
		if c["id"] == cooler.id:
			cv = c
	check(cv["in_bay"] and not cv["in_hold"], "the cargo view says the area (SPEC Section 31.2)")
	eq(v["shop"]["bay"]["after"], {"columns": 2, "rows": 3}, "the next size is 2×3")


func test_drop_preview_in_bay() -> void:
	_bay()
	var bar := _scrap("bar")
	var p := RunView.drop_preview(run, bar.id, Vector2i(1, 0), 0, true)
	eq(
		p["cells"][1],
		{"cell": Vector2i(2, 0), "free": false},
		"a cell outside the stasis bay is not free (SPEC Sections 8.3 and 31.1)"
	)
	eq(
		p["nearest"],
		Vector2i(0, 0),
		"the ghost shows the nearest place in the stasis bay (SPEC Sections 8.3 and 31.1)"
	)
