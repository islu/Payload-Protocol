class_name CargoChip
extends Control
## A small drawing of a cargo for a list: the dock, a contract, or a shop offer.

signal pressed(chip: CargoChip)

## The cell of the shape under the last press (SPEC Section 8.3).
var press_cell := Vector2i.ZERO

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


## Returns the cell of the shape at a local position (SPEC Section 8.3).
## A press on an empty cell of the box gives the nearest cell of the shape.
func cell_at(local: Vector2) -> Vector2i:
	var at := (local - Vector2(2, 2)) / cell
	var best := Vector2i.ZERO
	var best_d := INF
	for c: Dictionary in shape:
		var d := at.distance_squared_to(Vector2(c["x"], c["y"]) + Vector2(0.5, 0.5))
		if d < best_d:
			best_d = d
			best = Vector2i(c["x"], c["y"])
	return best


func _draw() -> void:
	CargoDraw.draw(self, cargo, shape, Vector2(2, 2), cell)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		press_cell = cell_at(event.position)
		pressed.emit(self)
		accept_event()
