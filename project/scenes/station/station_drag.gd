class_name StationDrag
extends RefCounted
## The drag of the station (SPEC Sections 8.2, 8.3, and 13): a cargo or a clamp
## that the player moves with a drag or picks up with a click. StationScreen owns
## it and sends it the input. The drops call the actions of GameState.

## A press and a release closer than this are a click: a pick up (SPEC Section 8.2).
const CLICK_DISTANCE := 8.0

## The drag now: {kind: "cargo" or "clamp", id, rot, grab: Vector2, press: Vector2,
## held: bool, from_dock: bool}, or empty. held is true after a click: a pick up
## (SPEC Section 8.2).
var state: Dictionary = {}
## True after the click that drops a picked-up cargo, so that its release does nothing.
var ignore_release := false

var _screen: StationScreen


func _init(screen: StationScreen) -> void:
	_screen = screen


func is_active() -> bool:
	return not state.is_empty()


func begin_cargo(id: int, grab: Vector2) -> void:
	var c := _screen._cargo(id)
	if c.is_empty():
		return
	_screen._hide_tip()
	state = {
		"kind": "cargo",
		"id": id,
		"rot": c["rot"],
		"grab": grab,
		"press": _screen.get_global_mouse_position(),
		"held": false,
		"from_dock": not c["in_hold"],
	}
	_screen._hold.dragging = id
	_screen._show_sell(c)
	_screen._drag_layer.start(c, c["rotations"][c["rot"]], grab)
	update()
	_screen._update_marks()


func begin_clamp() -> void:
	state = {"kind": "clamp", "press": _screen.get_global_mouse_position(), "held": false}
	_screen._drag_layer.start_clamp()


## Handles an input event during a drag. It returns true when it used the event.
func handle_input(event: InputEvent) -> bool:
	var left_release: bool = (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and not event.pressed
	)
	if ignore_release and left_release:
		ignore_release = false
		return true
	if state.is_empty():
		return false
	if event is InputEventMouseMotion:
		update()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_left_button(event.pressed)
			return true
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			rotate()
			return true
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			rotate()
		elif event.keycode == KEY_ESCAPE:
			end()
		return true
	return false


## The left button while the player holds a cargo or a clamp (SPEC Section 8.2):
## a release after a drag drops it, a release after a click picks it up, and the
## next press drops a picked-up cargo.
func _on_left_button(pressed: bool) -> void:
	if pressed:
		if state["held"]:
			ignore_release = true
			_drop()
		return
	var mouse := _screen.get_global_mouse_position()
	if not state["held"] and mouse.distance_to(state["press"]) < CLICK_DISTANCE:
		state["held"] = true
	else:
		_drop()


func rotate() -> void:
	if state["kind"] != "cargo":
		return
	var c := _screen._cargo(state["id"])
	# The same cell of the cargo stays under the cursor (SPEC Section 8.2).
	state["grab"] = HoldView.rotate_grab(c["rotations"][state["rot"]], state["grab"])
	state["rot"] = (state["rot"] + 1) % 4
	Hints.done(Hints.ROTATE)
	_screen._show_pilot()
	_screen._drag_layer.start(c, c["rotations"][state["rot"]], state["grab"])
	update()


## Moves the drag to the mouse, and shows the preview over the hold (SPEC Section 8.3).
func update() -> void:
	var hold := _screen._hold
	var mouse := _screen.get_global_mouse_position()
	_screen._drag_layer.queue_redraw()
	if state["kind"] != "cargo" or not hold.is_over(mouse):
		hold.preview = {}
		hold.queue_redraw()
		return
	var origin := hold.snap_origin(mouse, state["grab"])
	var c := _screen._cargo(state["id"])
	var cells: Array[Vector2i] = []
	for s: Dictionary in c["rotations"][state["rot"]]:
		cells.append(origin + Vector2i(s["x"], s["y"]))
	hold.preview = {
		"cells": cells,
		"ok": GameState.can_place(state["id"], origin.x, origin.y, state["rot"]),
		"links": GameState.preview_links(state["id"], origin.x, origin.y, state["rot"]),
		"id": state["id"],
	}
	hold.queue_redraw()


func _drop() -> void:
	drop_at(_screen.get_global_mouse_position())


## Drops the held cargo or clamp at a global position (SPEC Sections 8.2 and 13).
func drop_at(mouse: Vector2) -> void:
	var drag := state
	var hold := _screen._hold
	end()
	if drag["kind"] == "clamp":
		if hold.is_over(mouse):
			var target := hold.cargo_at(hold.cell_at(mouse))
			if target >= 0:
				_screen._act(GameState.clamp_cargo(target), "clack")
		return
	var id: int = drag["id"]
	var c := _screen._cargo(id)
	if _screen._sell_area.get_global_rect().has_point(mouse):
		if c["kind"] == Defs.KIND_SCRAP:
			_screen._act(GameState.clear_scrap(id), "coin")
		else:
			_screen._act(GameState.sell_kit(id), "coin")
	elif _screen._dock_panel.get_global_rect().has_point(mouse):
		if c["in_hold"]:
			_screen._act(GameState.dock_cargo(id))
	elif hold.is_over(mouse):
		var origin := hold.snap_origin(mouse, drag["grab"])
		var err := GameState.place_cargo(id, origin.x, origin.y, drag["rot"])
		_screen._act(err, "clack")
		# A picked-up cargo from the dock: pick up the next one (SPEC Section 8.2).
		if err == "" and drag["held"] and drag["from_dock"]:
			_pick_next()
	# A drop anywhere else leaves the cargo in its last place (SPEC Section 8.3).


## Picks up the next cargo on the dock after a placement by clicks (SPEC Section 8.2).
func _pick_next() -> void:
	# refresh() set the run of the screen for this action already.
	var dock: Array = _screen._run["dock"]
	if dock.is_empty():
		return
	# Grab a real cell of the shape: cell (0, 0) of the box can be empty (SPEC Section 8.3).
	var c := _screen._cargo(dock[0])
	var first: Dictionary = c["rotations"][c["rot"]][0]
	begin_cargo(dock[0], Vector2(first["x"], first["y"]))
	state["held"] = true


func end() -> void:
	state = {}
	_screen._show_sell({})
	_screen._hold.dragging = -1
	_screen._hold.preview = {}
	_screen._drag_layer.stop()
	_screen._update_marks()
