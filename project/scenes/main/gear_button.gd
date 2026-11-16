class_name GearButton
extends Button
## The gear button at the top right of the station and the warp. It opens the
## pause menu (SPEC Sections 20.2 and 20.7). It draws the gear, because the font
## has no gear glyph.

const MENU_TEXT := "Menu (Esc)"
const SIZE := 56.0
const TEETH := 8

## The tip of the button. It is a child of the parent of the button, so that it can
## show next to the button.
var tip: CargoTip


func _init() -> void:
	name = "GearButton"
	custom_minimum_size = Vector2(SIZE, SIZE)
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -SIZE - 20
	offset_right = -20
	offset_top = 20
	offset_bottom = 20 + SIZE
	tip = CargoTip.new()
	mouse_entered.connect(func() -> void: tip.show_text(tr(MENU_TEXT), PackedStringArray()))
	mouse_exited.connect(func() -> void: tip.visible = false)
	visibility_changed.connect(func() -> void: tip.visible = tip.visible and visible)


func _ready() -> void:
	get_parent().add_child.call_deferred(tip)


func _draw() -> void:
	var color := Palette.ACCENT if is_hovered() or has_focus() else Palette.TEXT
	var center := size / 2.0
	var r := SIZE * 0.26
	for i in TEETH:
		draw_set_transform(center, TAU * i / TEETH)
		draw_rect(Rect2(Vector2(-4, -r - 7), Vector2(8, 10)), color)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	draw_circle(center, r, color)
	draw_circle(center, r * 0.45, Palette.PANEL)
