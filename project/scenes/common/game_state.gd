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
		"terms": RunView.terms(catalog),
		"names": RunView.names(catalog),
		"run": RunView.view(run) if run != null else {},
	}


## Starts a new run. A seed of 0 gets a random seed (SPEC Section 14).
func new_run(run_seed: int = 0) -> String:
	if not is_loaded():
		return NOT_LOADED_TEXT
	if run_seed == 0:
		run_seed = randi() + 1
	run = Run.new(catalog, run_seed)
	state_changed.emit()
	return ""


## Ends the run with no result (SPEC Section 20.7).
func abandon_run() -> void:
	run = null
	state_changed.emit()


## Reports whether a drop of a cargo at a place is valid (SPEC Section 8.3).
func can_place(id: int, x: int, y: int, rot: int) -> bool:
	return run != null and run.can_place(id, Vector2i(x, y), rot)


## Returns the links that a drop of a cargo at a place would make (SPEC Section 8.3).
func preview_links(id: int, x: int, y: int, rot: int) -> Array:
	return RunView.preview_links(run, id, Vector2i(x, y), rot) if run != null else []


func place_cargo(id: int, x: int, y: int, rot: int) -> String:
	return _act(func() -> String: return run.place_cargo(id, Vector2i(x, y), rot))


func dock_cargo(id: int) -> String:
	return _act(func() -> String: return run.dock_cargo(id))


func rotate_cargo(id: int) -> String:
	return _act(func() -> String: return run.rotate_cargo(id))


func clamp_cargo(id: int) -> String:
	return _act(func() -> String: return run.clamp_cargo(id))


func unclamp_cargo(id: int) -> String:
	return _act(func() -> String: return run.unclamp_cargo(id))


func accept_contract(index: int) -> String:
	return _act(func() -> String: return run.accept_contract(index))


func cancel_contract(index: int) -> String:
	return _act(func() -> String: return run.cancel_contract(index))


func buy_kit(index: int) -> String:
	return _act(func() -> String: return run.buy_kit(index))


func reroll() -> String:
	return _act(func() -> String: return run.reroll())


func buy_clamp() -> String:
	return _act(func() -> String: return run.buy_clamp())


func upgrade_hold(axis: String) -> String:
	return _act(func() -> String: return run.upgrade_hold(axis))


func sell_kit(id: int) -> String:
	return _act(func() -> String: return run.sell_kit(id))


func clear_scrap(id: int) -> String:
	return _act(func() -> String: return run.clear_scrap(id))


func warp() -> String:
	return _act(func() -> String: return run.warp())


func continue_run() -> String:
	return _act(func() -> String: return run.continue_run())


func pay_toll() -> String:
	return _act(func() -> String: return run.pay_toll())


func _act(action: Callable) -> String:
	if run == null:
		return NO_RUN_TEXT
	var err: String = action.call()
	if err == "":
		state_changed.emit()
	return err
