extends RuleTest
## The tutorial (SPEC Section 23.4): a short run with fixed content, and its steps.
## The fixture tutorial has 3 jumps of the contract k_tut (a box and a vase).


## Returns a record of the fixture tutorial.
func _record() -> RunRecord:
	return RunRecord.new(run.cat, 1, true)


## Accepts the contract and puts the vase at the right wall and the box under it:
## a step right does not break the vase (a jolt of 1).
func _load_safe(rec: RunRecord) -> void:
	eq(rec.act(Defs.ACT_ACCEPT, [0]), "", "accept the contract")
	var ids: Array = rec.run.dock.duplicate()
	eq(rec.act(Defs.ACT_PLACE, [ids[0], 5, 1, 0]), "", "place the box")
	eq(rec.act(Defs.ACT_PLACE, [ids[1], 5, 0, 0]), "", "place the vase")


func test_fixed_content() -> void:
	var r := Run.new(run.cat, 1, true)
	eq(
		r.contracts.map(func(k: Contract) -> String: return k.template.id),
		["k_tut"],
		"the tutorial has the contracts of its data (SPEC Section 23.4)"
	)
	eq(
		[Array(r.hazard), Array(r.fork_options), r.shop.size()],
		[[Defs.DIR_RIGHT], [], 0],
		"the tutorial has the hazard and the shop of its data (SPEC Section 23.4)"
	)
	eq(
		[r.incident, r.event, r.environment, r.credits],
		[{}, null, "", 20],
		"the tutorial has no incident, no event, and no environment (SPEC Section 23.4)"
	)


func test_three_jumps_and_payment() -> void:
	var rec := _record()
	for j in 3:
		eq(rec.run.jump, j + 1, "jump %d of the tutorial" % (j + 1))
		_load_safe(rec)
		if j == 1:
			eq(rec.run.shop.size(), 1, "jump 2 sells the kit of its data (SPEC Section 23.4)")
		eq(rec.act(Defs.ACT_WARP), "", "warp")
		eq(rec.act(Defs.ACT_CONTINUE), "", "continue")
	eq(
		[rec.run.phase, rec.run.payment()],
		[Defs.PHASE_PAYMENT, 15],
		"after 3 jumps, the tutorial has its payment (SPEC Section 23.4)"
	)
	eq(rec.act(Defs.ACT_PAY), "", "pay")
	eq(
		[rec.run.phase, rec.run.won],
		[Defs.PHASE_END, true],
		"the payment ends the tutorial with no mod choice (SPEC Section 23.4)"
	)


func test_steps_advance() -> void:
	var rec := _record()
	var t := Tutorial.new(run.cat.tutorial)
	t.update(rec.run)
	eq(t.view()["text"], "Accept", "the first step waits for its action (SPEC Section 23.4)")
	eq(
		t.view()["target"],
		{"kind": "contract", "index": 0},
		"the step has its target (SPEC Section 23.4)"
	)
	check(not t.next(), "Next does not end a step with an action (SPEC Section 23.4)")
	eq(rec.act(Defs.ACT_ACCEPT, [0]), "", "accept the contract")
	t.update(rec.run)
	eq(
		t.view()["text"],
		"Read",
		"the step ends when the player does its action (SPEC Section 23.4)"
	)
	t.update(rec.run)
	eq(t.view()["text"], "Read", "a step with no action waits for Next (SPEC Section 23.4)")
	check(t.next(), "Next ends a step with no action (SPEC Section 23.4)")
	eq(
		[t.view()["text"], t.view()["try"]],
		["Load", false],
		"the next step starts (SPEC Section 23.4)"
	)


func test_try_step_goes_back() -> void:
	var rec := _record()
	var t := Tutorial.new(run.cat.tutorial)
	eq(rec.act(Defs.ACT_ACCEPT, [0]), "", "accept the contract")
	t.update(rec.run)
	t.next()
	# The vase at the left wall slides 5 cells to the right: force 5, and it breaks.
	var ids: Array = rec.run.dock.duplicate()
	eq(rec.act(Defs.ACT_PLACE, [ids[0], 0, 1, 0]), "", "place the box")
	eq(rec.act(Defs.ACT_PLACE, [ids[1], 0, 0, 0]), "", "place the vase")
	t.update(rec.run)
	eq([t.view()["text"], t.view()["try"]], ["Try", true], "the try step starts")
	var credits := rec.run.credits
	eq(rec.act(Defs.ACT_WARP), "", "warp")
	t.update(rec.run)
	check(t.failed(), "the goal of the try step fails: the vase broke (SPEC Section 23.4)")
	eq(t.view()["text"], "Try", "a failed try step does not end")
	eq(rec.back_to_warp(), "", "go back to the station before the warp")
	t.retry()
	var vase: Cargo = rec.run.cargo[ids[1]]
	eq(
		[rec.run.phase, rec.run.jump, vase.kind, vase.pos, rec.run.credits],
		[Defs.PHASE_STATION, 1, Defs.KIND_FREIGHT, Vector2i(0, 0), credits],
		"the tutorial goes back to the station before the warp (SPEC Section 23.4)"
	)
	check(not t.failed(), "the try step starts again")
	eq(rec.act(Defs.ACT_PLACE, [ids[1], 5, 0, 0]), "", "place the vase at the right wall")
	eq(rec.act(Defs.ACT_WARP), "", "warp")
	t.update(rec.run)
	eq(t.view()["text"], "Go on", "the goal is met: the try step ends (SPEC Section 23.4)")
