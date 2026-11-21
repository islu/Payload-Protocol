class_name CargoDraw
## Draws a cargo shape with its color, its trait marks, its weight, and its clamp
## (SPEC Section 4.2). The hold, the dock, the contracts, and the drag use it.

## The floor color under the image of a cargo: it shows the cells (SPEC Section 4.2).
const FLOOR_ALPHA := 0.16


## Draws a cargo at a place. shape is a list of {x, y}. origin is the upper left
## of the cell (0, 0). alpha fades the cargo. A cargo with an image (CargoArt)
## shows a faint floor on its cells and the image over them. Other cargo shows a
## drawn shape (SPEC Section 4.2).
static func draw(
	canvas: CanvasItem, cargo: Dictionary, shape: Array, origin: Vector2, cell: float, alpha := 1.0
) -> void:
	var color := Palette.cargo_color(cargo)
	color.a *= alpha
	var gap := maxf(2.0, cell * 0.04)
	var cells := {}
	for c: Dictionary in shape:
		cells[Vector2i(int(c["x"]), int(c["y"]))] = true
	var scrap: bool = cargo.get("kind", "") == Defs.KIND_SCRAP
	var floor_color := Color(color, FLOOR_ALPHA * alpha)
	for c: Vector2i in cells:
		var r := Rect2(origin + Vector2(c) * cell, Vector2(cell, cell))
		# Fill the gap to a neighbor cell, so that one cargo reads as one piece.
		var grow_r := 0.0 if cells.has(c + Vector2i.RIGHT) else gap
		var grow_b := 0.0 if cells.has(c + Vector2i.DOWN) else gap
		var body := Rect2(
			r.position + Vector2(gap, gap), r.size - Vector2(gap + grow_r, gap + grow_b)
		)
		if cargo.has("def_id") and CargoArt.texture(cargo["def_id"]) != null:
			canvas.draw_rect(body, floor_color)
		else:
			canvas.draw_rect(body, color.darkened(0.55))
			canvas.draw_rect(body.grow(-1.5), color, false, 3.0)
	CargoArt.draw(
		canvas, cargo.get("def_id", ""), shape, origin, cell, scrap, Color(1, 1, 1, alpha)
	)
	if scrap:
		_draw_cracks(canvas, cells, origin, cell, Color(Palette.BAD.lerp(Color.WHITE, 0.3), alpha))
	var first := _first_cell(cells)
	var top_left := origin + Vector2(first) * cell
	if cell < 18.0:
		return
	# A badge with one icon for each trait, at the top left (SPEC Section 4.2).
	var traits: Array = cargo.get("traits", [])
	var icon := clampf(cell * 0.2, 8.0, 18.0)
	if not traits.is_empty():
		var badge := Rect2(
			top_left + Vector2(gap + 2, gap + 2), Vector2(traits.size() * (icon + 4) + 4, icon + 8)
		)
		canvas.draw_rect(badge, Color(Palette.BACKGROUND, 0.75 * alpha))
	var x := top_left.x + gap + 6 + icon / 2
	for t: String in traits:
		var mark_color: Color = Palette.trait_color(t)
		mark_color.a *= alpha
		draw_icon(canvas, t, Vector2(x, top_left.y + gap + 6 + icon / 2), icon, mark_color)
		x += icon + 4
	# The weight: one dot for each weight value, on a dark disc, at the bottom
	# right (SPEC Sections 4.2 and 6.1). The dots grow with the cell.
	var last := _last_cell(cells)
	var corner := origin + Vector2(last + Vector2i.ONE) * cell
	var dots: int = cargo.get("weight_value", 0)
	var r := clampf(cell * 0.045, 1.5, 5.0)
	for i in dots:
		var p := corner - Vector2(gap + r * 2.6 + i * r * 2.8, gap + r * 2.6)
		canvas.draw_circle(p, r * 1.5, Color(Palette.BACKGROUND, 0.8 * alpha))
		canvas.draw_circle(p, r, Color(Palette.TEXT, alpha))
	if cargo.get("clamped", false):
		canvas.draw_rect(clamp_rect(top_left, cell), Color(Palette.CLAMP, alpha))


