extends RuleTest
## The rules of the mods (SPEC Section 27.2).


func test_shock_floor() -> void:
	run.mods.append(Defs.MOD_SHOCK_FLOOR)
	var low := put("vase", 2, 5)
	var high := put("vase", 2, 0)
	shift([Defs.DIR_LEFT])
	eq(low.kind, Defs.KIND_FREIGHT, "in the bottom row, a hit of force 2 is 1 (SPEC Section 27.2)")
	eq(
		high.kind,
		Defs.KIND_SCRAP,
		"out of the bottom row, the force does not change (SPEC Section 27.2)"
	)


func test_shock_floor_wall_jolt() -> void:
	run.mods.append(Defs.MOD_SHOCK_FLOOR)
	var glass := put("glass", 0, 5)
	shift([Defs.DIR_LEFT])
	eq(
		glass.kind,
		Defs.KIND_FREIGHT,
		"the wall jolt in the bottom row is 1 less too (SPEC Section 27.2)"
	)


func test_gravity_damper() -> void:
	run.mods.append(Defs.MOD_GRAVITY_DAMPER)
	var heavy := put("heavy", 1, 2)
	var logs := shift([Defs.DIR_LEFT])
	eq(
		hits_of(logs[0], heavy.id)[0]["force"],
		2,
		"a heavy cargo hits with a weight value of 2 (SPEC Section 27.2)"
	)
	eq(run.cargo_mass(heavy), 3, "its mass does not change (SPEC Section 27.2)")


func test_insurance() -> void:
	run.mods.append(Defs.MOD_INSURANCE)
	accept(["k_vases"])
	eq(run.place_cargo(run.dock[0], Vector2i(2, 0), 0), "", "place one vase")
	var before := run.credits
	warp_with([Defs.DIR_LEFT])
	var a := run.last_arrival
	eq(a["ledger"]["insurance"], 4, "a scrap piece pays half of its pay of 8 (SPEC Section 27.2)")
	eq(
		run.credits,
		before + 4 - run.cat.price("breach_fee"),
		"a breached piece does not pay insurance (SPEC Section 27.2)"
	)


func test_no_insurance_with_no_mod() -> void:
	accept(["k_vases"])
	run.place_cargo(run.dock[0], Vector2i(2, 0), 0)
	warp_with([Defs.DIR_LEFT])
	eq(
		run.last_arrival["ledger"]["insurance"],
		0,
		"with no mod, the insurance is 0 (SPEC Section 27.2)"
	)


func test_cryo_line() -> void:
	# The Cooler is at (0, 0). The near cheese is 2 cells away on a diagonal (2, 2).
	# The far cheese is 3 cells away (3, 0). The left cheese has no Cooler near it.
	put("cooler", 0, 0)
	var near := put("cheese", 2, 2)
	var far := put("cheese", 3, 0)
	var left := put("cheese", 0, 5)
	check(
		Arrival.spoil_check(run).has(near),
		"with no mod, a Cooler keeps only the cargo next to it fresh (SPEC Section 12.1)"
	)
	run.mods.append(Defs.MOD_CRYO_LINE)
	var spoil := Arrival.spoil_check(run)
	check(
		not spoil.has(near),
		"a Cooler keeps a Perishable cargo within 2 cells fresh (SPEC Section 27.2)"
	)
	check(spoil.has(far), "a cargo 3 cells away spoils (SPEC Section 27.2)")
	check(spoil.has(left), "the left column does not keep a cargo fresh (SPEC Section 27.2)")


func test_padded_walls() -> void:
	run.mods.append(Defs.MOD_PADDED_WALLS)
	var glass := put("glass", 0, 2)
	var bomb := put("bigbomb", 0, 4)
	var logs := shift([Defs.DIR_LEFT])
	eq(
		hits_of(logs[0], glass.id)[0]["force"],
		1,
		"a standard cargo takes a wall jolt of 2 - 1 (SPEC Section 27.2)"
	)
	eq(
		[glass.kind, bomb.kind],
		[Defs.KIND_FREIGHT, Defs.KIND_FREIGHT],
		"the jolt is under the break limits: Fragile 1 < 2, Volatile 2 < 3 (SPEC Section 27.2)"
	)


func test_padded_walls_light() -> void:
	run.mods.append(Defs.MOD_PADDED_WALLS)
	var vase := put("vase", 0, 2)
	var logs := shift([Defs.DIR_LEFT])
	eq(hits_of(logs[0], vase.id)[0]["force"], 0, "the wall jolt is 0 at least (SPEC Section 27.2)")


