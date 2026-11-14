extends Node
## The autoload GameState: the one owner of the game state. The scenes call its
## actions and read its view. They keep no game state (CLAUDE.md).
##
## Each action returns "" when it works, or an error text for the player. An
## action that works emits state_changed.

signal state_changed

const VERSION := "0.1.0"
const NOT_LOADED_TEXT := "The game data did not load."
const NO_RUN_TEXT := "No run is in progress."

var catalog: Catalog
var run: Run
## The seed and the actions of the run, for an undo (SPEC Section 20.2).
var _record: RunRecord


func _ready() -> void:
	catalog = DataFiles.catalog()
	for e in catalog.errors:
		push_error("data: " + e)


func is_loaded() -> bool:
	return catalog != null and catalog.errors.is_empty()


## Returns the visible game state: {version, terms, names, run}. run is {} with no run.
func view() -> Dictionary:
	if not is_loaded():
		return {"version": VERSION, "terms": [], "names": {}, "run": {}}
	return {
		"version": VERSION,
		"terms": RunView.terms(catalog, run),
		"names": RunView.names(catalog, run),
		"run": RunView.view(run) if run != null else {},
	}


## Starts a new run. A seed of 0 gets a random seed (SPEC Section 14).
func new_run(run_seed: int = 0) -> String:
	if not is_loaded():
		return NOT_LOADED_TEXT
	if run_seed == 0:
		run_seed = randi() + 1
	_record = RunRecord.new(catalog, run_seed)
	run = _record.run
	state_changed.emit()
	return ""


## Ends the run with no result (SPEC Section 20.7).
func abandon_run() -> void:
	run = null
	_record = null
	state_changed.emit()


## Reports whether a drop of a cargo at a place is valid (SPEC Section 8.3).
func can_place(id: int, x: int, y: int, rot: int) -> bool:
	return run != null and run.can_place(id, Vector2i(x, y), rot)


## Returns the links that a drop of a cargo at a place would make (SPEC Section 8.3).
func preview_links(id: int, x: int, y: int, rot: int) -> Array:
	return RunView.preview_links(run, id, Vector2i(x, y), rot) if run != null else []


func place_cargo(id: int, x: int, y: int, rot: int) -> String:
	return _act(func(r: Run) -> String: return r.place_cargo(id, Vector2i(x, y), rot))


func load_all() -> String:
	return _act(func(r: Run) -> String: return r.load_all())


func dock_cargo(id: int) -> String:
	return _act(func(r: Run) -> String: return r.dock_cargo(id))


func rotate_cargo(id: int) -> String:
	return _act(func(r: Run) -> String: return r.rotate_cargo(id))


func clamp_cargo(id: int) -> String:
	return _act(func(r: Run) -> String: return r.clamp_cargo(id))


func unclamp_cargo(id: int) -> String:
	return _act(func(r: Run) -> String: return r.unclamp_cargo(id))


func accept_contract(index: int) -> String:
	return _act(func(r: Run) -> String: return r.accept_contract(index))


func cancel_contract(index: int) -> String:
	return _act(func(r: Run) -> String: return r.cancel_contract(index))


func buy_kit(index: int) -> String:
	return _act(func(r: Run) -> String: return r.buy_kit(index))


func reroll() -> String:
	return _act(func(r: Run) -> String: return r.reroll())


func buy_clamp() -> String:
	return _act(func(r: Run) -> String: return r.buy_clamp())


func reinforce_hull() -> String:
	return _act(func(r: Run) -> String: return r.reinforce_hull())


func upgrade_hold(axis: String) -> String:
	return _act(func(r: Run) -> String: return r.upgrade_hold(axis))


func sell_kit(id: int) -> String:
	return _act(func(r: Run) -> String: return r.sell_kit(id))


func clear_scrap(id: int) -> String:
	return _act(func(r: Run) -> String: return r.clear_scrap(id))


func warp() -> String:
	return _act(func(r: Run) -> String: return r.warp())


func continue_run() -> String:
	return _act(func(r: Run) -> String: return r.continue_run())


func make_payment() -> String:
	return _act(func(r: Run) -> String: return r.make_payment())


## Selects a choice of the event of the station (SPEC Section 26.2).
func choose_event(index: int) -> String:
	return _act(func(r: Run) -> String: return r.choose_event(index))


## Selects a mod of the mod choice (SPEC Section 27.1).
func choose_mod(index: int) -> String:
	return _act(func(r: Run) -> String: return r.choose_mod(index))


## Reports whether the player can take back an action at this station (SPEC Section 20.2).
func can_undo() -> bool:
	return _record != null and _record.can_undo()


## Takes back the last action at this station (SPEC Section 20.2).
func undo() -> String:
	if _record == null:
		return NO_RUN_TEXT
	var err := _record.undo()
	if err == "":
		run = _record.run
		state_changed.emit()
	return err


func _act(action: Callable) -> String:
	if run == null:
		return NO_RUN_TEXT
	var err := _record.act(action)
	if err == "":
		state_changed.emit()
	return err
