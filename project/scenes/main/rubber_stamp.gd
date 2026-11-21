class_name RubberStamp
extends Control
## The rubber stamp of the payment screen (SPEC Section 20.5). The stamp comes down on
## the receipt, hits it, and lifts away. The mark stays: the text in a double frame,
## with a worn ink edge. Drops of ink fly out at the hit.

## At the hit: the panel plays the sound and shakes the receipt.
signal hit

const SIZE := 64
const ROTATION := -12.0
## The times of the stamp: it shows above, comes down, and lifts away.
const SHOW_TIME := 0.12
const DOWN_TIME := 0.12
const LIFT_TIME := 0.25
const LIFT_WAIT := 0.15
## The height above the mark where the stamp starts and ends.
const HEIGHT := 150.0
## The height of one pixel of the drawn stamp. Its width fits the rubber to the mark.
const PIXEL := 13.0
const INK_DROPS := 10
const INK_TIME := 0.35
## The worn ink: the pixel blocks of FRAGCOORD with a low noise value are pale.
const WORN_SHADER := """
shader_type canvas_item;
uniform float block = 3.0;
uniform float worn = 0.2;
float noise(vec2 p) {
	return fract(sin(dot(floor(p / block), vec2(12.9898, 78.233))) * 43758.5453);
}
void fragment() {
	float n = noise(FRAGCOORD.xy);
	COLOR.a *= n < worn ? 0.15 : (n < worn * 2.0 ? 0.6 : 0.95);
}
"""
## The handle of the stamp in pixels: wood for the knob and the neck, dark for the
## block, and ink for the rubber. Each string is one row.
const HANDLE_ROWS := [
	"....wwww....",
	"...wwwwww...",
	"...wwwwww...",
	"....wwww....",
	".....ww.....",
	".....ww.....",
	"..dddddddd..",
	".dddddddddd.",
	".iiiiiiiiii.",
]
const WOOD := Color("#b0753f")
const DARK := Color("#3a3f55")

## The parts and what played, for the checks.
var mark: Control
var label: Label
var handle: Control
var played: Array[String] = []
var text: String:
	get:
		return label.text

var _color := Palette.GOOD
## The progress of the ink drops from 0 to 1, or -1 before the hit.
var _ink := -1.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	mark = Control.new()
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var worn := ShaderMaterial.new()
	worn.shader = Shader.new()
	worn.shader.code = WORN_SHADER
	mark.material = worn
	mark.draw.connect(_draw_frame)
	add_child(mark)
	label = Label.new()
	label.use_parent_material = true
	TextSize.display(label, SIZE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.add_child(label)
	handle = Control.new()
	handle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	handle.visible = false
	handle.draw.connect(_draw_handle)
	add_child(handle)


## Sets the text and the color of the mark. The mark is at the center of the stamp.
func set_mark(t: String, color: Color) -> void:
	_color = color
	label.text = t
	label.add_theme_color_override("font_color", color)
	var s := label.get_combined_minimum_size() + Vector2(36, 12)
	custom_minimum_size = s
	mark.size = s
	mark.pivot_offset = s / 2.0
	mark.rotation_degrees = ROTATION
	label.position = Vector2.ZERO
	label.size = s
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	handle.size = Vector2(s.x, HANDLE_ROWS.size() * PIXEL)
	handle.pivot_offset = Vector2(s.x / 2.0, handle.size.y)
	handle.rotation_degrees = ROTATION
	mark.queue_redraw()
	handle.queue_redraw()


## The stamp comes down, hits, and lifts away. Then done runs.
func slam(done: Callable = Callable()) -> void:
	played.clear()
	visible = true
	mark.visible = false
	# The rubber covers the mark: the bottom of the stamp is at the bottom of the mark.
	var down := (size - mark.size) / 2.0 + Vector2(0, mark.size.y - handle.size.y)
	handle.position = down - Vector2(0, HEIGHT)
	handle.modulate.a = 0.0
	handle.visible = true
	var tw := create_tween()
	tw.tween_property(handle, "modulate:a", 1.0, SHOW_TIME)
	tw.tween_property(handle, "position", down, DOWN_TIME).set_ease(Tween.EASE_IN).set_trans(
		Tween.TRANS_QUAD
	)
	tw.tween_callback(_hit)
	tw.tween_property(handle, "scale", Vector2(1.1, 0.8), 0.05)
	tw.tween_property(handle, "scale", Vector2.ONE, 0.05)
	tw.tween_interval(LIFT_WAIT)
	tw.tween_property(handle, "position", down - Vector2(0, HEIGHT), LIFT_TIME).set_ease(
		Tween.EASE_OUT
	)
	tw.parallel().tween_property(handle, "modulate:a", 0.0, LIFT_TIME)
	tw.tween_callback(_lifted)
	if done.is_valid():
		tw.tween_callback(done)


func _hit() -> void:
	played.append("hit")
	mark.visible = true
	mark.scale = Vector2(1.12, 1.12)
	create_tween().tween_property(mark, "scale", Vector2.ONE, 0.1)
	played.append("ink")
	var tw := create_tween()
	tw.tween_method(_set_ink, 0.0, 1.0, INK_TIME)
	tw.tween_callback(_set_ink.bind(-1.0))
	hit.emit()


func _lifted() -> void:
	handle.visible = false
	played.append("lift")


func _set_ink(t: float) -> void:
	_ink = t
	queue_redraw()


## The drops of ink: they fly out from the edge of the mark and fade.
func _draw() -> void:
	if _ink < 0.0:
		return
	var center := size / 2.0
	var c := _color
	c.a = 1.0 - _ink
	for i in INK_DROPS:
		var angle := TAU * i / INK_DROPS + 0.4 * sin(i * 2.3)
		var dir := Vector2(cos(angle) * 1.6, sin(angle))
		var reach := size.y * (0.45 + 0.5 * _ink * (0.6 + 0.4 * absf(sin(i * 1.7))))
		draw_circle(center + dir * reach, (3.0 + i % 3) * (1.0 - _ink * 0.5), c)


## The double frame of the mark.
func _draw_frame() -> void:
	var r := Rect2(Vector2.ZERO, mark.size)
	mark.draw_rect(r.grow(-2), _color, false, 4.0)
	mark.draw_rect(r.grow(-10), _color, false, 2.0)


func _draw_handle() -> void:
	var px := handle.size.x / HANDLE_ROWS[0].length()
	for y in HANDLE_ROWS.size():
		var row: String = HANDLE_ROWS[y]
		for x in row.length():
			var color: Color
			match row[x]:
				"w":
					color = WOOD
				"d":
					color = DARK
				"i":
					color = _color
				_:
					continue
			handle.draw_rect(Rect2(x * px, y * PIXEL, px + 0.5, PIXEL), color)
