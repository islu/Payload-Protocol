extends Node
## The autoload GameState: the one owner of the game state. The scenes call its
## actions and read its view. They keep no game state (CLAUDE.md).
##
## Each action returns "" when it works, or an error text for the player. An
## action that works emits state_changed.

signal state_changed

const VERSION := "1.0.0"
const NOT_LOADED_TEXT := "The game data did not load."
const NO_RUN_TEXT := "No run is in progress."
const NO_TUTORIAL_TEXT := "No tutorial is in progress."
const NOT_NEXT_TEXT := "Do the action of this step first."
const NOT_FAILED_TEXT := "The try step did not fail."

var catalog: Catalog
var run: Run
## The seed and the actions of the run, for an undo (SPEC Section 20.2).
var _record: RunRecord
## The steps of the tutorial, or null in a normal run (SPEC Section 23.4).
var _tutorial: Tutorial
## The view of the state now, or {} after a change. view() builds it one time for
## each change: each scene that reads it gets the same copy. Do not change it.
var _view: Dictionary = {}


func _init() -> void:
	# The first listener: each other listener reads a new view.
	state_changed.connect(func() -> void: _view = {})


func _ready() -> void:
	catalog = DataFiles.catalog()
	for e in catalog.errors:
		push_error("data: " + e)


func is_loaded() -> bool:
	return catalog != null and catalog.errors.is_empty()


## Returns the visible game state: {version, terms, names, run}. run is {} with no run.
## The scenes must not change it: the next call returns the same copy until the state
## changes.
func view() -> Dictionary:
	if not is_loaded():
		return {"version": VERSION, "terms": [], "names": {}, "run": {}}
	if _view.is_empty():
		_view = {
			"version": VERSION,
			"terms": RunView.terms(catalog, run),
			"names": RunView.names(catalog, run),
			"run": RunView.view(run) if run != null else {},
			"tutorial": _tutorial.view() if _tutorial != null else {},
		}
	return _view


## Starts a new run. A seed of 0 gets a random seed (SPEC Section 14).
func new_run(run_seed: int = 0) -> String:
	if not is_loaded():
		return NOT_LOADED_TEXT
	if run_seed == 0:
		run_seed = randi() + 1
	_record = RunRecord.new(catalog, run_seed)
	run = _record.run
	_tutorial = null
	state_changed.emit()
	return ""


## Starts the tutorial: a run with the fixed content of the tutorial (SPEC Section 23.4).
func start_tutorial() -> String:
	if not is_loaded():
		return NOT_LOADED_TEXT
	_record = RunRecord.new(catalog, 1, true)
	run = _record.run
	_tutorial = Tutorial.new(catalog.tutorial)
	_tutorial.update(run)
	state_changed.emit()
	return ""


## Ends a tutorial step with no action: the Next button (SPEC Section 23.4).
func tutorial_next() -> String:
	if _tutorial == null:
		return NO_TUTORIAL_TEXT
	if not _tutorial.next():
		return NOT_NEXT_TEXT
	_tutorial.update(run)
	state_changed.emit()
	return ""


## Goes back to the station before the warp after a try step failed (SPEC Section 23.4).
func tutorial_retry() -> String:
	if _tutorial == null:
		return NO_TUTORIAL_TEXT
	if not _tutorial.failed():
		return NOT_FAILED_TEXT
	_record.back_to_warp()
	run = _record.run
	_tutorial.retry()
	_tutorial.update(run)
	state_changed.emit()
	return ""


## Leaves the tutorial and starts a normal run (SPEC Section 23.4).
func skip_tutorial() -> String:
	return new_run()


## Ends the run with no result (SPEC Section 20.7).
func abandon_run() -> void:
	run = null
	_record = null
	_tutorial = null
	state_changed.emit()


## Reports whether a drop of a cargo at a place is valid (SPEC Section 8.3).
func can_place(id: int, x: int, y: int, rot: int, to_bay := false) -> bool:
	return run != null and run.can_place(id, Vector2i(x, y), rot, to_bay)


## Returns the preview of a drop of a cargo at a place: each cell, the cargo in the
## way, and the nearest valid place (SPEC Section 8.3).
func drop_preview(id: int, x: int, y: int, rot: int, to_bay := false) -> Dictionary:
	if run == null:
		return {"ok": false, "cells": [], "blocking": [], "nearest": null}
	return RunView.drop_preview(run, id, Vector2i(x, y), rot, to_bay)


## Returns the links that a drop of a cargo at a place would make (SPEC Section 8.3).
func preview_links(id: int, x: int, y: int, rot: int, to_bay := false) -> Array:
	if run == null:
		return []
	return RunView.preview_links(run, id, Vector2i(x, y), rot, to_bay)


## Places a cargo in the hold, or in the stasis bay with to_bay (SPEC Sections 8.2 and 31.1).
func place_cargo(id: int, x: int, y: int, rot: int, to_bay := false) -> String:
	return _act(Defs.ACT_PLACE, [id, x, y, rot, to_bay])


func load_all() -> String:
	return _act(Defs.ACT_LOAD_ALL)


func dock_cargo(id: int) -> String:
	return _act(Defs.ACT_DOCK, [id])


func rotate_cargo(id: int) -> String:
	return _act(Defs.ACT_ROTATE, [id])


func clamp_cargo(id: int) -> String:
	return _act(Defs.ACT_CLAMP, [id])


func unclamp_cargo(id: int) -> String:
	return _act(Defs.ACT_UNCLAMP, [id])


func accept_contract(index: int) -> String:
	return _act(Defs.ACT_ACCEPT, [index])


func cancel_contract(index: int) -> String:
	return _act(Defs.ACT_CANCEL, [index])


func buy_kit(index: int) -> String:
	return _act(Defs.ACT_BUY_KIT, [index])


func reroll() -> String:
	return _act(Defs.ACT_REROLL)


func buy_clamp() -> String:
	return _act(Defs.ACT_BUY_CLAMP)


func reinforce_hull() -> String:
	return _act(Defs.ACT_REINFORCE)


## Installs the stasis bay, or makes it larger (SPEC Section 17.2).
func buy_shock_bay() -> String:
	return _act(Defs.ACT_BUY_BAY)


func sell_kit(id: int) -> String:
	return _act(Defs.ACT_SELL_KIT, [id])


func clear_scrap(id: int) -> String:
	return _act(Defs.ACT_CLEAR_SCRAP, [id])


func warp() -> String:
	return _act(Defs.ACT_WARP)


func continue_run() -> String:
	return _act(Defs.ACT_CONTINUE)


func make_payment() -> String:
	return _act(Defs.ACT_PAY)


## Selects a choice of the event of the station (SPEC Section 26.2).
func choose_event(index: int) -> String:
	return _act(Defs.ACT_CHOOSE_EVENT, [index])


## Selects a mod of the mod choice (SPEC Section 27.1).
func choose_mod(index: int) -> String:
	return _act(Defs.ACT_CHOOSE_MOD, [index])


## Changes the run directly, then draws the screens again. Only the screenshots and
## the UI checks use it, to set up a scene: the record does not keep the change, so an
## undo loses it.
func set_up(change: Callable) -> void:
	if run == null:
		return
	change.call(run)
	state_changed.emit()


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


func _act(name: String, args: Array = []) -> String:
	if run == null:
		return NO_RUN_TEXT
	var err := _record.act(name, args)
	if err == "":
		if _tutorial != null:
			_tutorial.update(run)
		state_changed.emit()
	return err
