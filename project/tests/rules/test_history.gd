extends RuleTest
## The history of the jumps, and the values of the report, the payment screen, and
## the run end screen (SPEC Sections 19.2, 20.4, 20.5, and 20.6).


## Plays one jump with two boxes in the bottom row: both arrive intact.
func _jump() -> void:
	skip_event()
	var k := accept(["k_boxes"])[0]
	var x := 0
	for id in k.cargo:
		eq(run.place_cargo(id, Vector2i(x, 5), 0), "", "load a box")
		x += 1
	warp_with([Defs.DIR_DOWN])


func test_each_arrival_adds_a_jump() -> void:
	eq(run.history, [], "a run starts with no jumps (SPEC Section 19.2)")
	var before := run.credits
	_jump()
	eq(run.history.size(), 1, "each arrival adds a jump to the history (SPEC Section 19.2)")
	var j: Dictionary = run.history[0]
	eq(
		[j["leg"], j["jump"], j["net"], j["delivered"], j["scrapped"], j["explosions"]],
		[1, 1, run.credits - before, 2, 0, 0],
		"a jump has its leg, its number, its net, and its counts (SPEC Section 20.5)"
	)


func test_leg_progress() -> void:
	_jump()
	var v := RunView.view(run)
	eq(
		v["leg_progress"],
		{"credits": run.credits, "payment": 60, "jumps_left": 2},
		"the report shows the credits, the payment, and the jumps before it (SPEC Section 20.4)"
	)
	eq(run.continue_run(), "", "continue")
	_jump()
	eq(run.continue_run(), "", "continue")
	_jump()
	eq(
		RunView.view(run)["leg_progress"]["jumps_left"],
		0,
		"after the last jump of a leg, the payment is at the next stop (SPEC Section 20.4)"
	)


func test_payment_view() -> void:
	for i in 3:
		_jump()
		eq(run.continue_run(), "", "continue")
	eq(run.phase, Defs.PHASE_PAYMENT, "the payment screen")
	var p: Dictionary = RunView.view(run)["payment_screen"]
	eq(p["jumps"].size(), 3, "the payment screen has a row for each jump of the leg (SPEC 20.5)")
	eq(
		p["next"],
		{"leg": 2, "jumps": 3, "payment": 140},
		"the payment screen shows the next leg (SPEC Section 20.5)"
	)
	run.leg = 3
	eq(
		RunView.view(run)["payment_screen"]["next"],
		{},
		"the last leg has no next leg (SPEC Section 20.5)"
	)


func test_end_view() -> void:
	for i in 3:
		_jump()
		eq(run.continue_run(), "", "continue")
	run.credits = 1000
	eq(run.make_payment(), "", "pay leg 1")
	run.phase = Defs.PHASE_PAYMENT
	run.credits = 0
	eq(run.make_payment(), "", "miss the payment of leg 2")
	var e: Dictionary = RunView.view(run)["end"]
	eq(
		e["legs"].map(func(l: Dictionary) -> Array: return [l["leg"], l["payment"], l["paid"]]),
		[[1, 60, true], [2, 140, false]],
		"the run end has a row for each leg that started: paid or missed (SPEC Section 19.2)"
	)
	var nets := 0
	for j: Dictionary in run.history:
		nets += j["net"]
	eq(e["legs"][0]["net"], nets, "the net of a leg is the sum of its jumps (SPEC Section 19.2)")
	eq(
		e["best_jump"]["net"],
		run.history.map(func(j: Dictionary) -> int: return j["net"]).max(),
		"the best jump is the jump with the largest net (SPEC Section 19.2)"
	)
	eq(
		[e["ship"]["clamps"], e["ship"]["shock_bay"], e["ship"]["mass_limit"]],
		[run.clamps, {}, run.mass_limit],
		"the run end shows the ship (SPEC Section 19.2)"
	)
