class_name HoldView
extends Control
## Draws the hold: the grid, the cargo, the links, the clamps, a zone, and the
## preview of a drop (SPEC Sections 8.3, 12.3, and 20.2). It reads the view only.

## A press on a cargo in the hold: the left button starts a drag, the right button rotates.
signal cargo_pressed(id: int, grab: Vector2i, button: int)
## A press on the clamp mark of a cargo (SPEC Section 13).
signal clamp_pressed(id: int)
## The mouse is on a cargo, or on no cargo (id -1).
signal cargo_hovered(id: int)

## The size of a cell grows to fill the free space, between these values (SPEC Section 20.2).
const MIN_CELL := 84.0
const MAX_CELL := 128.0
## The free space around the grid, in cells: the marks of the front wall are there.
const MARGIN := 0.8
## The width of the frame around the grid, in pixels.
const FRAME := 14.0

## The size of a cell in pixels now.
var cell := MIN_CELL

var columns := 6
var rows := 6
var cargo: Array = []
var links: Array = []
## The cells to mark: the zone of a bonus, or the freight of a contract.
var zone: Array = []
var marked: Array = []
## The preview of a drop: {cells: [Vector2i], ok: bool}, or empty.
var preview: Dictionary = {}
## The ID of the cargo that the player drags. It shows faded in its old place.
var dragging := -1
## The front walls to mark: the wall of the first shift step, or of the step under
## the mouse (SPEC Sections 12.3 and 20.2).
var front_walls := PackedStringArray()
## The wall jolt warnings show only for the first shift step (SPEC Section 12.3).
var show_jolts := true
## The offset of each cargo from its cell, in cells, by ID. The warp tweens it to 0.
var offsets: Dictionary = {}
## The fade of each cargo, by ID (1 is opaque). The arrival fades out delivered freight.
var fades: Dictionary = {}

var _hover := -1


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_view(run: Dictionary) -> void:
	columns = run["hold"]["columns"]
	rows = run["hold"]["rows"]
	cargo = run["cargo"]
	links = run["links"]
	front_walls = PackedStringArray([run.get("front_wall", "")])
	show_jolts = true
	custom_minimum_size = Vector2(columns + MARGIN, rows + MARGIN) * MIN_CELL
	_fit()
	queue_redraw()


## Marks front walls. jolts shows the wall jolt warnings (SPEC Section 20.2).
func show_front_walls(walls: PackedStringArray, jolts: bool) -> void:
	front_walls = walls
	show_jolts = jolts
	queue_redraw()


## Sets the size of a cell from the size of the view.
func _fit() -> void:
	var fit := minf(size.x / (columns + MARGIN), size.y / (rows + MARGIN))
	cell = clampf(floorf(fit), MIN_CELL, MAX_CELL)
	queue_redraw()


## Returns the upper left of the grid in local coordinates. The grid is centered.
func grid_origin() -> Vector2:
	return ((size - Vector2(columns, rows) * cell) / 2.0).floor()


## Returns the cell at a global position, also outside the grid.
func cell_at(global_pos: Vector2) -> Vector2i:
	var local := global_pos - global_position - grid_origin()
	return Vector2i(floori(local.x / cell), floori(local.y / cell))


## Returns the cell of the upper left of a shape when the player holds it at a
## global position. The shape snaps to the nearest cell (SPEC Section 8.3).
func snap_origin(global_pos: Vector2, grab: Vector2) -> Vector2i:
	var local := global_pos - global_position - grid_origin() - grab * cell
	return Vector2i(roundi(local.x / cell), roundi(local.y / cell))


func is_over(global_pos: Vector2) -> bool:
	return (
		Rect2(global_position + grid_origin(), Vector2(columns, rows) * cell)
		. grow(cell * 0.5)
		. has_point(global_pos)
	)


## Returns the ID of the cargo in a cell, or -1.
func cargo_at(at: Vector2i) -> int:
	for c: Dictionary in cargo:
		if not c["in_hold"]:
			continue
		for s: Dictionary in c["shape"]:
			if Vector2i(c["x"] + s["x"], c["y"] + s["y"]) == at:
				return c["id"]
	return -1


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var id := cargo_at(cell_at(get_global_mouse_position()))
		if id != _hover:
			_hover = id
			cargo_hovered.emit(id)
	elif event is InputEventMouseButton and event.pressed:
		var at := cell_at(get_global_mouse_position())
		var id := cargo_at(at)
		if id < 0:
			return
		var c := _cargo(id)
		var top_left := grid_origin() + Vector2(c["x"], c["y"]) * cell + _first_cell_offset(c)
		if c["clamped"] and event.button_index == MOUSE_BUTTON_LEFT:
			if CargoDraw.clamp_rect(top_left, cell).grow(4).has_point(get_local_mouse_position()):
				clamp_pressed.emit(id)
				accept_event()
				return
		cargo_pressed.emit(id, at - Vector2i(c["x"], c["y"]), event.button_index)
		accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_fit()
	if what == NOTIFICATION_MOUSE_EXIT and _hover != -1:
		_hover = -1
		cargo_hovered.emit(-1)