func test_array_power() -> void:
	# The Battery is at (0, 0). The near Shield is 2 cells away on a diagonal (2, 2).
	# The far Shield is 3 cells away (3, 0). The lone Shield has no Battery near it.
	put("battery", 0, 0)
	var near := put("shield", 2, 2)
	var far := put("shield", 3, 0)
	var lone := put("shield", 5, 5)
	check(
		not Shift.power_check(run).has(near.id),
		"with no mod, a Battery powers only the Shields next to it (SPEC Section 12.2)"
	)
	run.mods.append(Defs.MOD_ARRAY_POWER)
	var powered := Shift.power_check(run)
	check(powered.has(near.id), "a Battery powers each Shield within 2 cells (SPEC Section 27.2)")
	check(not powered.has(far.id), "a Shield 3 cells away has no power (SPEC Section 27.2)")
	check(not powered.has(lone.id), "a Shield with no Battery has no power (SPEC Section 27.2)")


## The rules read the values of the mods from the data (SPEC Section 27.2).
func test_mod_values_come_from_data() -> void:
	run.cat.mods[Defs.MOD_PADDED_WALLS]["values"]["less"] = 2
	run.cat.mods[Defs.MOD_ARRAY_POWER]["values"]["range"] = 3
	run.mods.append_array([Defs.MOD_PADDED_WALLS, Defs.MOD_ARRAY_POWER])
	# The Battery is at (0, 0). The Shield is 3 cells away (3, 0). The glass is at the
	# left wall: the jolt of a standard cargo is 2.
	put("battery", 0, 0)
	var far := put("shield", 3, 0)
	var glass := put("glass", 0, 2)
	check(
		Shift.power_check(run).has(far.id),
		"the range of Array Power comes from its data (SPEC Section 27.2)"
	)
	var logs := shift([Defs.DIR_LEFT])
	eq(
		hits_of(logs[0], glass.id)[0]["force"],
		0,
		"the force less of Padded Walls comes from its data: 2 - 2 (SPEC Section 27.2)"
	)
	eq(
		RunView.mods(run, [Defs.MOD_PADDED_WALLS])[0]["text"]["args"],
		{"less": 2},
		"the text of a mod has its values (SPEC Section 27.2)"
	)


func test_blast_doors() -> void:
	run.mods.append(Defs.MOD_BLAST_DOORS)
	var bomb := put("bomb", 2, 1)
	var side := put("box", 1, 1)
	var corner := put("glass", 3, 0)
	Shift.incident(run, {"kind": Defs.INCIDENT_METEOR, "x": 2})
	check(gone(bomb), "the bomb explodes")
	eq(
		side.kind,
		Defs.KIND_SCRAP,
		"with Blast Doors, the cargo at the side of an explosion still breaks (SPEC Section 27.2)"
	)
	eq(
		corner.kind,
		Defs.KIND_FREIGHT,
		"with Blast Doors, the blast area has no diagonal cells (SPEC Sections 11.2 and 27.2)"
	)


func test_blast_area_with_and_without_blast_doors() -> void:
	var bomb := put("bomb", 2, 2)
	eq(
		Shift.blast_area(run, bomb).size(),
		8,
		"the blast area has diagonal cells (SPEC Section 11.2)"
	)
	run.mods.append(Defs.MOD_BLAST_DOORS)
	eq(
		Shift.blast_area(run, bomb).size(),
		4,
		"with Blast Doors, the blast area has 4 cells around 1 cell (SPEC Section 27.2)"
	)


func test_sealed_wiring() -> void:
	run.mods.append(Defs.MOD_SEALED_WIRING)
	# The tank slides 1 cell down to (2,5): force 2. The chip at (3,5) is next to it.
	var tank := put("tank", 2, 4)
	var chip := put("chip", 3, 5)
	shift([Defs.DIR_DOWN])
	eq(tank.kind, Defs.KIND_SCRAP, "the tank still leaks (SPEC Section 11.3)")
	eq(
		chip.kind,
		Defs.KIND_FREIGHT,
		"with Sealed Wiring, a leak does not short an Electronic cargo (SPEC Section 27.2)"
	)


