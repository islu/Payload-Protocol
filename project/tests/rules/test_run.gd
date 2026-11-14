extends RuleTest


## Puts the freight of a contract in a row of the hold, from the left.
func load_row(k: Contract, y: int) -> void:
	var x := 0
	for id in k.cargo:
		eq(run.place_cargo(id, Vector2i(x, y), 0), "", "load the freight")
		x += Shapes.size(run.cargo[id].shape()).x


func test_start_values() -> void:
	eq(
		[run.credits, run.clamps, run.columns, run.rows],
		[40, 1, 6, 6],
		"the start values of rules.json (SPEC Section 14)"
	)
	eq(run.phase, Defs.PHASE_STATION, "the run starts at a station (SPEC Section 14)")
	eq(run.contracts.size(), 3, "the board offers 3 contracts (SPEC Section 15.1)")
	eq(run.shop.size(), 3, "the shop offers 3 kit (SPEC Section 17.1)")


func test_accept_and_cancel() -> void:
	var k := accept(["k_boxes"])[0]
	eq(
		run.dock.size(),
		2,
		"the freight of an accepted contract goes to the dock (SPEC Section 15.1)"
	)
	eq(
		run.accept_contract(0),
		Run.ACCEPTED_TEXT,
		"a contract is accepted one time (SPEC Section 15.1)"
	)
	run.place_cargo(k.cargo[0], Vector2i(0, 0), 0)
	eq(run.cancel_contract(0), "", "the player can cancel before the warp (SPEC Section 15.1)")
	check(
		run.cargo.is_empty() and run.dock.is_empty(),
		"the freight leaves the hold and the dock (SPEC Section 15.1)"
	)
	eq(run.credits, 40, "a cancel has no fee (SPEC Section 15.1)")


func test_delivery_pays_and_leaves() -> void:
	var k := accept(["k_boxes"])[0]
	load_row(k, 5)
	warp_with([Defs.DIR_DOWN])
	eq(run.credits, 50, "each intact piece pays its pay: 2 x 5 (SPEC Section 16)")
	check(run.cargo.is_empty(), "intact freight leaves the hold (SPEC Section 16)")
	eq(run.phase, Defs.PHASE_ARRIVAL, "the arrival report shows (SPEC Section 20.4)")
	eq(run.stats["delivered"], 2, "the run counts the delivered freight (SPEC Section 19.2)")


func test_scrap_stays_and_does_not_pay() -> void:
	var k := accept(["k_vases"])[0]
	run.place_cargo(k.cargo[0], Vector2i(0, 5), 0)
	run.place_cargo(k.cargo[1], Vector2i(3, 3), 0)  # slides 2 cells down: breaks
	warp_with([Defs.DIR_DOWN])
	eq(run.credits, 48, "only the intact piece pays, and no bonus (SPEC Sections 15.3 and 16)")
	eq(run.hold_cargo().size(), 1, "scrap stays in the hold (SPEC Section 16)")
	var states := []
	for p: Dictionary in run.last_arrival["contracts"][0]["pieces"]:
		states.append(p["state"])
	eq(
		states,
		[Defs.PIECE_DELIVERED, Defs.PIECE_SCRAP],
		"the report shows each piece (SPEC Section 20.4)"
	)


func test_all_intact_bonus() -> void:
	var k := accept(["k_vases"])[0]
	load_row(k, 5)
	warp_with([Defs.DIR_DOWN])
	eq(run.credits, 40 + 16 + 6, "all_intact pays when each piece is delivered (SPEC Section 15.3)")


func test_zone_bonus() -> void:
	var k := accept(["k_bars"])[0]
	run.place_cargo(k.cargo[0], Vector2i(2, 5), 0)
	warp_with([Defs.DIR_LEFT])
	eq(run.credits, 40 + 7 + 4, "zone pays when each piece ends in the zone (SPEC Section 15.3)")
	var tr := RuleTest.new()
	var bar := tr.accept(["k_bars"])[0]
	tr.run.place_cargo(bar.cargo[0], Vector2i(2, 5), 0)
	tr.warp_with([Defs.DIR_RIGHT])
	eq(tr.run.credits, 40 + 7, "zone does not pay out of the zone (SPEC Section 15.3)")
	failures.append_array(tr.failures)


func test_not_next_to_bonus() -> void:
	var k := accept(["k_chips"])[0]
	# A warp with no shift step: only the bonus rule counts. The chips are at (0,0) and (1,0).
	load_row(k, 0)
	put("tank", 4, 0)
	warp_with([])
	eq(
		run.credits,
		40 + 10 + 4,
		"not_next_to pays when no piece is next to the trait (SPEC Section 15.3)"
	)


