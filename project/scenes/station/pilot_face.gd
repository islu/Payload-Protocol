class_name PilotFace
extends Control
## The pixel art portrait of MAGELLAN in the pilot box (SPEC Section 22). It plays
## the idle loop, and the talk loop while a line types out.

## The sheets of the portrait in res://art/fx (task fx).
const SHEETS: PackedStringArray = ["pilot_idle", "pilot_talk"]

## True while a line types out: the mouth moves.
var talking := false
var _t := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _ready() -> void:
	var s := FxSheets.sheet(SHEETS[0])
	if not s.is_empty():
		custom_minimum_size = s["size"] * s["scale"]


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var s := FxSheets.sheet(SHEETS[1] if talking else SHEETS[0])
	if s.is_empty():
		return
	var frame := int(_t * s["fps"]) % int(s["frames"])
	var shown: Vector2 = s["size"] * s["scale"]
	var at := (size - shown) / 2.0
	draw_texture_rect_region(s["texture"], Rect2(at, shown), FxSheets.region(s, frame))
