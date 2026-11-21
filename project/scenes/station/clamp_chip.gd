class_name ClampChip
extends Control
## One free clamp in the clamp panel. A press starts a drag of the clamp (SPEC Section 13).

signal pressed


func _init() -> void:
	custom_minimum_size = Vector2(40, 40)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _draw() -> void:
	draw_rect(Rect2(Vector2(8, 8), Vector2(24, 24)), Palette.CLAMP)
	draw_rect(Rect2(Vector2(4, 4), Vector2(32, 32)), Palette.CLAMP, false, 2.0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
		accept_event()
