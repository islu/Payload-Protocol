class_name FxLayer
extends Control
## Draws the effects on top of the hold (SPEC Section 21): the pixel art sheets of
## FxSheets, the force numbers, the glow on a blast area, and the white flash of an
## explosion. Each effect is {kind, at, t, time, ...}. Positions are local to this
## layer: in the warp, the layer covers the HoldView.

## The sheets of the effects (SPEC Section 21). Each has a file in res://art/fx.
const NAMES: PackedStringArray = [
	"hit", "break", "explosion", "leak", "short", "shield", "spoil", "coin"
]

## The font size of a force number.
const NUMBER_SIZE := 56
## The font size of a lost pay (SPEC Section 21.5).
const LOSS_SIZE := 40

var hold: HoldView
var speed := 1.0
## The names of the sheets that this layer played. The UI check reads it.
var played := {}
var _fx: Array = []
var _flash := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Pixel art: no smoothing (SPEC Section 4.2).
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## A hit at the contact edge. The direction of the flare is back into the hold
## (SPEC Section 21.2).
func spark(at: Vector2, direction: Vector2) -> void:
	_sheet("hit", at, direction.angle())


func number(at: Vector2, force: int) -> void:
	var color: Color = (
		Palette.TEXT_DIM if force == 0 else (Palette.BAD if force >= 3 else Palette.WARN)
	)
	_add({"kind": "number", "at": at, "time": 1.1, "color": color, "text": str(force)})


## The lost pay of a freight that becomes scrap, below the force number (SPEC Section 21.5).
func loss(at: Vector2, amount: int) -> void:
	played["loss"] = true
	_add(
		{
			"kind": "number",
			"at": at + Vector2(0, 50),
			"time": 1.4,
			"color": Palette.BAD,
			"text": "-%d" % amount,
			"size": LOSS_SIZE,
		}
	)


func shards(at: Vector2) -> void:
	_sheet("break", at)


func explosion(at: Vector2, cells: Array) -> void:
	_flash = 1.0
	_add(
		{
			"kind": "area",
			"at": at,
			"time": 0.5,
			"color": Palette.TRAIT_COLORS["volatile"],
			"cells": cells
		}
	)
	_sheet("explosion", at)


func leak(at: Vector2) -> void:
	_sheet("leak", at)


func bolts(at: Vector2) -> void:
	_sheet("short", at)


func bubble(at: Vector2) -> void:
	_sheet("shield", at)


func cloud(at: Vector2) -> void:
	_sheet("spoil", at)


## A gold sparkle at a point of the screen (SPEC Section 21.4).
func coin(global_at: Vector2) -> void:
	_sheet("coin", get_global_transform().affine_inverse() * global_at)


func _sheet(sheet_name: String, at: Vector2, angle := 0.0) -> void:
	var s := FxSheets.sheet(sheet_name)
	if s.is_empty():
		return
	played[sheet_name] = true
	_add({"kind": "sheet", "at": at, "time": FxSheets.seconds(s), "sheet": s, "angle": angle})


func _add(fx: Dictionary) -> void:
	fx["t"] = 0.0
	_fx.append(fx)


func _process(delta: float) -> void:
	for fx: Dictionary in _fx:
		fx["t"] += delta * speed
	_fx = _fx.filter(func(fx: Dictionary) -> bool: return fx["t"] < fx["time"])
	_flash = maxf(0.0, _flash - delta * speed * 4.0)
	queue_redraw()


func _draw() -> void:
	for fx: Dictionary in _fx:
		var k: float = fx["t"] / fx["time"]
		var at: Vector2 = fx["at"]
		match fx["kind"]:
			"sheet":
				_draw_sheet(fx)
			"number":
				var color: Color = fx["color"]
				color.a = 1.0 - k
				# Large digits with a dark outline, so that they read on each cargo color (SPEC Section 21.2).
				var font := get_theme_default_font()
				var font_size: int = fx.get("size", NUMBER_SIZE)
				var pos := at + Vector2(-font_size * 0.3, -24 - 70 * k)
				var outline := Color(Palette.BACKGROUND, color.a)
				var align := HORIZONTAL_ALIGNMENT_LEFT
				draw_string_outline(font, pos, fx["text"], align, -1, font_size, 10, outline)
				draw_string(font, pos, fx["text"], align, -1, font_size, color)
			"area":
				var color: Color = fx["color"]
				for c: Vector2i in fx["cells"]:
					var r := Rect2(
						hold.grid_origin() + Vector2(c) * hold.cell, Vector2.ONE * hold.cell
					)
					draw_rect(r, Color(color, 0.5 * (1.0 - k)))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	if _flash > 0.0:
		draw_rect(Rect2(-global_position, get_viewport_rect().size), Color(1, 1, 1, _flash * 0.6))


## Draws the frame of a sheet at the time of the effect. The pivot of the sheet is at the point.
func _draw_sheet(fx: Dictionary) -> void:
	var s: Dictionary = fx["sheet"]
	var frame := mini(int(fx["t"] * s["fps"]), s["frames"] - 1)
	var scale_by: float = s["scale"]
	draw_set_transform(fx["at"], fx["angle"], Vector2.ONE * scale_by)
	draw_texture_rect_region(s["texture"], Rect2(-s["pivot"], s["size"]), FxSheets.region(s, frame))
	draw_set_transform_matrix(Transform2D.IDENTITY)
