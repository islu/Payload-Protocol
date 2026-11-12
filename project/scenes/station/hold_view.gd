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

const CELL := 84.0

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
	custom_minimum_size = Vector2(run["hold"]["max_columns"], run["hold"]["max_rows"]) * CELL
	queue_redraw()


## Returns the upper left of the grid in local coordinates. The grid is centered.
func grid_origin() -> Vector2:
	return ((size - Vector2(columns, rows) * CELL) / 2.0).floor()


## Returns the cell at a global position, also outside the grid.
func cell_at(global_pos: Vector2) -> Vector2i:
	var local := global_pos - global_position - grid_origin()
	return Vector2i(floori(local.x / CELL), floori(local.y / CELL))


## Returns the cell of the upper left of a shape when the player holds it at a
## global position. The shape snaps to the nearest cell (SPEC Section 8.3).
func snap_origin(global_pos: Vector2, grab: Vector2) -> Vector2i:
	var local := global_pos - global_position - grid_origin() - grab * CELL
	return Vector2i(roundi(local.x / CELL), roundi(local.y / CELL))


func is_over(global_pos: Vector2) -> bool:
	return (
		Rect2(global_position + grid_origin(), Vector2(columns, rows) * CELL)
		. grow(CELL * 0.5)
		. has_point(global_pos)
	)


## Returns the ID of the cargo in a cell, or -1.
func cargo_at(cell: Vector2i) -> int:
	for c: Dictionary in cargo:
		if not c["in_hold"]:
			continue
		for s: Dictionary in c["shape"]:
			if Vector2i(c["x"] + s["x"], c["y"] + s["y"]) == cell:
				return c["id"]
	return -1


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var id := cargo_at(cell_at(get_global_mouse_position()))
		if id != _hover:
			_hover = id
			cargo_hovered.emit(id)
	elif event is InputEventMouseButton and event.pressed:
		var cell := cell_at(get_global_mouse_position())
		var id := cargo_at(cell)
		if id < 0:
			return
		var c := _cargo(id)
		var top_left := grid_origin() + Vector2(c["x"], c["y"]) * CELL + _first_cell_offset(c)
		if c["clamped"] and event.button_index == MOUSE_BUTTON_LEFT:
			if CargoDraw.clamp_rect(top_left, CELL).grow(4).has_point(get_local_mouse_position()):
				clamp_pressed.emit(id)
				accept_event()
				return
		cargo_pressed.emit(id, cell - Vector2i(c["x"], c["y"]), event.button_index)
		accept_event()


func _notification(what: int) -> void:
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
	return Vector2(best) * CELL


func _draw() -> void:
	var o := grid_origin()
	draw_rect(
		Rect2(o - Vector2(6, 6), Vector2(columns, rows) * CELL + Vector2(12, 12)),
		Palette.PANEL_LINE,
		false,
		3.0
	)
	for y in rows:
		for x in columns:
			var r := Rect2(o + Vector2(x, y) * CELL, Vector2(CELL, CELL))
			draw_rect(r, Palette.GRID)
			draw_rect(r, Palette.GRID_LINE, false, 1.0)
	for z: Dictionary in zone:
		draw_rect(Rect2(o + Vector2(z["x"], z["y"]) * CELL, Vector2(CELL, CELL)), Palette.ZONE)
	for c: Dictionary in cargo:
		if c["in_hold"]:
			var alpha: float = 0.3 if c["id"] == dragging else fades.get(c["id"], 1.0)
			var off: Vector2 = offsets.get(c["id"], Vector2.ZERO)
			var at := o + (Vector2(c["x"], c["y"]) + off) * CELL
			CargoDraw.draw(self, c, c["shape"], at, CELL, alpha)
			if c["no_cooler"] or c["no_power"]:
				_draw_warning(at + _first_cell_offset(c))
	for id: int in marked:
		var c := _cargo(id)
		if not c.is_empty() and c["in_hold"]:
			for s: Dictionary in c["shape"]:
				draw_rect(
					(
						Rect2(
							o + Vector2(c["x"] + s["x"], c["y"] + s["y"]) * CELL,
							Vector2(CELL, CELL)
						)
						. grow(-3)
					),
					Palette.ACCENT,
					false,
					3.0
				)
	_draw_links(o)
	if not preview.is_empty():
		_draw_preview_links(o)
		var color: Color = Palette.GOOD if preview["ok"] else Palette.BAD
		for cell: Vector2i in preview["cells"]:
			var r := Rect2(o + Vector2(cell) * CELL, Vector2(CELL, CELL)).grow(-2)
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
	for cell: Vector2i in preview["cells"]:
		sum += Vector2(cell) + Vector2(0.5, 0.5)
	var at: Vector2 = sum / preview["cells"].size() * CELL
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
	return sum / c["shape"].size() * CELL


func _draw_warning(top_left: Vector2) -> void:
	var p := top_left + Vector2(CELL * 0.5, CELL * 0.62)
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
	return grid_origin() + _center(c) + off * CELL