func test_sealed_wiring_ion_pulse() -> void:
	run.mods.append(Defs.MOD_SEALED_WIRING)
	var chip := put("chip", 3, 2)
	Shift.incident(run, {"kind": Defs.INCIDENT_ION_PULSE, "y": 2})
	eq(
		chip.kind,
		Defs.KIND_SCRAP,
		"with Sealed Wiring, an Ion Pulse still shorts an Electronic cargo (SPEC Section 27.2)"
	)


## A scrap of the bar (2 cells) in the hold.
func _scrap_bar() -> Cargo:
	var c := put("bar", 0, 5)
	c.kind = Defs.KIND_SCRAP
	return c


func test_salvage_arm_clear() -> void:
	run.mods.append(Defs.MOD_SALVAGE_ARM)
	var c := _scrap_bar()
	run.credits = 0
	eq(run.clear_price(c), -2, "the clear of 2 cells pays 2 (SPEC Section 27.2)")
	eq(run.clear_scrap(c.id), "", "with Salvage Arm, a clear needs no credits (SPEC Section 17.4)")
	eq(run.credits, 2, "with Salvage Arm, a clear pays 1 credit for each cell (SPEC Section 17.4)")


func test_salvage_arm_clear_in_debt() -> void:
	run.mods.append(Defs.MOD_SALVAGE_ARM)
	var c := _scrap_bar()
	run.credits = -5
	eq(
		run.clear_scrap(c.id),
		"",
		"with Salvage Arm, a clear costs nothing, also in debt (SPEC Section 17.4)"
	)
	eq(run.credits, -3, "the clear pays 2")


func test_salvage_arm_dock_at_the_warp() -> void:
	run.mods.append(Defs.MOD_SALVAGE_ARM)
	var c := run.new_cargo(run.cat.cargo["bar"])
	c.kind = Defs.KIND_SCRAP
	run.contracts.clear()
	var before := run.credits
	warp_with([Defs.DIR_LEFT])
	var ledger: Dictionary = run.last_arrival["ledger"]
	eq(
		ledger["scrap_cleared"],
		0,
		"with Salvage Arm, the dock clear costs nothing (SPEC Section 17.4)"
	)
	eq(
		ledger["salvage"],
		2,
		"with Salvage Arm, the clear of scrap on the dock at the warp pays (SPEC Section 17.4)"
	)
	eq(run.credits, before + 2, "the credits get the pay of the clear (SPEC Section 17.4)")


func test_trade_license() -> void:
	run.mods.append(Defs.MOD_TRADE_LICENSE)
	run.shop = [{"def": run.cat.cargo["foam"], "bought": false}]
	run.credits = 20
	eq(
		RunView.view(run)["shop"]["offers"][0]["price"],
		4,
		"the shop shows 6 - 2 (SPEC Section 27.2)"
	)
	eq(run.buy_kit(0), "", "buy the foam")
	eq(run.credits, 16, "with Trade License, a kit costs 2 credits less (SPEC Section 27.2)")
	var foam: Cargo = run.cargo[run.dock[0]]
	eq(
		run.sell_price(foam.def),
		2,
		"with Trade License, the sell price is half of the lower price (SPEC Section 17.3)"
	)


func test_trade_license_least_price() -> void:
	run.mods.append(Defs.MOD_TRADE_LICENSE)
	run.cat.cargo["foam"].price = 2
	run.shop = [{"def": run.cat.cargo["foam"], "bought": false}]
	run.credits = 20
	run.buy_kit(0)
	eq(run.credits, 19, "with Trade License, a kit costs 1 credit at least (SPEC Section 27.2)")


func test_trade_license_reroll() -> void:
	var price := run.reroll_price()
	run.mods.append(Defs.MOD_TRADE_LICENSE)
	eq(run.reroll_price(), price, "Trade License does not change Reroll (SPEC Section 27.2)")


func test_new_mod_values_come_from_data() -> void:
	run.cat.mods[Defs.MOD_SALVAGE_ARM]["values"]["pay"] = 3
	run.cat.mods[Defs.MOD_TRADE_LICENSE]["values"]["less"] = 4
	run.mods.append_array([Defs.MOD_SALVAGE_ARM, Defs.MOD_TRADE_LICENSE])
	eq(
		run.clear_price(_scrap_bar()),
		-6,
		"the pay of Salvage Arm comes from its data (SPEC Section 27.2)"
	)
	eq(
		run.kit_price(run.cat.cargo["foam"]),
		2,
		"the less of Trade License comes from its data (SPEC Section 27.2)"
	)
