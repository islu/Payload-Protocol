extends RuleTest
## Events and the mod choice (SPEC Sections 26 and 27.1).


## Opens the station of a jump of the leg now.
func _open(jump: int) -> void:
	run.jump = jump
	run._open_station()


func test_first_station_has_no_event() -> void:
	eq(run.phase, Defs.PHASE_STATION, "the first station of a leg has no event (SPEC Section 26.1)")


func test_second_station_has_an_event() -> void:
	_open(2)
	eq(run.phase, Defs.PHASE_EVENT, "the second station of a leg has an event (SPEC Section 26.1)")
	check(run.event != null, "the run has the event of the station (SPEC Section 26.1)")


func test_third_station_has_a_chance() -> void:
	var with := 0
	for s in 40:
		var r := Run.new(Fixture.catalog(), s)
		r.jump = 3
		r._open_station()
		if r.phase == Defs.PHASE_EVENT:
			with += 1
	check(
		with > 5 and with < 35,
		"the third station has an event about one time in two, %d of 40 (SPEC Section 26.1)" % with
	)


func test_no_event_two_times() -> void:
	_open(2)
	var first: String = run.event.id
	eq(run.choose_event(2 if first == "e_one" else 0), "", "select a choice")
	run.leg = 2
	_open(2)
	check(run.event.id != first, "a run does not show the same event two times (SPEC Section 26.1)")
	run.choose_event(0)
	run.leg = 3
	_open(2)
	eq(
		run.phase,
		Defs.PHASE_STATION,
		"with no event left, the station has no event (SPEC Section 26.1)"
	)


func _open_one() -> void:
	for attempt in 2:
		_open(2)
		if run.event.id == "e_one":
			return
		run.choose_event(0)
		run.leg += 1
	failures.append("setup: e_one did not come")


func test_cost_more_than_credits() -> void:
	_open_one()
	run.credits = 4
	eq(
		run.choose_event(0),
		Run.NOT_ENOUGH_TEXT,
		"a choice that costs more than the credits cannot be selected (SPEC Section 26.2)"
	)
	eq(run.phase, Defs.PHASE_EVENT, "the event stays open (SPEC Section 26.2)")
	check(
		run._station_cargo_error(0) == Run.NOT_AT_STATION_TEXT,
		"the player cannot use the station before a choice (SPEC Section 20.8)"
	)


func test_effects() -> void:
	_open_one()
	run.credits = 40
	var clamps := run.clamps
	var payment := run.payment()
	var board := run.contracts.size()
	eq(run.choose_event(0), "", "select the first choice")
	eq(
		run.credits,
		40 - 5 + 10,
		"the choice costs 5, and the credits effect adds 10 (SPEC Section 26.2)"
	)
	eq(run.clamps, clamps + 1, "the clamp effect adds 1 clamp (SPEC Section 26.2)")
	eq(
		run.payment(),
		payment - 15,
		"the payment effect makes the payment smaller (SPEC Section 26.2)"
	)
	var kinds := []
	for id in run.dock:
		kinds.append([run.cargo[id].def.id, run.cargo[id].kind])
	eq(
		kinds,
		[["foam", Defs.KIND_KIT], ["bar", Defs.KIND_SCRAP]],
		"the kit and the scrap go to the dock (SPEC Sections 26.2 and 26.3)"
	)
	eq(
		run.contracts.size(),
		board + 1,
		"the contract effect adds a contract to the board (SPEC Section 26.2)"
	)
	var k: Contract = run.contracts[-1]
	check(
		k.template.id == "k_event" and not k.accepted,
		"the new contract is not accepted (SPEC Section 26.2)"
	)
	eq(run.phase, Defs.PHASE_STATION, "after the choice, the station opens (SPEC Section 20.8)")


func test_payment_cut_ends_with_the_leg() -> void:
	_open_one()
	run.credits = 200
	run.choose_event(0)
	run.phase = Defs.PHASE_PAYMENT
	eq(run.make_payment(), "", "make the payment")
	run.leg = 2
	eq(
		run.payment(),
		run.cat.legs[1]["payment"],
		"the cut is for the leg of the event only (SPEC Section 26.2)"
	)


func test_scrap_on_the_dock_at_the_warp() -> void:
	_open_one()
	run.credits = 40
	run.choose_event(0)
	for id in run.dock.duplicate():
		if run.cargo[id].kind == Defs.KIND_KIT:
			run.place_cargo(id, Vector2i(5, 5), 0)
	run.contracts.clear()
	var before := run.credits
	warp_with([Defs.DIR_LEFT])
	var fee := run.cat.price("scrap_cell") * 2
	eq(
		run.last_arrival["ledger"]["scrap_cleared"],
		fee,
		"the scrap on the dock is cleared at the warp (SPEC Section 26.3)"
	)
	eq(run.credits, before - fee, "the player pays its clear price (SPEC Section 26.3)")