func test_not_next_to_bonus_fails() -> void:
	var k := accept(["k_chips"])[0]
	load_row(k, 0)
	put("tank", 2, 0)
	warp_with([])
	eq(run.credits, 40 + 10, "not_next_to does not pay next to the trait (SPEC Section 15.3)")


func test_bonus_needs_each_piece() -> void:
	var k := accept(["k_chips"])[0]
	load_row(k, 0)
	put("tank", 4, 0)
	# One chip broke on the way: the other chip arrives, far from the Fluid cargo.
	run.cargo[k.cargo[1]].kind = Defs.KIND_SCRAP
	warp_with([])
	eq(
		run.credits,
		40 + 5,
		"one piece that is scrap cancels the bonus of its contract (SPEC Section 15.3)"
	)


func test_breach() -> void:
	var k := accept(["k_vases"])[0]
	run.place_cargo(k.cargo[0], Vector2i(0, 5), 0)
	warp_with([Defs.DIR_DOWN])
	eq(
		run.credits,
		40 + 8 - 5,
		"freight on the dock pays the breach fee, and the bonus cannot pay (SPEC Section 15.4)"
	)
	eq(
		run.last_arrival["contracts"][0]["pieces"][1]["state"],
		Defs.PIECE_BREACHED,
		"the piece is breached (SPEC Section 20.4)"
	)


func test_warp_sells_kit_on_dock() -> void:
	on_dock("shield")
	warp_with([Defs.DIR_DOWN])
	eq(run.credits, 46, "kit on the dock is sold at the sell price (SPEC Section 9)")
	eq(run.last_warp["sold_credits"], 6, "the warp log has the sale (SPEC Section 9)")


func test_lost_freight() -> void:
	run.contracts = [
		Contract.new(
			1,
			ContractTemplate.from_dict(
				{"id": "x", "legs": [1], "client_name": "X", "freight": ["bomb"], "pay": 9}
			)
		)
	]
	run.accept_contract(0)
	run.place_cargo(run.contracts[0].cargo[0], Vector2i(0, 2), 0)
	warp_with([Defs.DIR_DOWN])
	eq(
		run.last_arrival["contracts"][0]["pieces"][0]["state"],
		Defs.PIECE_LOST,
		"exploded freight is lost (SPEC Section 20.4)"
	)
	eq(
		run.last_arrival["contracts"][0]["pieces"][0].get("id"),
		run.contracts[0].cargo[0],
		"each piece has the ID of its cargo, so that the report can mark it (SPEC Section 20.4)"
	)
	eq(run.credits, 40, "lost freight does not pay (SPEC Section 16)")


func test_warp_log_has_the_hold_before() -> void:
	var c := put("box", 2, 2)
	warp_with([Defs.DIR_LEFT])
	var before: Array = run.last_warp["before"]
	eq(before.size(), 1, "the log has each cargo of the hold before the warp (SPEC Section 20.3)")
	eq(
		[before[0]["id"], before[0]["x"], before[0]["y"]],
		[c.id, 2, 2],
		"at its place before the slide"
	)


func test_kit_stays() -> void:
	put("foam", 0, 0)
	warp_with([Defs.DIR_DOWN])
	eq(run.hold_cargo().size(), 1, "kit stays in the hold after the arrival (SPEC Section 6.3)")


func test_shop() -> void:
	run.shop = [{"def": run.cat.cargo["shield"], "bought": false}]
	eq(run.buy_kit(0), "", "buy a kit (SPEC Section 17.1)")
	eq(run.credits, 28, "the price is paid (SPEC Section 17.1)")
	eq(run.dock.size(), 1, "the kit goes to the dock (SPEC Section 17.1)")
	eq(
		run.buy_kit(0),
		Run.OFFER_BOUGHT_TEXT,
		"each offer can be bought one time (SPEC Section 17.1)"
	)
	eq(run.sell_kit(run.dock[0]), "", "sell a kit (SPEC Section 17.3)")
	eq(run.credits, 34, "the sell price is half, rounded down (SPEC Section 17.3)")


func test_reroll_price_rises() -> void:
	eq(run.reroll(), "", "reroll (SPEC Section 17.1)")
	eq(run.reroll(), "", "reroll again (SPEC Section 17.1)")
	eq(run.credits, 40 - 2 - 4, "each reroll costs 2 more (SPEC Section 17.1)")
	eq(run.shop.size(), 3, "a reroll gives 3 offers (SPEC Section 17.1)")


