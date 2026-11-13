extends RuleTest
## The view of a contract card: the freight groups, the totals, the mass after
## it is accepted, and the loaded pieces (SPEC Section 20.2).


## Puts one contract with this freight on the board, not accepted, and returns its view.
func _board(freight: Array, pay := 4) -> Dictionary:
	var t := ContractTemplate.from_dict(
		{"id": "k_test", "sectors": [1], "client_name": "T", "freight": freight, "pay": pay}
	)
	run.contracts.clear()
	run.contracts.append(Contract.new(200, t))
	return RunView.view(run)["contracts"][0]


func test_contract_groups() -> void:
	var k := _board(["box", "vase", "box"])
	var groups: Array = k["groups"]
	eq(groups.size(), 2, "the same freight shows one time (SPEC Section 20.2)")
	eq(groups[0]["def_id"], "box", "the groups keep the order of the freight (SPEC Section 20.2)")
	eq(groups[0]["count"], 2, "a group has the number of its pieces (SPEC Section 20.2)")
	eq(groups[1]["count"], 1, "a group of one piece (SPEC Section 20.2)")
	eq(
		groups[1]["traits"],
		["fragile"],
		"a group has the traits of its freight (SPEC Section 20.2)"
	)


func test_contract_totals() -> void:
	var k := _board(["box", "vase", "box"], 4)
	eq(k["pieces"], 3, "a card shows the number of pieces (SPEC Section 20.2)")
	eq(
		k["total_pay"],
		12,
		"the total pay is the pay for each piece times the pieces (SPEC Section 20.2)"
	)
	eq(k["mass"], 2 + 1 + 2, "the mass of the contract (SPEC Section 20.2)")


func test_contract_mass_after() -> void:
	put("heavy", 0, 0)
	on_dock("bar")
	var k := _board(["box", "box"])
	eq(
		k["mass_after"],
		3 + 4 + 4,
		"the mass after: the hold and the dock, plus the contract (SPEC Section 20.2)"
	)
	eq(k["mass_state"], "ok", "a mass at the limit or less is ok (SPEC Section 20.2)")
	run.mass_limit = 10
	k = _board(["box", "box"])
	eq(k["mass_state"], "fee", "a mass above the limit takes a fuel fee (SPEC Section 20.2)")
	run.mass_limit = 8
	k = _board(["box", "box"])
	eq(k["mass_state"], "over", "a mass above the maximum is too heavy (SPEC Section 20.2)")


func test_contract_loaded() -> void:
	var ks := accept(["k_boxes"])
	var k: Dictionary = RunView.view(run)["contracts"][0]
	eq(k["loaded"], 0, "no piece is in the hold yet (SPEC Section 20.2)")
	var id: int = run.dock[0]
	eq(run.place_cargo(id, Vector2i(0, 0), 0), "", "place one piece")
	k = RunView.view(run)["contracts"][0]
	eq(k["loaded"], 1, "Loaded counts the pieces of the contract in the hold (SPEC Section 20.2)")
	eq(k["pieces"], ks[0].template.freight.size(), "of all its pieces (SPEC Section 20.2)")
