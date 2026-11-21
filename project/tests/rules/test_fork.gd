extends RuleTest


func _run_at(leg: int, run_seed: int) -> Run:
	var r := Run.new(run.cat, run_seed)
	r.leg = leg
	r.jump = 1
	r._open_station()
	return r


func test_leg_1_has_no_fork() -> void:
	for s in range(1, 30):
		var r := _run_at(1, s)
		check(r.fork_options.is_empty(), "leg 1 has no fork step (SPEC Section 18)")


func test_fork_step_rules() -> void:
	var opposite := {
		Defs.DIR_LEFT: Defs.DIR_RIGHT,
		Defs.DIR_RIGHT: Defs.DIR_LEFT,
		Defs.DIR_UP: Defs.DIR_DOWN,
		Defs.DIR_DOWN: Defs.DIR_UP,
	}
	for s in range(1, 60):
		for leg in [2, 3]:
			var r := _run_at(leg, s)
			var o: PackedStringArray = r.fork_options
			eq(o.size(), 2, "the last step of legs 2 and 3 is a fork step (SPEC Section 18)")
			if o.size() != 2:
				return
			var before: String = r.hazard[r.hazard.size() - 2]
			check(
				not before in o, "a fork step does not repeat the step before it (SPEC Section 18)"
			)
			check(opposite[o[0]] != o[1], "the two directions are not opposite (SPEC Section 18)")
			check(
				opposite[before] in o,
				"one direction is opposite to the step before it (SPEC Section 18)"
			)
			check(
				r.hazard[-1] in o, "the direction that happens is one of the two (SPEC Section 18)"
			)


func test_fork_hidden_in_the_view() -> void:
	var r := _run_at(2, 5)
	var step: Dictionary = RunView.view(r)["hazard"][-1]
	eq(
		step["directions"],
		Array(r.fork_options),
		"the station shows the two directions (SPEC Section 18)"
	)
	eq(step["known"], "", "the station does not show the direction that happens (SPEC Section 18)")


func test_sensor_shows_the_fork() -> void:
	var r := _run_at(2, 5)
	var sensor := r.new_cargo(r.cat.cargo["sensor"])
	r.place_cargo(sensor.id, Vector2i(0, 0), 0)
	eq(
		RunView.view(r)["hazard"][-1]["known"],
		r.hazard[-1],
		"a Sensor in the hold shows the fork (SPEC Section 18.1)"
	)
	r.dock_cargo(sensor.id)
	eq(
		RunView.view(r)["hazard"][-1]["known"],
		"",
		"a Sensor on the dock shows nothing (SPEC Section 18.1)"
	)
	r.place_cargo(sensor.id, Vector2i(0, 0), 0)
	sensor.kind = Defs.KIND_SCRAP
	eq(
		RunView.view(r)["hazard"][-1]["known"],
		"",
		"a scrap Sensor shows nothing (SPEC Section 18.1)"
	)


func test_warp_log_shows_the_fork() -> void:
	var r := _run_at(2, 5)
	r.warp()
	var last: Dictionary = r.last_warp["steps"][-1]
	eq(
		last["options"],
		Array(r.fork_options),
		"the log of the fork step has the two directions (SPEC Section 9)"
	)
	eq(last["direction"], r.hazard[-1], "and the direction that happened (SPEC Section 9)")


func test_offers_have_more_mass_than_the_limit() -> void:
	var cat := DataFiles.catalog()
	for s in range(1, 30):
		for leg in [1, 2, 3]:
			var r := Run.new(cat, s)
			r.leg = leg
			r._offer_contracts()
			var total := 0
			for k in r.contracts:
				for id in k.template.freight:
					total += cat.weight_value(cat.cargo[id].weight) * cat.cargo[id].shape.size()
			eq(r.contracts.size(), 4, "a station offers 4 contracts (SPEC Section 15.1)")
			check(
				total * 100 >= r.mass_limit * 130,
				(
					"the offers have 1.3 times the mass limit or more, seed %d leg %d: %d (content.md)"
					% [s, leg, total]
				)
			)