func test_scrap_from_the_dock_into_the_hold() -> void:
	_open_one()
	run.choose_event(0)
	var scrap: int = run.dock[1]
	eq(
		run.place_cargo(scrap, Vector2i(0, 5), 0),
		"",
		"the player can move the scrap into the hold (SPEC Section 26.3)"
	)


func test_mod_effect() -> void:
	_open_one()
	eq(run.choose_event(1), "", "select the mod choice")
	eq(run.phase, Defs.PHASE_MOD, "the mod effect starts a mod choice (SPEC Section 26.2)")
	eq(run.mod_offer.size(), 3, "a mod choice shows 3 mods (SPEC Section 27.1)")
	var picked: String = run.mod_offer[0]
	eq(run.choose_mod(0), "", "select a mod")
	check(run.has_mod(picked), "the player has the mod (SPEC Section 27.1)")
	eq(run.phase, Defs.PHASE_STATION, "after the mod choice, the station opens (SPEC Section 27.1)")


func test_mod_after_payment() -> void:
	run.phase = Defs.PHASE_PAYMENT
	run.credits = 500
	eq(run.make_payment(), "", "make the payment of leg 1")
	eq(
		run.phase,
		Defs.PHASE_MOD,
		"a mod choice comes after the payment of leg 1 (SPEC Section 27.1)"
	)
	run.choose_mod(0)
	eq(run.phase, Defs.PHASE_STATION, "then the station of leg 2 opens")
	run.phase = Defs.PHASE_PAYMENT
	run.make_payment()
	eq(
		run.phase,
		Defs.PHASE_MOD,
		"a mod choice comes after the payment of leg 2 (SPEC Section 27.1)"
	)
	run.choose_mod(0)
	run.phase = Defs.PHASE_PAYMENT
	run.make_payment()
	eq(
		run.phase,
		Defs.PHASE_END,
		"the payment of leg 3 ends the run, with no mod choice (SPEC Section 27.1)"
	)


func test_offers_only_new_mods() -> void:
	for id in ["shock_floor", "cryo_line", "padded_walls", "gravity_damper"]:
		run.mods.append(id)
	run.offer_mods()
	var offer := Array(run.mod_offer)
	offer.sort()
	eq(
		offer,
		["array_power", "insurance"],
		"a mod choice shows only the mods that are left (SPEC Section 27.1)"
	)
	run.mods.append("array_power")
	run.mods.append("insurance")
	run.phase = Defs.PHASE_STATION
	run.offer_mods()
	eq(run.phase, Defs.PHASE_STATION, "with no mod left, no mod choice happens (SPEC Section 27.1)")


func test_event_view() -> void:
	_open_one()
	run.credits = 4
	var e: Dictionary = RunView.view(run)["event"]
	eq(e["choices"].size(), 3, "the view has each choice (SPEC Section 20.8)")
	eq(
		e["choices"][0]["can"],
		false,
		"a choice that costs more than the credits is disabled (SPEC Section 20.8)"
	)
	eq(e["choices"][2]["can"], true, "a choice with no cost can be selected (SPEC Section 20.8)")
	eq(
		e["choices"][0]["effects"].size(),
		6,
		"the view has the text of each effect (SPEC Section 20.8)"
	)


func test_mod_areas_view() -> void:
	run.mods.append(Defs.MOD_SHOCK_FLOOR)
	run.mods.append(Defs.MOD_CRYO_LINE)
	var v := RunView.view(run)
	eq(v["mods"].size(), 2, "the view has each mod of the ship (SPEC Section 20.2)")
	var areas := {}
	for a: Dictionary in v["mod_areas"]:
		areas[a["mod"]] = a["cells"]
	eq(
		areas[Defs.MOD_SHOCK_FLOOR][0],
		{"x": 0, "y": run.rows - 1},
		"Shock Floor shows the bottom row (SPEC Section 27.2)"
	)
	eq(
		areas[Defs.MOD_CRYO_LINE].size(),
		run.rows,
		"Cryo Line shows the left column (SPEC Section 27.2)"
	)


func test_choice_with_no_effect() -> void:
	_open_one()
	run.credits = 40
	run.clamps = 4
	eq(
		run.choose_event(0),
		Run.CLAMPS_MAXED_TEXT,
		"a choice with a cost cannot add a clamp at the maximum (SPEC Section 26.2)"
	)
	eq(
		[run.credits, run.phase],
		[40, Defs.PHASE_EVENT],
		"the choice takes no credits, and the event stays open (SPEC Section 26.2)"
	)
	eq(
		RunView.view(run)["event"]["choices"][0]["can"],
		false,
		"the view disables that choice (SPEC Section 20.8)"
	)
	run.event.choices[1]["cost"] = 8
	for id in Defs.MODS:
		run.mods.append(id)
	eq(
		run.choose_event(1),
		Run.NO_MOD_LEFT_TEXT,
		"a choice with a cost cannot start a mod choice with no mod left (SPEC Section 26.2)"
	)
	eq(run.credits, 40, "the mod choice takes no credits (SPEC Section 26.2)")
