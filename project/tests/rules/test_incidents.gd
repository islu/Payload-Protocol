extends RuleTest
## The incidents of the route (SPEC Section 29).


func _station(leg: int, run_seed: int, cargo: Array = []) -> Run:
	var r := Run.new(Fixture.catalog(), run_seed)
	for spot: Array in cargo:
		var c := r.new_cargo(r.cat.cargo[spot[0]])
		r.place_cargo(c.id, Vector2i(spot[1], spot[2]), 0)
	r.leg = leg
	r.jump = 1
	r._open_station()
	return r


func test_leg_1_has_no_incident() -> void:
	for s in 10:
		check(
			_station(1, s).incident.is_empty(),
			"leg 1 has no incident, seed %d (SPEC Section 29.1)" % s
		)


func test_leg_3_has_an_incident_at_each_jump() -> void:
	for s in 10:
		var i := _station(3, s).incident
		check(
			i.get("kind", "") in Defs.INCIDENTS,
			"leg 3 has an incident at each jump, seed %d (SPEC Section 29.1)" % s
		)


func test_leg_2_has_a_chance() -> void:
	var with := 0
	for s in 40:
		if not _station(2, s).incident.is_empty():
			with += 1
	check(
		with > 5 and with < 35,
		"leg 2 has an incident about one time in two, %d of 40 (SPEC Section 29.1)" % with
	)


func test_place_has_a_cargo() -> void:
	for s in 20:
		var r := _station(3, s, [["box", 4, 2]])
		var i := r.incident
		match i["kind"]:
			Defs.INCIDENT_METEOR:
				eq(
					i["x"],
					4,
					"a meteor selects a column with a cargo, seed %d (SPEC Section 29.1)" % s
				)
			Defs.INCIDENT_ION_PULSE:
				eq(
					i["y"],
					2,
					"an ion pulse selects a row with a cargo, seed %d (SPEC Section 29.1)" % s
				)
			Defs.INCIDENT_HULL_BREACH:
				eq(
					[i["x"], i["y"]],
					[4, 2],
					"a hull breach selects a cell with a cargo, seed %d (SPEC Section 29.1)" % s
				)


func test_meteor_hits_the_top_cargo() -> void:
	var box := put("box", 2, 1)
	var vase := put("vase", 2, 3)
	var out := Shift.incident(run, {"kind": Defs.INCIDENT_METEOR, "x": 2})
	eq(out["hits"].size(), 1, "the meteor makes one hit (SPEC Section 29.2)")
	eq(
		out["hits"][0]["cargo"],
		box.id,
		"the meteor hits the cargo with the top cell in the column (SPEC Section 29.2)"
	)
	eq(out["hits"][0]["force"], 3, "the hit has a force of 3 (SPEC Section 29.2)")
	eq(
		[box.kind, vase.kind],
		[Defs.KIND_FREIGHT, Defs.KIND_FREIGHT],
		"a cargo with no trait takes the hit and stays intact (SPEC Section 29.2)"
	)


func test_meteor_breaks_fragile() -> void:
	var vase := put("vase", 2, 3)
	Shift.incident(run, {"kind": Defs.INCIDENT_METEOR, "x": 2})
	eq(vase.kind, Defs.KIND_SCRAP, "the rules of Section 11 apply to the hit (SPEC Section 29.2)")


func test_meteor_explosion_chain() -> void:
	var bomb := put("bomb", 2, 0)
	var box := put("box", 3, 0)
	var out := Shift.incident(run, {"kind": Defs.INCIDENT_METEOR, "x": 2})
	check(gone(bomb), "a Volatile cargo that the meteor hits explodes (SPEC Section 29.2)")
	eq(box.kind, Defs.KIND_SCRAP, "the explosion breaks the cargo around it (SPEC Section 29.2)")
	eq(
		out["reactions"].size(),
		2,
		"the reactions of the incident are in its log (SPEC Section 29.2)"
	)


func test_meteor_empty_column() -> void:
	put("box", 0, 0)
	var out := Shift.incident(run, {"kind": Defs.INCIDENT_METEOR, "x": 3})
	eq(
		[out["hits"], out["reactions"]],
		[[], []],
		"a meteor on an empty column does nothing (SPEC Section 29.2)"
	)


