extends RuleTest
## The route environments (SPEC Section 28).


func test_leg_1_has_no_environment() -> void:
	eq(run.environment, "", "leg 1 has no environment (SPEC Section 28.1)")


func test_legs_2_and_3_have_different_environments() -> void:
	for s in 20:
		var r := Run.new(Fixture.catalog(), s)
		var seen := []
		for leg in 2:
			r.phase = Defs.PHASE_PAYMENT
			r.credits = 1000
			eq(r.make_payment(), "", "make the payment")
			seen.append(r.environment)
			if r.phase == Defs.PHASE_MOD:
				r.choose_mod(0)
		check(
			seen[0] in Defs.ENVIRONMENTS and seen[1] in Defs.ENVIRONMENTS,
			"legs 2 and 3 each have an environment, seed %d (SPEC Section 28.1)" % s
		)
		check(
			seen[0] != seen[1],
			"the two environments are not the same, seed %d (SPEC Section 28.1)" % s
		)


func test_low_gravity() -> void:
	run.environment = Defs.ENV_LOW_GRAVITY
	var box := put("box", 5, 2)
	var logs := shift([Defs.DIR_LEFT])
	eq(
		box.pos,
		Vector2i(3, 2),
		"in Low Gravity, a cargo slides 2 cells at most (SPEC Section 28.2)"
	)
	eq(
		hits_of(logs[0], box.id),
		[],
		"a cargo that stops at its slide limit with nothing in front makes no hit (SPEC Section 10.2)"
	)


func test_low_gravity_block() -> void:
	run.environment = Defs.ENV_LOW_GRAVITY
	# Column 1: two vases slide up 2 cells together and stop at the limit.
	var front := put("vase", 1, 4)
	var back := put("vase", 1, 5)
	# Column 3: the vase stops at the wall after 1 cell. The box behind it slides 2.
	var held := put("vase", 3, 1)
	var box := put("box", 3, 3)
	var logs := shift([Defs.DIR_UP])
	eq([front.pos, back.pos], [Vector2i(1, 2), Vector2i(1, 3)], "both vases slide 2 cells")
	eq(
		[front.kind, back.kind, hits_of(logs[0], back.id)],
		[Defs.KIND_FREIGHT, Defs.KIND_FREIGHT, []],
		"two cargo that stop at their slide limits make no hit on each other (SPEC Section 10.2)"
	)
	eq(box.pos, Vector2i(3, 1), "the box slides 2 cells to the vase")
	eq(
		held.kind,
		Defs.KIND_SCRAP,
		"a cargo at its limit hits a cargo that did not stop at its limit (SPEC Section 10.2)"
	)


func test_low_gravity_hit() -> void:
	run.environment = Defs.ENV_LOW_GRAVITY
	var vase := put("vase", 2, 2)
	shift([Defs.DIR_LEFT])
	eq(
		vase.kind,
		Defs.KIND_SCRAP,
		"a cargo that slides 2 cells into a wall still hits (SPEC Section 28.2)"
	)


func test_magnetic_storm() -> void:
	run.environment = Defs.ENV_MAGNETIC_STORM
	run.mods.append(Defs.MOD_ARRAY_POWER)
	var shield := put("shield", 2, 2)
	put("battery", 3, 2)
	check(
		not Shift.power_check(run).has(shield.id),
		"in a Magnetic Storm, no Shield has power, with Array Power too (SPEC Section 28.2)"
	)


func test_radiation_belt() -> void:
	var safe := put("chip", 2, 0)
	shift([Defs.DIR_LEFT])
	eq(
		safe.kind,
		Defs.KIND_FREIGHT,
		"with no environment, a hit does not short an Electronic cargo"
	)
	run.environment = Defs.ENV_RADIATION_BELT
	var chip := put("chip", 2, 3)
	var logs := shift([Defs.DIR_LEFT])
	eq(
		chip.kind,
		Defs.KIND_SCRAP,
		"in a Radiation Belt, an Electronic cargo shorts at force 2 (SPEC Section 28.2)"
	)
	eq(reaction_kinds(logs), [Defs.REACT_SHORT], "the log has the short (SPEC Section 28.2)")


func test_heat_zone() -> void:
	run.environment = Defs.ENV_HEAT_ZONE
	eq(
		run.break_limit(Defs.TRAIT_VOLATILE),
		2,
		"in a Heat Zone, Volatile breaks at 2 (SPEC Section 28.2)"
	)
	eq(
		run.break_limit(Defs.TRAIT_FLUID),
		1,
		"in a Heat Zone, Fluid breaks at 1 (SPEC Section 28.2)"
	)
	eq(run.break_limit(Defs.TRAIT_FRAGILE), 2, "Fragile does not change (SPEC Section 28.2)")
	var bomb := put("bomb", 2, 0)
	shift([Defs.DIR_LEFT])
	check(gone(bomb), "a Volatile cargo explodes at force 2 in a Heat Zone (SPEC Section 28.2)")


func test_environment_view() -> void:
	run.environment = Defs.ENV_HEAT_ZONE
	var e: Dictionary = RunView.view(run)["environment"]
	eq(e["id"], Defs.ENV_HEAT_ZONE, "the view has the environment of the leg (SPEC Section 28.1)")
	check(e["text"] != "", "the view has its rule (SPEC Section 28.1)")


func test_heat_zone_view() -> void:
	run.environment = Defs.ENV_HEAT_ZONE
	var limits := {}
	for t: Dictionary in RunView.terms(run.cat, run):
		limits[t["id"]] = t["limit"]
	eq(
		[limits[Defs.TRAIT_VOLATILE], limits[Defs.TRAIT_FLUID]],
		[2, 1],
		"in a Heat Zone, the rules of the traits show the limits of the leg (SPEC Section 28.2)"
	)
	eq(
		RunView.names(run.cat, run)["limits"][Defs.TRAIT_FLUID],
		1,
		"How to Play shows the limits of the leg (SPEC Section 28.2)"
	)


func test_radiation_jolt_risk() -> void:
	run.environment = Defs.ENV_RADIATION_BELT
	run.hazard = PackedStringArray([Defs.DIR_LEFT, Defs.DIR_UP])
	run.fork_options = PackedStringArray()
	var battery := put("battery", 0, 2)
	check(
		RunView.jolt_risks(run).has(battery.id),
		(
			"in a Radiation Belt, an Electronic cargo that the jolt would short shows a warning"
			+ " (SPEC Sections 12.3 and 28.2)"
		)
	)
