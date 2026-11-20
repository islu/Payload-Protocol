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
## The times of the effects of an incident, at 1× speed (SPEC Section 29.3).
const METEOR_TIME := 0.4
const WAVE_TIME := 0.6
const CRACK_TIME := 0.5
## The strength of the flash of the warp start: an explosion has 1 (SPEC Section 20.3).
const JUMP_FLASH := 0.35
const METEOR_COLOR := Color("ffb347")
const WAVE_COLOR := Color("5fd3ff")  # Palette.ACCENT

var hold: HoldView
var speed := 1.0
## The names of the sheets and the drawn effects that this layer played. The UI
## check reads it.
var played := {}
## The number of coins that flew to the report (SPEC Section 20.4).
var coin_flights := 0
var _fx: Array = []
var _flash := 0.0
## True while the layer shows an effect or the flash.
var _drawn := false


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
			"color": Palette.TRAIT_COLORS[Defs.TRAIT_VOLATILE],
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


## A fireball that falls down a column from the top bulkhead. It stops at the top of
## the cell in stop_row: the top cargo, or the floor when stop_row is the row count
## (SPEC Section 29.3).
func meteor(column: int, stop_row: int) -> void:
	played["meteor"] = true
	var x := hold.grid_origin().x + (column + 0.5) * hold.cell
	var from := Vector2(x, hold.grid_origin().y - HoldView.FRAME)
	var to := Vector2(x, hold.grid_origin().y + stop_row * hold.cell)
	_add({"kind": "meteor", "at": to, "from": from, "time": METEOR_TIME})


## A cyan wave that moves along a row from left to right (SPEC Section 29.3).
func wave(row: int) -> void:
	played["wave"] = true
	var o := hold.grid_origin()
	var band := Rect2(o + Vector2(0, row * hold.cell), Vector2(hold.columns, 1) * hold.cell)
	_add({"kind": "wave", "at": band.position, "band": band, "time": WAVE_TIME})


## The deck plate of a cell cracks, and dust sprays out (SPEC Section 29.3).
func crack(cell: Vector2i) -> void:
	played["crack"] = true
	var at := hold.grid_origin() + (Vector2(cell) + Vector2(0.5, 0.5)) * hold.cell
	# The crack draws over the shards.
	_sheet("break", at)
	_add({"kind": "crack", "at": at, "time": CRACK_TIME})


## The start of the warp: a soft white flash, about a third of the flash of an
## explosion. The warp screen stretches the stars (SPEC Section 20.3).
func jump() -> void:
	played["jump"] = true
	_flash = JUMP_FLASH
	_drawn = true


## A coin that flies from a point of the screen to a control, after a delay. on_arrive
## runs when it arrives (SPEC Section 20.4).
func coin_fly(global_from: Vector2, target: Control, delay: float, on_arrive: Callable) -> void:
	coin_flights += 1
	var fx := {"kind": "coin_fly", "at": _local(global_from), "target": target, "time": 0.6}
	fx["arrive"] = on_arrive
	_add(fx)
	fx["t"] = -delay


## A small image of a cargo that flies from a point of the screen to a control: the
## freight of an accepted contract flies to the dock (SPEC Section 21.1).
func cargo_fly(global_from: Vector2, target: Control, cargo: Dictionary) -> void:
	played["fly"] = true
	_add(
		{
			"kind": "cargo_fly",
			"at": _local(global_from),
			"target": target,
			"cargo": cargo,
			"time": 0.35
		}
	)


## A puff of gray smoke that rises from a cargo that becomes scrap (SPEC Section 21.5).
func smoke(at: Vector2) -> void:
	played["smoke"] = true
	_add({"kind": "smoke", "at": at, "time": 0.9})


func _local(global_at: Vector2) -> Vector2:
	return get_global_transform().affine_inverse() * global_at


## The center of a target control in local coordinates.
func _target_at(fx: Dictionary) -> Vector2:
	var target: Variant = fx["target"]
	if not is_instance_valid(target):
		return fx["at"]
	return _local((target as Control).get_global_rect().get_center())


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
	if _fx.is_empty() and _flash <= 0.0 and not _drawn:
		return
	for fx: Dictionary in _fx:
		fx["t"] += delta * speed
		if fx["t"] >= fx["time"] and fx.has("arrive"):
			var arrive: Callable = fx["arrive"]
			fx.erase("arrive")
			arrive.call()
	_fx = _fx.filter(func(fx: Dictionary) -> bool: return fx["t"] < fx["time"])
	_flash = maxf(0.0, _flash - delta * speed * 4.0)
	# One more redraw after the last effect clears the layer.
	_drawn = not _fx.is_empty() or _flash > 0.0
	queue_redraw()