func test_ion_pulse() -> void:
	var hit := put("chip", 1, 2)
	var other_row := put("chip", 1, 3)
	var box := put("box", 2, 2)
	Shift.incident(run, {"kind": Defs.INCIDENT_ION_PULSE, "y": 2})
	eq(
		hit.kind,
		Defs.KIND_SCRAP,
		"an ion pulse shorts each Electronic cargo in its row (SPEC Section 29.2)"
	)
	eq(
		[other_row.kind, box.kind],
		[Defs.KIND_FREIGHT, Defs.KIND_FREIGHT],
		"other cargo stays intact (SPEC Section 29.2)"
	)


func test_ion_pulse_shield() -> void:
	run.mods.append(Defs.MOD_ARRAY_POWER)
	run.charges = {}
	var shield := put("shield", 2, 2)
	run.charges[shield.id] = 1
	var chip := put("chip", 1, 2)
	var out := Shift.incident(run, {"kind": Defs.INCIDENT_ION_PULSE, "y": 2})
	eq(
		chip.kind,
		Defs.KIND_FREIGHT,
		"a Shield can cancel a reaction of an incident (SPEC Section 29.2)"
	)
	eq(out["reactions"][0]["kind"], Defs.REACT_SHIELD, "the log has the shield (SPEC Section 29.2)")


func test_hull_breach_empty_cell() -> void:
	var out := Shift.incident(run, {"kind": Defs.INCIDENT_HULL_BREACH, "x": 3, "y": 4})
	var id: int = out["debris"]
	check(run.cargo.has(id), "a debris appears in an empty cell (SPEC Section 29.2)")
	var d: Cargo = run.cargo[id]
	check(
		d.in_hold and d.pos == Vector2i(3, 4) and d.kind == Defs.KIND_SCRAP,
		"the debris is a scrap of 1 cell in the cell (SPEC Section 29.2)"
	)
	check(not id in run.dock, "the debris is not on the dock")


func test_hull_breach_on_cargo() -> void:
	var box := put("box", 3, 4)
	var count := run.cargo.size()
	var out := Shift.incident(run, {"kind": Defs.INCIDENT_HULL_BREACH, "x": 3, "y": 4})
	eq(box.kind, Defs.KIND_SCRAP, "a cargo in the cell becomes scrap (SPEC Section 29.2)")
	eq([out["debris"], run.cargo.size()], [0, count], "no debris appears (SPEC Section 29.2)")


func test_warp_plays_the_incident_first() -> void:
	accept(["k_vases"])
	eq(run.place_cargo(run.dock[0], Vector2i(2, 2), 0), "", "place a vase")
	eq(run.place_cargo(run.dock[0], Vector2i(4, 0), 0), "", "place a vase at the top wall")
	run.incident = {"kind": Defs.INCIDENT_METEOR, "x": 2}
	warp_with([Defs.DIR_UP])
	var w := run.last_warp
	eq(w["incident"]["hits"].size(), 1, "the warp has the log of the incident (SPEC Section 29.3)")
	eq(w["loss"], 8, "the loss of the warp has the reactions of the incident (SPEC Section 21.5)")


func test_incident_view() -> void:
	run.incident = {"kind": Defs.INCIDENT_ION_PULSE, "y": 3}
	var v := RunView.view(run)
	eq(
		v["incident"]["kind"],
		Defs.INCIDENT_ION_PULSE,
		"the view has the incident of the next jump (SPEC Section 29.3)"
	)
	eq(
		v["incident"]["cells"].size(),
		run.columns,
		"the view has the cells of its place: a row (SPEC Section 29.3)"
	)


func test_incident_picks_the_line() -> void:
	var boom := {"kind": Defs.REACT_EXPLOSION}
	run.last_warp = {"steps": [], "incident": {"reactions": [boom, boom]}}
	eq(
		Arrival._line_event(run, {"contracts": [], "spoiled": []}),
		Defs.LINE_CHAIN,
		"the reactions of an incident select the line of the pilot (SPEC Sections 22 and 29.2)"
	)
