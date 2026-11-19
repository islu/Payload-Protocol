class_name RunRecord
extends RefCounted
## The record of a run: its seed and each action that worked. An action is plain
## data, {name, args}, so a record can be saved and played again. An undo plays the
## run again from the seed with no last action. The same seed and the same actions
## give the same run (SPEC Section 3), so a reroll after an undo gives the same offers.
## Undo works only at a station, back to the arrival at it (SPEC Section 20.2).

const NOTHING_TEXT := "There is nothing to undo at this station."
const UNKNOWN_TEXT := "There is no such action."
const NO_WARP_TEXT := "There is no warp to go back to."

## The run now.
var run: Run
## Each action that worked: {name: a Defs.ACT_* constant, args: Array}.
var _actions: Array[Dictionary] = []
## The number of actions before the arrival at this station.
var _station_start := 0
## The catalog and the mode of the run, to play it again.
var _catalog: Catalog
var _tutorial := false


func _init(catalog: Catalog, run_seed: int, tutorial := false) -> void:
	_catalog = catalog
	_tutorial = tutorial
	run = Run.new(catalog, run_seed, tutorial)


## Does an action on the run. It records the action when it works.
func act(name: String, args: Array = []) -> String:
	var at_station := run.phase == Defs.PHASE_STATION
	var err := apply(run, name, args)
	if err != "":
		return err
	_actions.append({"name": name, "args": args.duplicate()})
	# An action that leaves the station, or that opens one, cannot be undone.
	if not at_station or run.phase != Defs.PHASE_STATION:
		_station_start = _actions.size()
	return ""


## Returns a copy of each action that worked, in order.
func actions() -> Array[Dictionary]:
	return _actions.duplicate(true)


func can_undo() -> bool:
	return run.phase == Defs.PHASE_STATION and _actions.size() > _station_start


## Takes back the last action at this station (SPEC Section 20.2). A full run plays
## again in about 10 ms, so the record keeps no copy of the run at the station start.
func undo() -> String:
	if not can_undo():
		return NOTHING_TEXT
	_actions.pop_back()
	_replay()
	return ""


## Goes back to the station before the last warp: the run plays again with no action
## from that warp on. The tutorial uses it after a try step fails (SPEC Section 23.4).
func back_to_warp() -> String:
	var at := -1
	for i in _actions.size():
		if _actions[i]["name"] == Defs.ACT_WARP:
			at = i
	if at < 0:
		return NO_WARP_TEXT
	_actions.resize(at)
	_replay()
	return ""


## Plays the run again from the seed with the recorded actions.
func _replay() -> void:
	run = Run.new(_catalog, run.seed_value, _tutorial)
	_station_start = 0
	for i in _actions.size():
		var at_station := run.phase == Defs.PHASE_STATION
		apply(run, _actions[i]["name"], _actions[i]["args"])
		if not at_station or run.phase != Defs.PHASE_STATION:
			_station_start = i + 1


## Does one action on a run, and returns its error text, or "".
static func apply(r: Run, name: String, args: Array) -> String:
	var n := func(i: int) -> int: return int(args[i]) if args.size() > i else -1
	match name:
		Defs.ACT_PLACE:
			var to_bay: bool = args.size() > 4 and args[4]
			return r.place_cargo(n.call(0), Vector2i(n.call(1), n.call(2)), n.call(3), to_bay)
		Defs.ACT_LOAD_ALL:
			return r.load_all()
		Defs.ACT_DOCK:
			return r.dock_cargo(n.call(0))
		Defs.ACT_ROTATE:
			return r.rotate_cargo(n.call(0))
		Defs.ACT_CLAMP:
			return r.clamp_cargo(n.call(0))
		Defs.ACT_UNCLAMP:
			return r.unclamp_cargo(n.call(0))
		Defs.ACT_ACCEPT:
			return r.accept_contract(n.call(0))
		Defs.ACT_CANCEL:
			return r.cancel_contract(n.call(0))
		Defs.ACT_BUY_KIT:
			return r.buy_kit(n.call(0))
		Defs.ACT_REROLL:
			return r.reroll()
		Defs.ACT_BUY_CLAMP:
			return r.buy_clamp()
		Defs.ACT_REINFORCE:
			return r.reinforce_hull()
		Defs.ACT_BUY_BAY:
			return r.buy_shock_bay()
		Defs.ACT_SELL_KIT:
			return r.sell_kit(n.call(0))
		Defs.ACT_CLEAR_SCRAP:
			return r.clear_scrap(n.call(0))
		Defs.ACT_WARP:
			return r.warp()
		Defs.ACT_CONTINUE:
			return r.continue_run()
		Defs.ACT_PAY:
			return r.make_payment()
		Defs.ACT_CHOOSE_EVENT:
			return r.choose_event(n.call(0))
		Defs.ACT_CHOOSE_MOD:
			return r.choose_mod(n.call(0))
	return UNKNOWN_TEXT
