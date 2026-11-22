class_name ModIcon
extends Control
## The icon of a mod (SPEC Sections 20.2 and 20.9): simple lines in one color. The
## mod bar and the mod choice show the same icon.

const ICONS: PackedStringArray = [
	Defs.MOD_SHOCK_FLOOR,
	Defs.MOD_CRYO_LINE,
	Defs.MOD_PADDED_WALLS,
	Defs.MOD_GRAVITY_DAMPER,
	Defs.MOD_ARRAY_POWER,
	Defs.MOD_INSURANCE,
	Defs.MOD_BLAST_DOORS,
	Defs.MOD_SEALED_WIRING,
	Defs.MOD_SALVAGE_ARM,
	Defs.MOD_TRADE_LICENSE,
]

var mod := ""
var color := Palette.ACCENT


func _init(mod_id := "", icon_size := 32.0) -> void:
	mod = mod_id
	custom_minimum_size = Vector2(icon_size, icon_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


static func has_icon(mod_id: String) -> bool:
	return mod_id in ICONS


func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := size / 2.0
	var k := s / 32.0
	var w := 2.5 * k
	match mod:
		Defs.MOD_SHOCK_FLOOR:
			# A floor on springs.
			draw_line(c + Vector2(-12, 10) * k, c + Vector2(12, 10) * k, color, w * 1.4)
			for x: float in [-8.0, 0.0, 8.0]:
				var pts := PackedVector2Array()
				for i in 5:
					pts.append(c + Vector2(x + (3.0 if i % 2 == 1 else -3.0), -10 + i * 4.5) * k)
				draw_polyline(pts, color, w)
		Defs.MOD_CRYO_LINE:
			# A snowflake.
			for i in 3:
				var d := Vector2.from_angle(i * PI / 3.0) * 12.0 * k
				draw_line(c - d, c + d, color, w)
			draw_circle(c, 2.5 * k, color)
		Defs.MOD_PADDED_WALLS:
			# A wall with soft pads.
			draw_line(c + Vector2(-12, -12) * k, c + Vector2(-12, 12) * k, color, w * 1.6)
			for y: float in [-8.0, 0.0, 8.0]:
				draw_circle(c + Vector2(-4, y) * k, 3.5 * k, color)
		Defs.MOD_GRAVITY_DAMPER:
			# A weight that goes down slowly.
			draw_rect(Rect2(c + Vector2(-7, -12) * k, Vector2(14, 9) * k), color)
			draw_line(c + Vector2(0, -2) * k, c + Vector2(0, 10) * k, color, w)
			draw_line(c + Vector2(-5, 5) * k, c + Vector2(0, 10) * k, color, w)
			draw_line(c + Vector2(5, 5) * k, c + Vector2(0, 10) * k, color, w)
			draw_line(c + Vector2(-10, 13) * k, c + Vector2(10, 13) * k, color, w)
		Defs.MOD_ARRAY_POWER:
			# A bolt with rings of range.
			var bolt := PackedVector2Array(
				[
					c + Vector2(2, -12) * k,
					c + Vector2(-5, 1) * k,
					c + Vector2(0, 1) * k,
					c + Vector2(-2, 12) * k,
					c + Vector2(5, -2) * k,
					c + Vector2(0, -2) * k,
				]
			)
			draw_colored_polygon(bolt, color)
			draw_arc(c, 14.0 * k, -0.6, 0.6, 8, color, w * 0.8)
			draw_arc(c, 14.0 * k, PI - 0.6, PI + 0.6, 8, color, w * 0.8)
		Defs.MOD_INSURANCE:
			# A shield with a check mark.
			var shield := PackedVector2Array(
				[
					c + Vector2(-10, -11) * k,
					c + Vector2(10, -11) * k,
					c + Vector2(10, 1) * k,
					c + Vector2(0, 12) * k,
					c + Vector2(-10, 1) * k,
					c + Vector2(-10, -11) * k,
				]
			)
			draw_polyline(shield, color, w)
			draw_polyline(
				PackedVector2Array(
					[c + Vector2(-5, -1) * k, c + Vector2(-1, 4) * k, c + Vector2(6, -5) * k]
				),
				color,
				w
			)
		Defs.MOD_BLAST_DOORS:
			# A plus of four doors: the blast goes only up, down, left, and right.
			draw_circle(c, 3.5 * k, color)
			for d: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
				draw_line(c + d * 6.0 * k, c + d * 13.0 * k, color, w)
			for d: Vector2 in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
				var p := c + d * 9.0 * k
				draw_line(p - d.orthogonal() * 3.0 * k, p + d.orthogonal() * 3.0 * k, color, w)
		Defs.MOD_SEALED_WIRING:
			# A drop above a wire with a seal.
			var drop := PackedVector2Array(
				[c + Vector2(0, -13) * k, c + Vector2(5, -4) * k, c + Vector2(-5, -4) * k]
			)
			draw_colored_polygon(drop, color)
			draw_circle(c + Vector2(0, -4) * k, 5.0 * k, color)
			draw_line(c + Vector2(-13, 9) * k, c + Vector2(13, 9) * k, color, w)
			draw_rect(Rect2(c + Vector2(-5, 5) * k, Vector2(10, 8) * k), color, false, w)
		Defs.MOD_SALVAGE_ARM:
			# A claw of a crane.
			draw_line(c + Vector2(-12, -12) * k, c + Vector2(0, -12) * k, color, w)
			draw_line(c + Vector2(0, -12) * k, c + Vector2(0, 0) * k, color, w)
			draw_polyline(
				PackedVector2Array(
					[c + Vector2(-8, 10) * k, c + Vector2(-6, 2) * k, c + Vector2(0, 0) * k]
				),
				color,
				w
			)
			draw_polyline(
				PackedVector2Array(
					[c + Vector2(8, 10) * k, c + Vector2(6, 2) * k, c + Vector2(0, 0) * k]
				),
				color,
				w
			)
		Defs.MOD_TRADE_LICENSE:
			# A price tag.
			var tag := PackedVector2Array(
				[
					c + Vector2(-12, -4) * k,
					c + Vector2(-4, -12) * k,
					c + Vector2(12, -12) * k,
					c + Vector2(12, 12) * k,
					c + Vector2(-4, 12) * k,
					c + Vector2(-12, 4) * k,
					c + Vector2(-12, -4) * k,
				]
			)
			draw_polyline(tag, color, w)
			draw_circle(c + Vector2(-5, 0) * k, 2.5 * k, color)
			draw_line(c + Vector2(2, -5) * k, c + Vector2(8, -5) * k, color, w)
			draw_line(c + Vector2(2, 5) * k, c + Vector2(8, 5) * k, color, w)