## Draws the icon of a trait in a square of a size at a center.
static func draw_icon(
	canvas: CanvasItem, trait_id: String, at: Vector2, size: float, color: Color
) -> void:
	var h := size / 2.0
	match trait_id:
		Defs.TRAIT_FRAGILE:  # A glass: a cup on a stem
			canvas.draw_polyline(
				PackedVector2Array(
					[
						at + Vector2(-h * 0.7, -h),
						at + Vector2(-h * 0.4, 0),
						at + Vector2(h * 0.4, 0),
						at + Vector2(h * 0.7, -h)
					]
				),
				color,
				2.0
			)
			canvas.draw_line(at, at + Vector2(0, h * 0.8), color, 2.0)
			canvas.draw_line(at + Vector2(-h * 0.5, h), at + Vector2(h * 0.5, h), color, 2.0)
		Defs.TRAIT_VOLATILE:  # A burst: a star with 8 points
			var points := PackedVector2Array()
			for i in 16:
				var r := h if i % 2 == 0 else h * 0.45
				points.append(at + Vector2.from_angle(i * TAU / 16 - PI / 2) * r)
			canvas.draw_colored_polygon(points, color)
		Defs.TRAIT_FLUID:  # A drop
			canvas.draw_circle(at + Vector2(0, h * 0.25), h * 0.6, color)
			canvas.draw_colored_polygon(
				PackedVector2Array(
					[at + Vector2(0, -h), at + Vector2(h * 0.55, 0), at + Vector2(-h * 0.55, 0)]
				),
				color
			)
		Defs.TRAIT_ELECTRONIC:  # A bolt
			canvas.draw_colored_polygon(
				PackedVector2Array(
					[
						at + Vector2(h * 0.2, -h),
						at + Vector2(-h * 0.6, h * 0.15),
						at + Vector2(-h * 0.05, h * 0.15),
						at + Vector2(-h * 0.2, h),
						at + Vector2(h * 0.6, -h * 0.15),
						at + Vector2(h * 0.05, -h * 0.15)
					]
				),
				color
			)
		Defs.TRAIT_PERISHABLE:  # A leaf
			canvas.draw_colored_polygon(
				PackedVector2Array(
					[
						at + Vector2(-h, h),
						at + Vector2(-h * 0.6, -h * 0.4),
						at + Vector2(h, -h),
						at + Vector2(h * 0.4, h * 0.6)
					]
				),
				color
			)
		Defs.TRAIT_THRUSTER:  # Two chevrons
			for dx in [-h * 0.5, h * 0.3]:
				canvas.draw_polyline(
					PackedVector2Array(
						[
							at + Vector2(dx - h * 0.3, -h * 0.8),
							at + Vector2(dx + h * 0.3, 0),
							at + Vector2(dx - h * 0.3, h * 0.8)
						]
					),
					color,
					2.5
				)
		Defs.TRAIT_CUSHION:  # Two waves
			for dy in [-h * 0.35, h * 0.35]:
				var wave := PackedVector2Array()
				for i in 7:
					wave.append(
						at + Vector2(-h + i * h / 3.0, dy + (h * 0.25 if i % 2 == 0 else -h * 0.25))
					)
				canvas.draw_polyline(wave, color, 2.0)
		Defs.TRAIT_COOLER:  # A snowflake
			for i in 3:
				var d := Vector2.from_angle(i * PI / 3) * h
				canvas.draw_line(at - d, at + d, color, 2.0)
		Defs.TRAIT_BATTERY:  # A battery
			canvas.draw_rect(
				Rect2(at + Vector2(-h * 0.8, -h * 0.5), Vector2(h * 1.4, h)), color, false, 2.0
			)
			canvas.draw_rect(
				Rect2(at + Vector2(h * 0.6, -h * 0.2), Vector2(h * 0.3, h * 0.4)), color
			)
			canvas.draw_rect(
				Rect2(at + Vector2(-h * 0.6, -h * 0.3), Vector2(h * 0.6, h * 0.6)), color
			)
		Defs.TRAIT_SHIELD:  # A shield
			canvas.draw_colored_polygon(
				PackedVector2Array(
					[
						at + Vector2(-h * 0.8, -h),
						at + Vector2(h * 0.8, -h),
						at + Vector2(h * 0.8, 0),
						at + Vector2(0, h),
						at + Vector2(-h * 0.8, 0)
					]
				),
				color
			)
		_:
			canvas.draw_circle(at, h * 0.5, color)


## The rect of the clamp mark of a cargo: a click on it takes the clamp off (SPEC Section 13).
static func clamp_rect(top_left: Vector2, cell: float) -> Rect2:
	return Rect2(top_left + Vector2(cell - 22, 6), Vector2(14, 14))


static func _first_cell(cells: Dictionary) -> Vector2i:
	var best := Vector2i(1 << 20, 1 << 20)
	for c: Vector2i in cells:
		if c.y < best.y or (c.y == best.y and c.x < best.x):
			best = c
	return best


## The cell at the bottom right of a shape: the last row, the last cell in it.
static func _last_cell(cells: Dictionary) -> Vector2i:
	var best := Vector2i(-1, -1)
	for c: Vector2i in cells:
		if c.y > best.y or (c.y == best.y and c.x > best.x):
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