func _draw() -> void:
	for fx: Dictionary in _fx:
		if fx["t"] < 0.0:
			continue
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
			"meteor":
				_draw_meteor(fx["from"], at, k)
			"wave":
				_draw_wave(fx["band"], k)
			"crack":
				_draw_crack(at, k)
			"coin_fly":
				_draw_coin(at, _target_at(fx), k)
			"cargo_fly":
				var p := at.lerp(_target_at(fx), 1.0 - pow(1.0 - k, 2.0))
				var c: Dictionary = fx["cargo"]
				var cell := 24.0
				var box := Vector2(CargoDraw.shape_size(c["shape"])) * cell
				CargoDraw.draw(self, c, c["shape"], p - box / 2.0, cell, 1.0 - 0.3 * k)
			"smoke":
				_draw_smoke(at, k)
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


## The fireball: a bright head and a trail behind it.
func _draw_meteor(from: Vector2, to: Vector2, k: float) -> void:
	var head := from.lerp(to, k * k)
	var trail := maxf(0.0, k * k - 0.45)
	# The fireball is about half a cell wide, so that it reads at a glance.
	draw_line(from.lerp(to, trail), head, Color(METEOR_COLOR, 0.35), 34.0)
	draw_line(from.lerp(to, trail), head, Color(METEOR_COLOR, 0.6), 20.0)
	draw_line(from.lerp(to, (trail + k * k) / 2.0), head, Color(1, 0.9, 0.6, 0.85), 9.0)
	draw_circle(head, 40.0, Color(METEOR_COLOR, 0.25))
	draw_circle(head, 28.0, Color(METEOR_COLOR, 0.7))
	draw_circle(head, 17.0, Color(1, 0.95, 0.8))


## The wave: a glow on the row, and a bright front that moves from left to right.
func _draw_wave(band: Rect2, k: float) -> void:
	var x := band.position.x + band.size.x * k
	draw_rect(
		Rect2(band.position, Vector2(x - band.position.x, band.size.y)), Color(WAVE_COLOR, 0.12)
	)
	for i in 3:
		var w := x - i * 14.0
		if w >= band.position.x:
			var a := 0.9 - i * 0.3
			draw_line(
				Vector2(w, band.position.y), Vector2(w, band.end.y), Color(WAVE_COLOR, a), 4.0
			)


## The crack: jagged lines from the middle of the cell, and dust that spreads.
func _draw_crack(at: Vector2, k: float) -> void:
	var fade := 1.0 - k
	var dark := Color(Palette.BACKGROUND, fade)
	var rim := Color(Palette.TEXT, 0.8 * fade)
	draw_circle(at, 9.0, dark)
	for i in 5:
		var angle := i * TAU / 5.0 + 0.4
		var mid := at + Vector2.from_angle(angle) * 18.0 + Vector2.from_angle(angle + 1.2) * 6.0
		var tip := at + Vector2.from_angle(angle) * 40.0
		var line := PackedVector2Array([at, mid, tip])
		# A light rim, so that the crack reads on the dark plate.
		draw_polyline(line, rim, 6.0)
		draw_polyline(line, dark, 3.0)
	for i in 8:
		var p := at + Vector2.from_angle(i * TAU / 8.0) * (10.0 + 40.0 * k)
		draw_circle(p, 6.0 * fade + 1.0, Color(Palette.PLAIN, 0.5 * fade))


## A coin on an arc from a point to its target.
func _draw_coin(from: Vector2, to: Vector2, k: float) -> void:
	var e := k * k * (3.0 - 2.0 * k)
	var p := from.lerp(to, e) + Vector2(0, -80.0 * sin(PI * k))
	draw_circle(p, 11.0, Palette.TITLE_AMBER.darkened(0.3))
	draw_circle(p, 8.0, Palette.TITLE_AMBER)
	draw_circle(p + Vector2(-2, -2), 3.0, Color(1, 1, 0.85))


## Gray puffs that rise, grow, and fade.
func _draw_smoke(at: Vector2, k: float) -> void:
	var fade := 1.0 - k
	for i in 5:
		var side := (i - 2) * 9.0
		var p := at + Vector2(side + 6.0 * sin(k * 6.0 + i), -20.0 - 60.0 * k - i * 6.0)
		draw_circle(p, 10.0 + 14.0 * k, Color(Palette.PLAIN, 0.45 * fade))
