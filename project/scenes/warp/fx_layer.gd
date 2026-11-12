class_name FxLayer
extends Control
## Draws the effects of the warp on top of the hold (SPEC Section 21): sparks,
## force numbers, shards, explosions, leaks, bolts, shields, and spoil clouds.
## Each effect is {kind, at, t, time, color, text, cells, parts}. Positions are
## local to the HoldView.

var hold: HoldView
var speed := 1.0
var _fx: Array = []
var _flash := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func spark(at: Vector2, force: int) -> void:
	var parts := []
	for i in 6 + mini(force, 12):
		parts.append(
			Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(40, 120 + force * 12)
		)
	_add({"kind": "spark", "at": at, "time": 0.35, "color": Palette.WARN, "parts": parts})


func number(at: Vector2, force: int) -> void:
	var color: Color = (
		Palette.TEXT_DIM if force == 0 else (Palette.BAD if force >= 3 else Palette.WARN)
	)
	_add({"kind": "number", "at": at, "time": 0.9, "color": color, "text": str(force)})


func shards(at: Vector2, color: Color) -> void:
	var parts := []
	for i in 14:
		parts.append(Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(60, 200))
	_add({"kind": "shards", "at": at, "time": 0.6, "color": color, "parts": parts})


func explosion(at: Vector2, cells: Array) -> void:
	_flash = 1.0
	_add({"kind": "ring", "at": at, "time": 0.6, "color": Palette.TRAIT_COLORS["volatile"]})
	_add(
		{
			"kind": "area",
			"at": at,
			"time": 0.5,
			"color": Palette.TRAIT_COLORS["volatile"],
			"cells": cells
		}
	)
	shards(at, Palette.WARN)


func leak(at: Vector2) -> void:
	var parts := []
	for i in 10:
		parts.append(Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(20, HoldView.CELL))
	_add(
		{
			"kind": "leak",
			"at": at,
			"time": 0.9,
			"color": Palette.TRAIT_COLORS["fluid"],
			"parts": parts
		}
	)


func bolts(at: Vector2) -> void:
	_add({"kind": "bolts", "at": at, "time": 0.5, "color": Palette.TRAIT_COLORS["electronic"]})


func bubble(at: Vector2) -> void:
	_add({"kind": "bubble", "at": at, "time": 0.6, "color": Palette.TRAIT_COLORS["shield"]})


func cloud(at: Vector2) -> void:
	_add({"kind": "cloud", "at": at, "time": 1.0, "color": Palette.TRAIT_COLORS["perishable"]})


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
		var color: Color = fx["color"]
		color.a = 1.0 - k
		var at: Vector2 = fx["at"]
		match fx["kind"]:
			"spark":
				for p: Vector2 in fx["parts"]:
					draw_line(at + p * k * 0.6, at + p * k, color, 2.0)
			"number":
				var font := ThemeDB.fallback_font
				draw_string(
					font,
					at + Vector2(-10, -30 - 50 * k),
					fx["text"],
					HORIZONTAL_ALIGNMENT_LEFT,
					-1,
					34,
					color
				)
			"shards":
				for p: Vector2 in fx["parts"]:
					var q := at + p * k + Vector2(0, 160 * k * k)
					draw_colored_polygon(
						PackedVector2Array([q, q + Vector2(6, 2), q + Vector2(2, 7)]), color
					)
			"ring":
				draw_arc(at, 20 + 160 * k, 0, TAU, 48, color, 6.0 * (1.0 - k) + 1.0)
			"area":
				for c: Vector2i in fx["cells"]:
					var r := Rect2(
						hold.grid_origin() + Vector2(c) * HoldView.CELL, Vector2.ONE * HoldView.CELL
					)
					draw_rect(r, Color(color, 0.5 * (1.0 - k)))
			"leak":
				for p: Vector2 in fx["parts"]:
					draw_circle(at + p * minf(1.0, k * 2.0), 10.0, Color(color, 0.6 * (1.0 - k)))
			"bolts":
				for i in 4:
					var a := at + Vector2.from_angle(i * TAU / 4 + k * 3.0) * 10.0
					var b := a + Vector2.from_angle(i * TAU / 4 + 0.7) * 40.0
					draw_polyline(
						PackedVector2Array([a, (a + b) / 2 + Vector2(8, -6), b]), color, 2.0
					)
			"bubble":
				draw_circle(at, HoldView.CELL * 0.6, Color(color, 0.25 * (1.0 - k)))
				draw_arc(at, HoldView.CELL * 0.6, 0, TAU, 40, color, 3.0)
			"cloud":
				for i in 5:
					draw_circle(
						at + Vector2(i * 14 - 28, -20 * k - (i % 2) * 10),
						16.0 + 8 * k,
						Color(color, 0.5 * (1.0 - k))
					)
	if _flash > 0.0:
		draw_rect(Rect2(-global_position, get_viewport_rect().size), Color(1, 1, 1, _flash * 0.6))
