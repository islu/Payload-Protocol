extends RuleTest
## The arrival report for the cards and the ledger (SPEC Section 20.4).


func test_groups_of_pieces() -> void:
	accept(["k_vases"])
	var first: int = run.dock[0]
	eq(run.place_cargo(first, Vector2i(0, 5), 0), "", "place one vase")
	warp_with([Defs.DIR_LEFT])
	var k: Dictionary = run.last_arrival["contracts"][0]
	var groups: Array = k["groups"]
	eq(groups.size(), 2, "pieces with a different state make two groups (SPEC Section 20.4)")
	eq(groups[0]["def_id"], "vase", "a group has the freight ID for its image (SPEC Section 20.4)")
	eq(groups[0]["state"], Defs.PIECE_DELIVERED, "the first group is delivered")
	eq(groups[0]["count"], 1, "a group has the number of its pieces (SPEC Section 20.4)")
	eq(groups[0]["ids"], [first], "a group has the IDs of its pieces (SPEC Section 20.4)")
	eq(groups[1]["state"], Defs.PIECE_BREACHED, "the second group is breached")


func test_same_state_shares_a_group() -> void:
	accept(["k_boxes"])
	for x in 2:
		eq(run.place_cargo(run.dock[0], Vector2i(x, 5), 0), "", "place a box")
	warp_with([Defs.DIR_LEFT])
	var groups: Array = run.last_arrival["contracts"][0]["groups"]
	eq(groups.size(), 1, "pieces with the same freight and state share a group (SPEC Section 20.4)")
	eq(groups[0]["count"], 2, "the group counts both pieces (SPEC Section 20.4)")


func test_ledger() -> void:
	run.credits = 50
	accept(["k_vases"])
	eq(run.place_cargo(run.dock[0], Vector2i(0, 5), 0), "", "place one vase")
	on_dock("foam")
	warp_with([Defs.DIR_LEFT])
	var a := run.last_arrival
	var ledger: Dictionary = a["ledger"]
	eq(ledger["deliveries"], 8, "the ledger has the pay of the deliveries (SPEC Section 20.4)")
	eq(ledger["bonuses"], 0, "the ledger has the bonuses (SPEC Section 20.4)")
	eq(ledger["breaches"], 5, "the ledger has the breach fees (SPEC Section 20.4)")
	eq(ledger["sold"], 3, "the ledger has the kit sold from the dock (SPEC Section 20.4)")
	eq(ledger["fuel_fee"], 0, "the ledger has the fuel fee (SPEC Section 20.4)")
	eq(a["credits_before"], 50, "the report has the credits before the warp (SPEC Section 20.4)")
	eq(
		a["credits_after"],
		run.credits,
		"the report has the credits after the arrival (SPEC Section 20.4)"
	)
	eq(
		ledger["net"],
		a["credits_after"] - a["credits_before"],
		"the net is the credits after minus the credits before (SPEC Section 20.4)"
	)
	eq(ledger["net"], 8 - 5 + 3, "the net adds up the lines of the ledger (SPEC Section 20.4)")
