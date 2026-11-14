extends TestCase
## Undo at the station: the record plays the run again from the seed, with no last
## action (SPEC Sections 3 and 20.2).

var rec := RunRecord.new(Fixture.catalog(), 7)


func view() -> String:
	return JSON.stringify(RunView.view(rec.run))


func test_undo_place() -> void:
	eq(rec.can_undo(), false, "a new station has nothing to undo (SPEC Section 20.2)")
	eq(rec.act(func(r: Run) -> String: return r.accept_contract(0)), "", "accept a contract")
	var id: int = rec.run.dock[0]
	var before := view()
	eq(
		rec.act(func(r: Run) -> String: return r.place_cargo(id, Vector2i(0, 0), 0)),
		"",
		"place the freight"
	)
	eq(rec.can_undo(), true, "a placement can be undone (SPEC Section 20.2)")
	eq(rec.undo(), "", "undo works")
	check(id in rec.run.dock, "undo puts the cargo back on the dock (SPEC Section 20.2)")
	eq(view(), before, "undo gives the run before the placement (SPEC Section 20.2)")
	eq(rec.undo(), "", "undo again")
	eq(rec.run.dock.size(), 0, "undo takes back the contract too (SPEC Section 20.2)")


func test_failed_action_is_not_recorded() -> void:
	eq(
		rec.act(func(r: Run) -> String: return r.cancel_contract(0)),
		Run.NOT_ACCEPTED_TEXT,
		"an action that fails gives its error"
	)
	eq(rec.can_undo(), false, "an action that fails is not an action to undo (SPEC Section 20.2)")


func test_undo_shop() -> void:
	var credits := rec.run.credits
	eq(rec.act(func(r: Run) -> String: return r.reroll()), "", "reroll the shop")
	var offers := JSON.stringify(RunView.view(rec.run)["shop"])
	eq(rec.undo(), "", "undo the reroll")
	eq(rec.run.credits, credits, "undo gives back the price (SPEC Section 20.2)")
	eq(rec.act(func(r: Run) -> String: return r.reroll()), "", "reroll again")
	eq(
		JSON.stringify(RunView.view(rec.run)["shop"]),
		offers,
		"after an undo, the same reroll gives the same offers (SPEC Section 20.2)"
	)


func test_undo_stops_at_station() -> void:
	rec.act(func(r: Run) -> String: return r.accept_contract(0))
	eq(rec.act(func(r: Run) -> String: return r.warp()), "", "warp")
	eq(rec.can_undo(), false, "the warp cannot be undone (SPEC Section 20.2)")
	eq(rec.undo(), RunRecord.NOTHING_TEXT, "undo gives an error after the warp")
	eq(rec.act(func(r: Run) -> String: return r.continue_run()), "", "go to the next station")
	eq(rec.run.phase, Defs.PHASE_EVENT, "the next station opens with its event (SPEC Section 26.1)")
	eq(rec.act(func(r: Run) -> String: return r.choose_event(0)), "", "select a choice")
	eq(rec.run.phase, Defs.PHASE_STATION, "the station opens")
	eq(
		rec.can_undo(),
		false,
		"undo does not go back past the choice of an event (SPEC Section 20.2)"
	)
	eq(
		rec.can_undo(),
		false,
		"undo does not go back past the arrival at the station (SPEC Section 20.2)"
	)
