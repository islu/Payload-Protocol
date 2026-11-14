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


func test_cryo_line() -> void:
	var left := put("cheese", 0, 2)
	var other := put("cheese", 3, 2)
	check(
		Arrival.spoil_check(run).has(left),
		"with no mod, a Perishable cargo with no Cooler spoils (SPEC Section 12.1)"
	)
	run.mods.append(Defs.MOD_CRYO_LINE)
	var spoil := Arrival.spoil_check(run)
	check(
		not spoil.has(left),
		"in the left column, a Perishable cargo counts as next to a Cooler (SPEC Section 27.2)"
	)
	check(spoil.has(other), "out of the left column, it spoils (SPEC Section 27.2)")


func test_padded_walls() -> void:
	run.mods.append(Defs.MOD_PADDED_WALLS)
	var glass := put("glass", 0, 2)
	var logs := shift([Defs.DIR_LEFT])
	eq(glass.kind, Defs.KIND_FREIGHT, "no cargo takes a wall jolt (SPEC Section 27.2)")
	eq(hits_of(logs[0], glass.id), [], "the log has no wall jolt (SPEC Section 27.2)")


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


func test_array_power() -> void:
	var shield := put("shield", 2, 2)
	check(
		not Shift.power_check(run).has(shield.id),
		"with no mod, a Shield needs a Battery (SPEC Section 12.2)"
	)
	run.mods.append(Defs.MOD_ARRAY_POWER)
	check(
		Shift.power_check(run).has(shield.id),
		"each Shield has power with no Battery (SPEC Section 27.2)"
	)


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
