class_name CargoChip
extends Control
## A small drawing of a cargo for a list: the dock, a contract, or a shop offer.

signal pressed(chip: CargoChip)

var cargo: Dictionary = {}
var shape: Array = []
var cell := 22.0


func setup(cargo_view: Dictionary, cell_size := 22.0) -> CargoChip:
	cargo = cargo_view
	shape = cargo_view.get("shape", [])
	cell = cell_size
	var size_cells := CargoDraw.shape_size(shape)
	custom_minimum_size = Vector2(size_cells) * cell + Vector2(4, 4)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return self


func _draw() -> void:
	CargoDraw.draw(self, cargo, shape, Vector2(2, 2), cell)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(self)
		accept_event()
