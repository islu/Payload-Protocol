extends RuleTest


func test_mass_is_weight_times_cells() -> void:
	var bar := put("bar", 0, 0)
	var heavy := put("heavy", 3, 3)
	eq(run.cargo_mass(bar), 4, "a standard cargo of 2 cells has a mass of 4 (SPEC Section 25)")
	eq(run.cargo_mass(heavy), 3, "a heavy cargo of 1 cell has a mass of 3 (SPEC Section 25)")


func test_hold_mass() -> void:
	put("bar", 0, 0)
	var scrap := put("ell", 3, 3)
	scrap.kind = Defs.KIND_SCRAP
	put("foam", 0, 5)
	on_dock("heavy")
	eq(
		run.hold_mass(),
		4 + 3 + 1,
		"freight, kit, and scrap count; the dock does not (SPEC Section 25)"
	)


func test_start_mass_limit() -> void:
	eq(run.mass_limit, 40, "a run starts with a mass limit of 40 (SPEC Section 25)")
	eq(run.max_mass(), 50, "the maximum is the limit plus 25%, rounded down (SPEC Section 25)")


## Puts heavy cargo in the hold until its mass is at least the target.
func _fill(target: int) -> void:
	for y in run.rows:
		for x in run.columns:
			if run.hold_mass() + 3 <= target:
				put("heavy", x, y)


func test_fuel_fee() -> void:
	_fill(45)
	eq(run.hold_mass(), 45, "the hold has a mass of 45")
	eq(
		run.fuel_fee(),
		10,
		"the fuel fee is 2 credits for each point over the limit (SPEC Section 25)"
	)
	warp_with([Defs.DIR_DOWN])
	eq(run.last_warp["fuel_fee"], 10, "the warp takes the fuel fee (SPEC Section 9)")
	eq(run.credits, 30, "40 credits minus the fee of 10 (SPEC Section 25)")


func test_no_fee_at_the_limit() -> void:
	_fill(39)
	eq(run.fuel_fee(), 0, "no fee at or under the limit (SPEC Section 25)")


func test_fee_can_go_below_zero() -> void:
	run.credits = 4
	_fill(45)
	warp_with([Defs.DIR_DOWN])
	eq(run.credits, -6, "the credits can go below 0 after the fuel fee (SPEC Section 25)")


func test_overweight_stops_the_warp() -> void:
	_fill(51)
	eq(
		run.warp(),
		Run.OVERWEIGHT_TEXT,
		"the warp does not start over the maximum (SPEC Section 25)"
	)
	eq(run.phase, Defs.PHASE_STATION, "the run stays at the station (SPEC Section 25)")


func test_reinforce_hull() -> void:
	run.credits = 100
	eq(run.reinforce_hull(), "", "buy Reinforce hull (SPEC Section 17.2)")
	eq(run.mass_limit, 48, "it adds 8 to the mass limit (SPEC Section 17.2)")
	eq(run.reinforce_hull(), "", "buy it again")
	eq(run.credits, 100 - 12 - 20, "each one costs 8 more than the last one (SPEC Section 17.2)")


func test_mass_view() -> void:
	_fill(45)
	var m: Dictionary = RunView.view(run)["mass"]
	eq(
		[m["hold"], m["limit"], m["max"], m["fee"]],
		[45, 40, 50, 10],
		"the top bar shows the mass and the fee (SPEC Section 25)"
	)
	eq(
		RunView.view(run)["cargo"][0]["mass"],
		3,
		"the tooltip shows the mass of a cargo (SPEC Section 25)"
	)