func _cargo(id: int) -> Dictionary:
	for c: Dictionary in cargo:
		if c["id"] == id:
			return c
	return {}


func _first_cell_offset(c: Dictionary) -> Vector2:
	var best := Vector2i(1 << 20, 1 << 20)
	for s: Dictionary in c["shape"]:
		var v := Vector2i(s["x"], s["y"])
		if v.y < best.y or (v.y == best.y and v.x < best.x):
			best = v
	return Vector2(best) * cell


func _draw() -> void:
	var o := grid_origin()
	_draw_frame(o)
	for y in rows:
		for x in columns:
			var r := Rect2(o + Vector2(x, y) * cell, Vector2(cell, cell))
			draw_rect(r, Palette.GRID)
			draw_rect(r, Palette.GRID_LINE, false, 1.0)
	for z: Dictionary in zone:
		draw_rect(Rect2(o + Vector2(z["x"], z["y"]) * cell, Vector2(cell, cell)), Palette.ZONE)
	for c: Dictionary in cargo:
		if c["in_hold"]:
			var alpha: float = 0.3 if c["id"] == dragging else fades.get(c["id"], 1.0)
			if alpha <= 0.0:
				continue
			var off: Vector2 = offsets.get(c["id"], Vector2.ZERO)
			var at := o + (Vector2(c["x"], c["y"]) + off) * cell
			CargoDraw.draw(self, c, c["shape"], at, cell, alpha)
			if c.get("no_cooler", false) or c.get("no_power", false):
				_draw_warning(at + _first_cell_offset(c))
			if show_jolts and c.get("jolt_risk", false):
				_draw_jolt(at + _first_cell_offset(c))
	for id: int in marked:
		var c := _cargo(id)
		if not c.is_empty() and c["in_hold"]:
			for s: Dictionary in c["shape"]:
				draw_rect(
					(
						Rect2(
							o + Vector2(c["x"] + s["x"], c["y"] + s["y"]) * cell,
							Vector2(cell, cell)
						)
						. grow(-3)
					),
					Palette.ACCENT,
					false,
					3.0
				)
	for wall in front_walls:
		_draw_front_wall(o, wall)
	_draw_links(o)
	if not preview.is_empty():
		_draw_preview_links(o)
		var color: Color = Palette.GOOD if preview["ok"] else Palette.BAD
		for p: Vector2i in preview["cells"]:
			var r := Rect2(o + Vector2(p) * cell, Vector2(cell, cell)).grow(-2)
			draw_rect(r, Color(color, 0.25))
			draw_rect(r, color, false, 2.0)


func _draw_links(o: Vector2) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for l: Dictionary in links:
		var a := _cargo(l["from"])
		var b := _cargo(l["to"])
		if a.is_empty() or b.is_empty():
			continue
		var color: Color = (
			Palette.TRAIT_COLORS["cooler"]
			if l["kind"] == Defs.LINK_COLD
			else Palette.TRAIT_COLORS["battery"]
		)
		color.a = 0.6 + 0.3 * sin(t * 3.0)
		draw_line(o + _center(a), o + _center(b), color, 3.0)


## Draws the links that the drop would make, from the preview cells (SPEC Section 8.3).
func _draw_preview_links(o: Vector2) -> void:
	var sum := Vector2.ZERO
	for p: Vector2i in preview["cells"]:
		sum += Vector2(p) + Vector2(0.5, 0.5)
	var at: Vector2 = sum / preview["cells"].size() * cell
	for l: Dictionary in preview.get("links", []):
		var other_id: int = l["to"] if l["from"] == preview["id"] else l["from"]
		var other := _cargo(other_id)
		if other.is_empty():
			continue
		var color: Color = (
			Palette.TRAIT_COLORS["cooler"]
			if l["kind"] == Defs.LINK_COLD
			else Palette.TRAIT_COLORS["battery"]
		)
		draw_dashed_line(o + at, o + _center(other), color, 3.0, 10.0)


func _center(c: Dictionary) -> Vector2:
	var sum := Vector2.ZERO
	for s: Dictionary in c["shape"]:
		sum += Vector2(c["x"] + s["x"], c["y"] + s["y"]) + Vector2(0.5, 0.5)
	return sum / c["shape"].size() * cell