func test_clamps_and_upgrades() -> void:
	run.credits = 1000
	for i in 3:
		eq(run.buy_clamp(), "", "buy a clamp (SPEC Section 17.2)")
	eq(run.buy_clamp(), Run.CLAMPS_MAXED_TEXT, "the maximum is 4 clamps (SPEC Section 17.2)")
	eq(run.upgrade_hold(Defs.AXIS_COLUMN), "", "add a column (SPEC Section 17.2)")
	eq(run.upgrade_hold(Defs.AXIS_ROW), "", "add a row (SPEC Section 17.2)")
	eq([run.columns, run.rows], [7, 7], "the hold grows (SPEC Section 17.2)")
	eq(run.credits, 1000 - 24 - 15 - 25, "each upgrade costs 10 more (SPEC Section 17.2)")
	run.upgrade_hold(Defs.AXIS_COLUMN)
	eq(
		run.upgrade_hold(Defs.AXIS_COLUMN),
		Run.HOLD_MAXED_TEXT,
		"the maximum is 8 columns (SPEC Section 5)"
	)


func test_clear_scrap() -> void:
	var c := put("bar", 0, 0)
	c.kind = Defs.KIND_SCRAP
	eq(run.sell_kit(c.id), Run.CANNOT_SELL_TEXT, "the player cannot sell scrap (SPEC Section 17.3)")
	eq(run.clear_scrap(c.id), "", "clear a scrap (SPEC Section 17.4)")
	eq(run.credits, 36, "2 credits for each cell (SPEC Section 17.4)")


func test_cannot_buy_without_credits() -> void:
	run.credits = 5
	eq(
		run.buy_clamp(),
		Run.NOT_ENOUGH_TEXT,
		"the player cannot buy when the price is more than the credits (SPEC Section 17.5)"
	)
	run.credits = -3
	eq(run.reroll(), Run.IN_DEBT_TEXT, "the player cannot buy below 0 credits (SPEC Section 16)")


func test_hazard() -> void:
	eq(run.hazard.size(), 1, "the first jump has 1 step (SPEC Section 18)")
	for i in 30:
		var r := Run.new(run.cat, i + 1)
		r.leg = 3
		r.jump = 2
		var h := Route.make_hazard(r)
		check(h.size() >= 2 and h.size() <= 3, "leg 3 has 2 or 3 steps (SPEC Section 18)")
		for k in range(1, h.size()):
			check(h[k] != h[k - 1], "two steps next to each other differ (SPEC Section 18)")


func test_payments() -> void:
	for jump in 3:
		if run.phase == Defs.PHASE_EVENT:
			run.choose_event(run.event.choices.size() - 1)
		eq(run.warp(), "", "warp")
		eq(run.continue_run(), "", "continue")
	eq(
		run.phase,
		Defs.PHASE_PAYMENT,
		"the payment screen comes after the last jump of a leg (SPEC Section 19.1)"
	)
	run.credits = 100
	eq(run.make_payment(), "", "pay the payment (SPEC Section 19.1)")
	eq(
		[run.credits, run.leg, run.jump, run.phase],
		[40, 2, 1, Defs.PHASE_MOD],
		"the next leg starts, with a mod choice first (SPEC Sections 19.1 and 27.1)"
	)


func test_payment_loss() -> void:
	run.phase = Defs.PHASE_PAYMENT
	run.credits = 59
	run.make_payment()
	eq(
		run.phase,
		Defs.PHASE_END,
		"the run ends when the credits are less than the payment (SPEC Section 19.1)"
	)
	check(not run.won, "it is a loss (SPEC Section 19.1)")
	eq(run.score(), 0, "a loss has no score (SPEC Section 19.2)")


func test_win() -> void:
	run.phase = Defs.PHASE_PAYMENT
	run.leg = 3
	run.credits = 300
	run.make_payment()
	check(
		run.won and run.phase == Defs.PHASE_END,
		"making the last payment wins the run (SPEC Section 19.2)"
	)
	eq(run.score(), 40, "the score is the credits after the last payment (SPEC Section 19.2)")


func test_same_seed_same_run() -> void:
	var a := Run.new(run.cat, 99)
	var b := Run.new(run.cat, 99)
	for r: Run in [a, b]:
		r.accept_contract(0)
		r.place_cargo(r.dock[0], Vector2i(2, 2), 0)
		r.warp()
	eq(
		JSON.stringify(RunView.view(a)),
		JSON.stringify(RunView.view(b)),
		"the same seed and actions give the same run (SPEC Section 3)"
	)


func test_lines_do_not_repeat() -> void:
	var last := ""
	for i in 40:
		run.say(Defs.LINE_HAZARD)
		check(
			run.line != last,
			"the pilot does not say the same line two times in a row (SPEC Section 22)"
		)
		last = run.line
