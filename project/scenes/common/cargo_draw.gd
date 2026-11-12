class_name CargoDraw
## Draws a cargo shape with its color, its trait marks, its weight, and its clamp
## (SPEC Section 4.2). The hold, the dock, the contracts, and the drag use it.

const FONT_SIZE := 13


## Draws a cargo at a place. shape is a list of {x, y}. origin is the upper left
## of the cell (0, 0). alpha fades the cargo.
static func draw(
	canvas: CanvasItem, cargo: Dictionary, shape: Array, origin: Vector2, cell: float, alpha := 1.0
) -> void:
	var color := Palette.cargo_color(cargo)
	color.a *= alpha
	var gap := maxf(2.0, cell * 0.04)
	var cells := {}
	for c: Dictionary in shape:
		cells[Vector2i(int(c["x"]), int(c["y"]))] = true
	for c: Vector2i in cells:
		var r := Rect2(origin + Vector2(c) * cell, Vector2(cell, cell))
		# Fill the gap to a neighbor cell, so that one cargo reads as one piece.
		var grow_r := 0.0 if cells.has(c + Vector2i.RIGHT) else gap
		var grow_b := 0.0 if cells.has(c + Vector2i.DOWN) else gap
		var body := Rect2(
			r.position + Vector2(gap, gap), r.size - Vector2(gap + grow_r, gap + grow_b)
		)
		canvas.draw_rect(body, color.darkened(0.55))
		canvas.draw_rect(body, color, false, 2.0)
	if cargo.get("kind", "") == Defs.KIND_SCRAP:
		_draw_cracks(canvas, cells, origin, cell, color)
	var first := _first_cell(cells)
	var top_left := origin + Vector2(first) * cell
	if cell < 30.0:
		return
	var font := ThemeDB.fallback_font
	var y := top_left.y + gap + FONT_SIZE + 2
	for t: String in cargo.get("traits", []):
		var mark_color: Color = Palette.TRAIT_COLORS.get(t, Palette.TEXT)
		mark_color.a *= alpha
		canvas.draw_string(
			font,
			Vector2(top_left.x + gap + 4, y),
			Palette.TRAIT_MARKS.get(t, t),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			FONT_SIZE,
			mark_color
		)
		y += FONT_SIZE + 1
	# The weight: one dot for each weight value (SPEC Section 6.1).
	var dots: int = cargo.get("weight_value", 0)
	for i in dots:
		var p := top_left + Vector2(cell - gap - 8 - i * 9, cell - gap - 8)
		canvas.draw_circle(p, 3.0, Color(Palette.TEXT, alpha))
	if cargo.get("clamped", false):
		canvas.draw_rect(clamp_rect(top_left, cell), Color(Palette.CLAMP, alpha))


## The rect of the clamp mark of a cargo: a click on it takes the clamp off (SPEC Section 13).
static func clamp_rect(top_left: Vector2, cell: float) -> Rect2:
	return Rect2(top_left + Vector2(cell - 22, 6), Vector2(14, 14))


static func _first_cell(cells: Dictionary) -> Vector2i:
	var best := Vector2i(1 << 20, 1 << 20)
	for c: Vector2i in cells:
		if c.y < best.y or (c.y == best.y and c.x < best.x):
			best = c
	return best


static func _draw_cracks(
	canvas: CanvasItem, cells: Dictionary, origin: Vector2, cell: float, color: Color
) -> void:
	for c: Vector2i in cells:
		var p := origin + Vector2(c) * cell
		canvas.draw_line(
			p + Vector2(cell * 0.2, cell * 0.25), p + Vector2(cell * 0.55, cell * 0.6), color, 1.5
		)
		canvas.draw_line(
			p + Vector2(cell * 0.55, cell * 0.6), p + Vector2(cell * 0.8, cell * 0.45), color, 1.5
		)


## Returns the cells of a shape as the size in cells.
static func shape_size(shape: Array) -> Vector2i:
	var s := Vector2i.ZERO
	for c: Dictionary in shape:
		s = Vector2i(maxi(s.x, int(c["x"]) + 1), maxi(s.y, int(c["y"]) + 1))
	return s
