class_name DragLayer
extends Control
## Draws the cargo or the clamp that the player drags, at the mouse (SPEC Section 21.1).

## The hold: a dragged cargo has the size of its cells.
var hold: HoldView
var _cargo: Dictionary = {}
var _shape: Array = []
var _grab := Vector2.ZERO
var _clamp := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 5


func start(cargo: Dictionary, shape: Array, grab: Vector2) -> void:
	_cargo = cargo
	_shape = shape
	_grab = grab
	_clamp = false
	queue_redraw()


func start_clamp() -> void:
	_cargo = {}
	_clamp = true
	queue_redraw()


func stop() -> void:
	_cargo = {}
	_clamp = false
	queue_redraw()


func _draw() -> void:
	var mouse := get_local_mouse_position()
	if _clamp:
		draw_rect(Rect2(mouse - Vector2(10, 10), Vector2(20, 20)), Palette.CLAMP)
		return
	if _cargo.is_empty():
		return
	var cell := hold.cell
	# A lifted cargo: a shadow and a scale of 1.05 (SPEC Section 21.1).
	var origin := mouse - (_grab + Vector2(0.5, 0.5)) * cell * 1.05
	CargoDraw.draw(self, {"kind": "scrap"}, _shape, origin + Vector2(8, 10), cell * 1.05, 0.35)
	CargoDraw.draw(self, _cargo, _shape, origin, cell * 1.05, 0.9)


func _process(_delta: float) -> void:
	if _clamp or not _cargo.is_empty():
		queue_redraw()
