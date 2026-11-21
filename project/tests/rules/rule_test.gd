class_name RuleTest
extends TestCase
## The base of the rule tests: a run on the fixture catalog, at a station, with
## an empty hold. Use the real data only in test_data.gd.

var run: Run


func _init() -> void:
	run = Run.new(Fixture.catalog(), 7)


## Makes a cargo of a fixture definition and puts it in the hold.
func put(def_id: String, x: int, y: int, rot: int = 0) -> Cargo:
	var c := run.new_cargo(run.cat.cargo[def_id])
	var err := run.place_cargo(c.id, Vector2i(x, y), rot)
	if err != "":
		failures.append("setup: cannot put %s at (%d, %d): %s" % [def_id, x, y, err])
	return c


## Replaces the board with contracts of fixture templates, and accepts them.
func accept(template_ids: Array) -> Array[Contract]:
	run.contracts.clear()
	for id: String in template_ids:
		for t in run.cat.contracts:
			if t.id == id:
				run.contracts.append(Contract.new(100 + run.contracts.size(), t))
	for i in run.contracts.size():
		eq(run.accept_contract(i), "", "accept %s" % template_ids[i])
	return run.contracts


## Makes a cargo on the dock.
func on_dock(def_id: String) -> Cargo:
	return run.new_cargo(run.cat.cargo[def_id])


## Plays shift steps as a warp does, with no dock and no arrival.
func shift(dirs: Array) -> Array:
	Shift.charge_shields(run)
	var logs := []
	for d: String in dirs:
		logs.append(Shift.step(run, d))
	return logs


## Sets the hazard and warps.
func warp_with(dirs: Array) -> void:
	run.hazard = PackedStringArray(dirs)
	eq(run.warp(), "", "the warp works")


## Selects the last choice of the event of the station, if the station has one
## (SPEC Section 26.1).
func skip_event() -> void:
	if run.phase == Defs.PHASE_EVENT:
		eq(run.choose_event(run.event.choices.size() - 1), "", "skip the event")


func gone(c: Cargo) -> bool:
	return not run.cargo.has(c.id)


## Returns the kinds of all reactions of step logs.
static func reaction_kinds(logs: Array) -> Array:
	var out := []
	for s: Dictionary in logs:
		for r: Dictionary in s["reactions"]:
			out.append(r["kind"])
	return out


## Returns the hits of a cargo in a step log.
static func hits_of(log_step: Dictionary, id: int) -> Array:
	var out := []
	for h: Dictionary in log_step["hits"]:
		if h["cargo"] == id:
			out.append(h)
	return out
