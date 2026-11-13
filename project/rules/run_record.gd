class_name RunRecord
extends RefCounted
## The record of a run: its seed and each action that worked. An undo plays the run
## again from the seed with no last action. The same seed and the same actions give
## the same run (SPEC Section 3), so a reroll after an undo gives the same offers.
## Undo works only at a station, back to the arrival at it (SPEC Section 20.2).

const NOTHING_TEXT := "There is nothing to undo at this station."

## The run now.
var run: Run
var _cat: Catalog
var _seed: int
## Each action that worked: a Callable that takes the Run and returns an error text.
var _actions: Array[Callable] = []
## The number of actions before the arrival at this station.
var _station_start := 0


func _init(catalog: Catalog, run_seed: int) -> void:
	_cat = catalog
	_seed = run_seed
	run = Run.new(catalog, run_seed)


## Does an action on the run. It records the action when it works.
func act(action: Callable) -> String:
	var at_station := run.phase == Defs.PHASE_STATION
	var err: String = action.call(run)
	if err != "":
		return err
	_actions.append(action)
	# An action that leaves the station, or that opens one, cannot be undone.
	if not at_station or run.phase != Defs.PHASE_STATION:
		_station_start = _actions.size()
	return ""


func can_undo() -> bool:
	return run.phase == Defs.PHASE_STATION and _actions.size() > _station_start


## Takes back the last action at this station (SPEC Section 20.2).
func undo() -> String:
	if not can_undo():
		return NOTHING_TEXT
	_actions.pop_back()
	run = Run.new(_cat, _seed)
	for a in _actions:
		a.call(run)
	return ""