## Draws the frame of the hold: metal plates with a rivet at each cell line (SPEC Section 4.2).
func _draw_frame(o: Vector2) -> void:
	var grid := Rect2(o, Vector2(columns, rows) * cell)
	var outer := grid.grow(FRAME)
	draw_rect(outer, Palette.PANEL_LINE.darkened(0.35))
	draw_rect(outer, Palette.PANEL_LINE, false, 2.0)
	draw_rect(grid.grow(2), Palette.BACKGROUND)
	var rivet := Palette.PANEL_LINE.lightened(0.25)
	var mid := FRAME / 2.0
	for x in columns + 1:
		var px := o.x + x * cell
		draw_circle(Vector2(px, grid.position.y - mid), 2.5, rivet)
		draw_circle(Vector2(px, grid.end.y + mid), 2.5, rivet)
	for y in rows + 1:
		var py := o.y + y * cell
		draw_circle(Vector2(grid.position.x - mid, py), 2.5, rivet)
		draw_circle(Vector2(grid.end.x + mid, py), 2.5, rivet)


## Draws the front wall: a band of yellow and black stripes on the frame, and
## arrows out of it (SPEC Section 12.3).
func _draw_front_wall(o: Vector2, front_wall: String) -> void:
	if front_wall == "":
		return
	var w := columns * cell
	var h := rows * cell
	var a := o
	var b := o
	match front_wall:
		Defs.DIR_LEFT:
			b = o + Vector2(0, h)
		Defs.DIR_RIGHT:
			a = o + Vector2(w, 0)
			b = o + Vector2(w, h)
		Defs.DIR_UP:
			b = o + Vector2(w, 0)
		Defs.DIR_DOWN:
			a = o + Vector2(0, h)
			b = o + Vector2(w, h)
	var dir := Vector2(Defs.delta(front_wall))
	_draw_stripes(a, b, dir)
	for k in 3:
		var p := a.lerp(b, (k + 1) / 4.0) + dir * (FRAME + 14.0)
		var d := Vector2(Defs.delta(front_wall)) * 10.0
		var side := Vector2(-d.y, d.x)
		draw_colored_polygon(
			PackedVector2Array([p + d, p - d * 0.3 + side, p - d * 0.3 - side]), Palette.WARN
		)


## Draws stripes on the frame band from a to b. dir points out of the hold.
func _draw_stripes(a: Vector2, b: Vector2, dir: Vector2) -> void:
	var along := (b - a).normalized()
	var length := a.distance_to(b)
	var inner := a + dir * 2.0
	var depth := dir * (FRAME - 2.0)
	draw_colored_polygon(
		PackedVector2Array(
			[inner, inner + along * length, inner + along * length + depth, inner + depth]
		),
		Palette.BACKGROUND
	)
	var step := 16.0
	var t := 0.0
	while t < length:
		var t0 := t
		var t1 := minf(t + step / 2.0, length)
		# A slanted stripe: its outer edge is a half step further along.
		var s0 := minf(t0 + step / 2.0, length)
		var s1 := minf(t1 + step / 2.0, length)
		draw_colored_polygon(
			PackedVector2Array(
				[
					inner + along * t0,
					inner + along * t1,
					inner + along * s1 + depth,
					inner + along * s0 + depth
				]
			),
			Palette.WARN
		)
		t += step


## Draws the jolt warning on a cargo: the wall jolt would make it react (SPEC Section 12.3).
func _draw_jolt(top_left: Vector2) -> void:
	var p := top_left + Vector2(cell * 0.72, cell * 0.62)
	draw_circle(p, 12.0, Palette.BAD)
	CargoDraw.draw_icon(self, Defs.TRAIT_ELECTRONIC, p, 14.0, Palette.BACKGROUND)


func _draw_warning(top_left: Vector2) -> void:
	var p := top_left + Vector2(cell * 0.5, cell * 0.62)
	draw_colored_polygon(
		PackedVector2Array([p + Vector2(0, -12), p + Vector2(11, 8), p + Vector2(-11, 8)]),
		Palette.WARN
	)
	draw_string(
		ThemeDB.fallback_font,
		p + Vector2(-3, 6),
		"!",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		Palette.BACKGROUND
	)


func _process(_delta: float) -> void:
	if not links.is_empty() or not offsets.is_empty():
		queue_redraw()


## Returns the center of a cargo in local coordinates, with its offset.
func cargo_center(c: Dictionary) -> Vector2:
	var off: Vector2 = offsets.get(c["id"], Vector2.ZERO)
	return grid_origin() + _center(c) + off * cell
