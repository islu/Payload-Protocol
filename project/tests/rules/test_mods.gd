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
