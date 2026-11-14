extends RuleTest
## Special contracts: VIP and long (SPEC Section 30).


func test_vip_penalty() -> void:
	accept(["k_vip"])
	eq(run.place_cargo(run.dock[0], Vector2i(2, 0), 0), "", "place a vase that breaks")
	eq(run.place_cargo(run.dock[0], Vector2i(0, 3), 0), "", "place a vase that stays intact")
	var before := run.credits
	warp_with([Defs.DIR_LEFT])
	var k: Dictionary = run.last_arrival["contracts"][0]
	eq(
		k["penalty"],
		6,
		"a VIP contract with a piece that is not delivered pays its penalty (SPEC Section 30.1)"
	)
	eq(
		run.last_arrival["ledger"]["penalties"],
		6,
		"the ledger has the penalties (SPEC Section 20.4)"
	)
	eq(run.credits, before + 8 - 6, "the penalty comes off the credits (SPEC Section 30.1)")


func test_vip_no_penalty() -> void:
	accept(["k_vip"])
	eq(run.place_cargo(run.dock[0], Vector2i(0, 0), 0), "", "place a vase")
	eq(run.place_cargo(run.dock[0], Vector2i(0, 3), 0), "", "place a vase")
	warp_with([Defs.DIR_LEFT])
	eq(
		run.last_arrival["contracts"][0]["penalty"],
		0,
		"with each piece delivered, there is no penalty (SPEC Section 30.1)"
	)


func test_vip_breach_penalty() -> void:
	accept(["k_vip"])
	eq(run.place_cargo(run.dock[0], Vector2i(0, 0), 0), "", "place one vase")
	warp_with([Defs.DIR_LEFT])
	var k: Dictionary = run.last_arrival["contracts"][0]
	eq(
		[k["breach"], k["penalty"]],
		[5, 6],
		"a breached piece pays the breach fee and the penalty (SPEC Section 30.1)"
	)


func _long_to_next_station() -> Contract:
	var k: Contract = accept(["k_long"])[0]
	eq(run.place_cargo(run.dock[0], Vector2i(0, 5), 0), "", "place the freight")
	warp_with([Defs.DIR_LEFT])
	return k


func test_long_stays() -> void:
	var before := run.credits
	var k := _long_to_next_station()
	var id: int = k.cargo[0]
	check(
		run.cargo.has(id) and run.cargo[id].in_hold,
		"the freight of a long contract stays in the hold (SPEC Section 30.2)"
	)
	eq(run.credits, before, "it does not pay at the first arrival (SPEC Section 30.2)")
	eq(run.continue_run(), "", "continue")
	if run.phase == Defs.PHASE_EVENT:
		run.choose_event(run.event.choices.size() - 1)
	check(
		k in run.contracts and k.accepted,
		"the contract stays accepted at the next station (SPEC Section 30.2)"
	)
	eq(
		RunView.view(run)["contracts"][0]["jumps_left"],
		1,
		"the station shows the jumps that are left (SPEC Section 30.2)"
	)
	eq(
		run.cancel_contract(run.contracts.find(k)),
		Run.CARRIED_TEXT,
		"the player cannot cancel it on its way (SPEC Section 30.2)"
	)
	eq(
		run.place_cargo(id, Vector2i(3, 3), 0),
		"",
		"the player can move its freight (SPEC Section 30.2)"
	)
	var credits := run.credits
	run.hazard = PackedStringArray([Defs.DIR_DOWN])
	run.incident = {}
	eq(run.warp(), "", "warp again")
	check(not run.cargo.has(id), "at the last jump, the freight is delivered (SPEC Section 30.2)")
	eq(run.credits, credits + 9, "and it pays (SPEC Section 30.2)")


func test_long_on_dock_is_breached() -> void:
	var k := _long_to_next_station()
	run.continue_run()
	if run.phase == Defs.PHASE_EVENT:
		run.choose_event(run.event.choices.size() - 1)
	eq(run.dock_cargo(k.cargo[0]), "", "move the freight to the dock")
	run.hazard = PackedStringArray([Defs.DIR_DOWN])
	run.incident = {}
	eq(run.warp(), "", "warp")
	var res: Dictionary = run.last_arrival["contracts"][0]
	eq(
		res["breach"],
		run.cat.price("breach_fee"),
		"freight of a long contract on the dock at the warp is breached (SPEC Section 30.2)"
	)


## Returns the template IDs that the station of a jump offers, over many seeds. The
## long contract is in each leg, so that only the jumps left decide.
func _offers_at(leg: int, jump: int) -> Dictionary:
	var d := Fixture.data()
	d["contracts"]["k_long"]["legs"] = [1, 2, 3]
	var cat := Catalog.from_data(d)
	var seen := {}
	for s in 30:
		var r := Run.new(cat, s)
		r.leg = leg
		r.jump = jump
		r._offer_contracts()
		for k in r.contracts:
			seen[k.template.id] = true
	return seen


func test_no_long_contract_at_the_last_jump() -> void:
	check(
		_offers_at(3, 2).has("k_long"),
		"the board offers a long contract with 2 jumps left (SPEC Section 30.2)"
	)
	check(
		not _offers_at(3, 3).has("k_long"),
		"the board does not offer a long contract at the last jump of the run (SPEC Section 30.2)"
	)
