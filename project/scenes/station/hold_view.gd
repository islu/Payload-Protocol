class_name HoldView
extends Control
## Draws the hold: the grid, the cargo, the links, the clamps, a zone, and the
## preview of a drop (SPEC Sections 8.3, 12.3, and 20.2). It reads the view only.
## The hold has a bulkhead with lights, and a deck plate in each cell (SPEC Section 21.6).
## With bay true, it draws the stasis bay: its own cells, a padded frame, and the
## coupling to the hold below it (SPEC Section 31.2).

## A press on a cargo in the hold: the left button starts a drag, the right button rotates.
signal cargo_pressed(id: int, grab: Vector2i, button: int)
## A press on the clamp mark of a cargo (SPEC Section 13).
signal clamp_pressed(id: int)
## The mouse is on a cargo, or on no cargo (id -1).
signal cargo_hovered(id: int)

## The size of a cell: the cargo images show at half their size (SPEC Sections 4.2 and 20.2).
const CELL := 100.0
## The free space around the grid, in cells: the marks of the front wall are there.
const MARGIN := 0.8
## The space at the right of the stasis bay, in pixels: the coupling to the hold.
const BAY_COUPLING := 16.0
## The space around the cells of the stasis bay, in pixels: its padded frame.
const BAY_PAD := 12.0
## The width of the bulkhead around the grid, in pixels (SPEC Section 21.6).
const FRAME := 18.0
## The length of each arm of a corner bracket, in pixels.
const BRACKET := 28.0
## The colors of the lights of the bulkhead (SPEC Section 21.6).
const LIGHT_IDLE := Color("29538f")
const LIGHT_STEP := Palette.TITLE_AMBER
const LIGHT_HIT := Color(1, 1, 1)
const LIGHT_ALARM := Palette.BAD
const LIGHT_LEAK := Palette.FLUID
const LIGHT_SHORT := Palette.ACCENT
## The targets of the light log: all lights, or the light nearest to a point. A wall
## target is the direction of the wall.
const LIGHT_ALL := "all"
const LIGHT_NEAR := "near"
## The shortest time between two flashes of a light: 3 flashes each second or less.
const FLASH_GAP := 1.0 / 3.0
## The time of the bounce of a new clamp, in seconds (SPEC Section 21.1).
const CLAMP_BOUNCE := 0.3
## The color of the area of each mod.
const MOD_COLORS := {
	Defs.MOD_SHOCK_FLOOR: Color(0.55, 0.75, 1.0, 0.16),
}

## The size of a cell in pixels.
var cell := CELL
## True for the stasis bay (SPEC Section 31).
var bay := false

var columns := 6
var rows := 6
var cargo: Array = []
var links: Array = []
## The cells to mark: the zone of a bonus, or the freight of a contract.
var zone: Array = []
var marked: Array = []
## The preview of a drop, or empty: the drop_preview of GameState (ok, cells, blocking,
## nearest), with origin (the place under the mouse), id, and links (SPEC Section 8.3).
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
## The cargo with a check mark, by ID: the freight that the arrival delivered (SPEC Section 20.4).
var checks: Dictionary = {}
## The areas of the mods of the ship: [{mod, cells}] (SPEC Section 27.2).
var mod_areas: Array = []
## The mod under the mouse on the mod bar: its area has a bright frame (SPEC Section 20.2).
var hover_mod := ""
## The cells of the place of the incident of the next jump (SPEC Section 29.3).
var incident_cells: Array = []
## The lights of the bulkhead: [{wall, at, steady, flash, flash_end, flash_start}]. at is
## the place along the wall, from 0 to 1. The stasis bay has none (SPEC Section 21.6).
var lights: Array[Dictionary] = []
## Each request to light a light: {target, color, shown}, for the checks. shown is false
## when a light flashed less than FLASH_GAP before.
var light_log: Array[Dictionary] = []
## The start time of the bounce of each new clamp, by cargo ID (SPEC Section 21.1).
var clamp_bounces: Dictionary = {}
## True after the hold drew the trail of a sliding cargo, for the checks (SPEC Section 21.1).
var trail_drawn := false

var _hover := -1
## True while the hold animates: the last frame of an animation draws once more.
var _animating := false
## The layer of the bulkhead and the deck plates, behind the hold.
var _back_layer: BackLayer
## The links pulse: only this layer redraws each frame, not the whole hold.
var _link_layer: LinkLayer


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	# The bulkhead and the deck plates do not move: their own layer behind the hold
	# draws them again only when the view changes (SPEC Section 21.6).
	_back_layer = BackLayer.new(self)
	add_child(_back_layer)
	_link_layer = LinkLayer.new(self)
	add_child(_link_layer)


func set_view(run: Dictionary) -> void:
	cargo = run["cargo"]
	if bay:
		# The stasis bay has no front wall, no mod area, and no incident (SPEC Section 31.1).
		var size: Dictionary = run.get("shock_bay", {})
		columns = size.get("columns", 0)
		rows = size.get("rows", 0)
		visible = columns > 0
		links = []
		for l: Dictionary in run["links"]:
			if _mine(_cargo(l["from"])) and _mine(_cargo(l["to"])):
				links.append(l)
		# The padded frame, and the coupling to the hold at the right (SPEC Section 31.2).
		var pad := 2.0 * BAY_PAD
		custom_minimum_size = Vector2(columns * CELL + pad + BAY_COUPLING, rows * CELL + pad)
	else:
		columns = run["hold"]["columns"]
		rows = run["hold"]["rows"]
		links = []
		for l: Dictionary in run["links"]:
			if _mine(_cargo(l["from"])):
				links.append(l)
		mod_areas = run.get("mod_areas", [])
		incident_cells = run.get("incident", {}).get("cells", [])
		front_walls = PackedStringArray([run.get("front_wall", "")])
		show_jolts = true
		custom_minimum_size = Vector2(columns + MARGIN, rows + MARGIN) * CELL
		if lights.is_empty():
			_make_lights()
	queue_redraw()
	_back_layer.queue_redraw()
	_link_layer.queue_redraw()


## Reports whether a cargo view is in the area of this view: the hold or the stasis bay.
func _mine(c: Dictionary) -> bool:
	return not c.is_empty() and (c.get("in_bay", false) if bay else c.get("in_hold", false))


## Marks front walls. jolts shows the wall jolt warnings (SPEC Section 20.2).
func show_front_walls(walls: PackedStringArray, jolts: bool) -> void:
	front_walls = walls
	show_jolts = jolts
	queue_redraw()


## Sets the cargo under the mouse, or -1. It shows a bright frame on its cells (SPEC Section 4.2).
func set_hover(id: int) -> void:
	if id != _hover:
		_hover = id
		cargo_hovered.emit(id)
		queue_redraw()


## Sets the cargo under a global point as the cargo under the mouse, or none when the
## point is not on the view. A drop calls it: the mouse did not move (SPEC Section 4.2).
func refresh_hover(global_pos: Vector2) -> void:
	var inside := (
		is_visible_in_tree() and _has_point(get_global_transform().affine_inverse() * global_pos)
	)
	set_hover(cargo_at(cell_at(global_pos)) if inside else -1)


## Returns the cells of the frame of the cargo under the mouse (SPEC Section 4.2).
func frame_cells() -> Array[Vector2i]:
	var c := _cargo(_hover)
	if not _mine(c):
		return []
	return _cells_of(c)


## Returns the cells of a cargo view in the grid, or [] for {}.
static func _cells_of(c: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for s: Dictionary in c.get("shape", []):
		out.append(Vector2i(c["x"] + s["x"], c["y"] + s["y"]))
	return out


## Returns the upper left of the grid in local coordinates. The grid is centered.
func grid_origin() -> Vector2:
	var o := ((size - Vector2(columns, rows) * cell) / 2.0).floor()
	if bay:
		# The stasis bay sits at the left: the coupling fills the space at its right.
		o.x = BAY_PAD
	return o


## Returns the grid in local coordinates: its cells, with no bulkhead.
func grid_rect() -> Rect2:
	return Rect2(grid_origin(), Vector2(columns, rows) * cell)


## Returns the global position of a point of the grid in cells: (0.5, 0.5) is the
## center of the cell (0, 0).
func cell_global(at: Vector2) -> Vector2:
	return global_position + grid_origin() + at * cell


## Returns the cell at a global position, also outside the grid.
func cell_at(global_pos: Vector2) -> Vector2i:
	var local := global_pos - global_position - grid_origin()
	return Vector2i(floori(local.x / cell), floori(local.y / cell))


## Returns the cell of the upper left of a shape when the player holds it at a
## global position. The grab cell goes to the cell under the cursor (SPEC Section 8.3).
func snap_origin(global_pos: Vector2, grab: Vector2) -> Vector2i:
	var local := global_pos - global_position - grid_origin() - grab * cell
	return Vector2i(floori(local.x / cell), floori(local.y / cell))


## Returns the grab cell after a clockwise rotation of a shape (SPEC Section 8.2).
## The same cell of the cargo stays under the cursor. The rule is the one of Shapes.rotate.
static func rotate_grab(shape: Array, grab: Vector2) -> Vector2:
	var low := Vector2(INF, INF)
	for c: Dictionary in shape:
		low = Vector2(minf(low.x, -c["y"]), minf(low.y, c["x"]))
	return Vector2(-grab.y, grab.x) - low


## A green check mark at the middle of a cell: the freight is delivered.
func _draw_check(top_left: Vector2) -> void:
	var c := top_left + Vector2(cell, cell) / 2.0
	draw_circle(c, cell * 0.22, Color(Palette.BACKGROUND, 0.8))
	var k := cell * 0.12
	draw_polyline(
		PackedVector2Array(
			[c + Vector2(-k, 0), c + Vector2(-k * 0.3, k * 0.8), c + Vector2(k, -k)]
		),
		Palette.GOOD,
		5.0
	)


## The mouse is on the view only over the grid and its bulkhead. The free margin lets
## the mouse through to the stasis bay that overlaps it (SPEC Sections 4.2 and 31.2).
func _has_point(point: Vector2) -> bool:
	var grid := grid_rect()
	return grid.grow(BAY_PAD if bay else FRAME).has_point(point)


func is_over(global_pos: Vector2) -> bool:
	return (
		Rect2(global_position + grid_origin(), Vector2(columns, rows) * cell)
		. grow(cell * 0.5)
		. has_point(global_pos)
	)


## Returns the ID of the cargo in a cell, or -1.
func cargo_at(at: Vector2i) -> int:
	for c: Dictionary in cargo:
		if _mine(c) and at in _cells_of(c):
			return c["id"]
	return -1


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# The place of the event, not the mouse of the viewport: they can differ.
		set_hover(cargo_at(cell_at(get_global_transform() * event.position)))
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
	# The grid stays centered when the view changes size.
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
		_back_layer.queue_redraw()
	if what == NOTIFICATION_MOUSE_EXIT:
		set_hover(-1)


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
	for a: Dictionary in mod_areas:
		for c: Dictionary in a["cells"]:
			var r := Rect2(o + Vector2(c["x"], c["y"]) * cell, Vector2(cell, cell)).grow(-3)
			draw_rect(r, MOD_COLORS.get(a["mod"], Palette.ZONE))
			if a["mod"] == hover_mod:
				draw_rect(r, Palette.ACCENT, false, 3.0)
	for c: Dictionary in incident_cells:
		var r := Rect2(o + Vector2(c["x"], c["y"]) * cell, Vector2(cell, cell)).grow(-2)
		draw_rect(r, Color(RouteCards.INCIDENT_COLOR, 0.12))
		draw_rect(r, Color(RouteCards.INCIDENT_COLOR, 0.7), false, 2.0)
	for z: Dictionary in zone:
		draw_rect(Rect2(o + Vector2(z["x"], z["y"]) * cell, Vector2(cell, cell)), Palette.ZONE)
	for c: Dictionary in cargo:
		if _mine(c):
			var alpha: float = 0.3 if c["id"] == dragging else fades.get(c["id"], 1.0)
			if alpha <= 0.0:
				continue
			var off: Vector2 = offsets.get(c["id"], Vector2.ZERO)
			var at := o + (Vector2(c["x"], c["y"]) + off) * cell
			if off != Vector2.ZERO:
				_draw_trail(c, at, off)
			CargoDraw.draw(self, c, c["shape"], at, cell, alpha)
			if clamp_bounces.has(c["id"]):
				_draw_clamp_bounce(c, at + _first_cell_offset(c))
			if c.get("no_cooler", false) or c.get("no_power", false):
				_draw_warning(at + _first_cell_offset(c))
			if show_jolts and c.get("jolt_risk", false):
				_draw_jolt(at + _first_cell_offset(c))
			if checks.has(c["id"]):
				_draw_check(at + _first_cell_offset(c))
	for id: int in marked:
		var c := _cargo(id)
		if _mine(c):
			for p in _cells_of(c):
				var r := Rect2(o + Vector2(p) * cell, Vector2(cell, cell)).grow(-3)
				draw_rect(r, Palette.ACCENT, false, 3.0)
	# The cargo under the mouse: a bright frame on its cells (SPEC Section 4.2).
	_draw_outline(o, frame_cells(), Palette.ACCENT)
	# The stripes of a front wall cover its lights (SPEC Section 21.6).
	if not bay:
		_draw_lights()
	for wall in front_walls:
		_draw_front_wall(o, wall)
	if not bay:
		_draw_brackets(grid_rect().grow(FRAME))
	if not preview.is_empty():
		_draw_preview(o)


## Draws the links between the cargo on a canvas, with a pulse (SPEC Section 12.3).
func _draw_links(canvas: CanvasItem, o: Vector2) -> void:
	var t := _now()
	for l: Dictionary in links:
		var a := _cargo(l["from"])
		var b := _cargo(l["to"])
		if a.is_empty() or b.is_empty():
			continue
		var color := Palette.link_color(l["kind"])
		color.a = 0.6 + 0.3 * sin(t * 3.0)
		canvas.draw_line(o + _center(a), o + _center(b), color, 3.0)


## Draws an outline around a group of cells.
func _draw_outline(o: Vector2, cells: Array[Vector2i], color: Color) -> void:
	for p in cells:
		var r := Rect2(o + Vector2(p) * cell, Vector2(cell, cell))
		for d: Vector2i in Shapes.EDGE_NEIGHBORS:
			if p + d in cells:
				continue
			var a := r.get_center() + (Vector2(d) - Vector2(d.y, d.x).abs()) * cell / 2.0
			var b := r.get_center() + (Vector2(d) + Vector2(d.y, d.x).abs()) * cell / 2.0
			draw_line(a - Vector2(d) * 2.0, b - Vector2(d) * 2.0, color, 3.0)


## Draws the preview of a drop (SPEC Section 8.3): each cell green when it is free and
## red when it is not, a red frame on each cargo in the way, and a faint ghost at the
## nearest valid place.
func _draw_preview(o: Vector2) -> void:
	_draw_preview_links(o)
	for e: Dictionary in preview["cells"]:
		var color: Color = Palette.GOOD if e["free"] else Palette.BAD
		var r := Rect2(o + Vector2(e["cell"]) * cell, Vector2(cell, cell)).grow(-2)
		draw_rect(r, Color(color, 0.25))
		draw_rect(r, color, false, 2.0)
	for id: int in preview.get("blocking", []):
		_draw_outline(o, _cells_of(_cargo(id)), Palette.BAD)
	for p in ghost_cells():
		var r := Rect2(o + Vector2(p) * cell, Vector2(cell, cell)).grow(-6)
		draw_rect(r, Color(Palette.GOOD, 0.1))
		draw_rect(r, Color(Palette.GOOD, 0.45), false, 2.0)


## Returns the cells of the ghost at the nearest valid place, or [] (SPEC Section 8.3).
func ghost_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if preview.is_empty() or preview.get("nearest") == null:
		return out
	var shift: Vector2i = preview["nearest"] - preview["origin"]
	for e: Dictionary in preview["cells"]:
		out.append(e["cell"] + shift)
	return out


## Draws the links that the drop would make, from the preview cells (SPEC Section 8.3).
func _draw_preview_links(o: Vector2) -> void:
	if preview["cells"].is_empty():
		return
	var sum := Vector2.ZERO
	for e: Dictionary in preview["cells"]:
		sum += Vector2(e["cell"]) + Vector2(0.5, 0.5)
	var at: Vector2 = sum / preview["cells"].size() * cell
	for l: Dictionary in preview.get("links", []):
		var other_id: int = l["to"] if l["from"] == preview["id"] else l["from"]
		var other := _cargo(other_id)
		if other.is_empty():
			continue
		var color := Palette.link_color(l["kind"])
		draw_dashed_line(o + at, o + _center(other), color, 3.0, 10.0)


func _center(c: Dictionary) -> Vector2:
	var sum := Vector2.ZERO
	for s: Dictionary in c["shape"]:
		sum += Vector2(c["x"] + s["x"], c["y"] + s["y"]) + Vector2(0.5, 0.5)
	return sum / c["shape"].size() * cell


## Draws the bulkhead of the hold: metal plates with a rivet at each grid line
## (SPEC Sections 4.2 and 21.6).
func _draw_frame(canvas: CanvasItem, o: Vector2) -> void:
	var grid := grid_rect()
	var outer := grid.grow(FRAME)
	if bay:
		_draw_bay_frame(canvas, grid, grid.grow(BAY_PAD - 2.0))
		return
	canvas.draw_rect(outer, Palette.PANEL_LINE.darkened(0.35))
	canvas.draw_rect(outer, Palette.PANEL_LINE, false, 2.0)
	canvas.draw_rect(grid.grow(2), Palette.BACKGROUND)
	var rivet := Palette.PANEL_LINE.lightened(0.25)
	var mid := FRAME / 2.0
	for x in columns + 1:
		var px := o.x + x * cell
		canvas.draw_circle(Vector2(px, grid.position.y - mid), 2.5, rivet)
		canvas.draw_circle(Vector2(px, grid.end.y + mid), 2.5, rivet)
	for y in rows + 1:
		var py := o.y + y * cell
		canvas.draw_circle(Vector2(grid.position.x - mid, py), 2.5, rivet)
		canvas.draw_circle(Vector2(grid.end.x + mid, py), 2.5, rivet)


## Starts the bounce of a new clamp on a cargo (SPEC Section 21.1).
func bounce_clamp(id: int) -> void:
	clamp_bounces[id] = _now()
	queue_redraw()


## A new clamp grows a little and comes back, with a bright frame.
func _draw_clamp_bounce(c: Dictionary, top_left: Vector2) -> void:
	var k := (_now() - float(clamp_bounces[c["id"]])) / CLAMP_BOUNCE
	if k >= 1.0:
		clamp_bounces.erase(c["id"])
		return
	var r := CargoDraw.clamp_rect(top_left, cell).grow(8.0 * sin(PI * k))
	draw_rect(r, Palette.CLAMP)
	draw_rect(r, Color(1, 1, 1, 1.0 - k), false, 2.0)


## Draws a short trail behind a sliding cargo: two faded copies of its cells, toward
## the place that it comes from (SPEC Section 21.1).
func _draw_trail(c: Dictionary, at: Vector2, off: Vector2) -> void:
	trail_drawn = true
	var back := off.normalized() * cell
	var color := Palette.cargo_color(c)
	for i in [1, 2]:
		for s: Dictionary in c["shape"]:
			var r := Rect2(
				at + Vector2(s["x"], s["y"]) * cell + back * 0.3 * i, Vector2(cell, cell)
			)
			draw_rect(r.grow(-10.0), Color(color, 0.18 / i))


## Draws a deck plate: a cell with a soft bevel and a screw at each corner. The
## contrast is low, so that the cargo is easy to see (SPEC Section 21.6).
func _draw_plate(canvas: CanvasItem, r: Rect2) -> void:
	canvas.draw_rect(r, Palette.GRID)
	var inner := r.grow(-4)
	var light := Palette.GRID.lightened(0.07)
	var dark := Palette.GRID.darkened(0.25)
	canvas.draw_line(inner.position, Vector2(inner.end.x, inner.position.y), light, 2.0)
	canvas.draw_line(inner.position, Vector2(inner.position.x, inner.end.y), light, 2.0)
	canvas.draw_line(Vector2(inner.position.x, inner.end.y), inner.end, dark, 2.0)
	canvas.draw_line(Vector2(inner.end.x, inner.position.y), inner.end, dark, 2.0)
	var screw := Palette.GRID.lightened(0.14)
	var k := 10.0
	for p in [
		inner.position + Vector2(k, k),
		Vector2(inner.end.x - k, inner.position.y + k),
		Vector2(inner.position.x + k, inner.end.y - k),
		inner.end - Vector2(k, k),
	]:
		canvas.draw_circle(p, 2.5, screw)
	canvas.draw_rect(r, Palette.GRID_LINE, false, 1.0)


## Draws an L-shaped bracket at each corner of the bulkhead (SPEC Section 21.6).
func _draw_brackets(outer: Rect2) -> void:
	var metal := Palette.PANEL_LINE.lightened(0.12)
	var edge := Palette.PANEL_LINE.lightened(0.35)
	var arm := FRAME + BRACKET
	for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
		var p: Vector2 = outer.position + outer.size * corner
		var sx := 1.0 if corner.x == 0 else -1.0
		var sy := 1.0 if corner.y == 0 else -1.0
		var pts := PackedVector2Array(
			[
				p,
				p + Vector2(sx * arm, 0),
				p + Vector2(sx * arm, sy * FRAME),
				p + Vector2(sx * FRAME, sy * FRAME),
				p + Vector2(sx * FRAME, sy * arm),
				p + Vector2(0, sy * arm),
			]
		)
		draw_colored_polygon(pts, metal)
		pts.append(p)
		draw_polyline(pts, edge, 1.5)
		draw_circle(p + Vector2(sx, sy) * FRAME / 2.0, 3.0, edge)


# --- The lights of the bulkhead (SPEC Section 21.6) ---


## Makes 2 lights on each wall, at the middle of each half of the wall.
func _make_lights() -> void:
	lights.clear()
	for wall in [Defs.DIR_UP, Defs.DIR_RIGHT, Defs.DIR_DOWN, Defs.DIR_LEFT]:
		for at in [0.25, 0.75]:
			(
				lights
				. append(
					{
						"wall": wall,
						"at": at,
						"steady": LIGHT_IDLE,
						"flash": LIGHT_IDLE,
						"flash_end": 0.0,
						"flash_start": -10.0,
					}
				)
			)


## Returns the color of a light now: its flash, or its steady color.
func light_color(l: Dictionary) -> Color:
	return l["flash"] if _now() < l["flash_end"] else l["steady"]


## Returns the place of a light in local coordinates: on the middle of the bulkhead.
func light_position(l: Dictionary) -> Vector2:
	var grid := grid_rect()
	var mid := FRAME / 2.0
	match l["wall"]:
		Defs.DIR_UP:
			return Vector2(grid.position.x + grid.size.x * l["at"], grid.position.y - mid)
		Defs.DIR_DOWN:
			return Vector2(grid.position.x + grid.size.x * l["at"], grid.end.y + mid)
		Defs.DIR_LEFT:
			return Vector2(grid.position.x - mid, grid.position.y + grid.size.y * l["at"])
	return Vector2(grid.end.x + mid, grid.position.y + grid.size.y * l["at"])


## Lights the lights of a wall. With seconds 0 or less, the color stays until
## lights_off(); else the lights flash for seconds.
func light_wall(wall: String, color: Color, seconds: float) -> void:
	var chosen := lights.filter(func(l: Dictionary) -> bool: return l["wall"] == wall)
	_light(chosen, wall, color, seconds)


## Flashes all lights for seconds.
func light_all(color: Color, seconds: float) -> void:
	_light(lights, LIGHT_ALL, color, seconds)


## Flashes the light nearest to a point in local coordinates for seconds.
func light_near(point: Vector2, color: Color, seconds: float) -> void:
	if lights.is_empty():
		return
	var best := lights[0]
	for l in lights:
		if light_position(l).distance_to(point) < light_position(best).distance_to(point):
			best = l
	_light([best], LIGHT_NEAR, color, seconds)


## Sets the lights of a wall, or all lights, back to dark blue.
func lights_off(wall := "") -> void:
	for l in lights:
		if wall == "" or l["wall"] == wall:
			l["steady"] = LIGHT_IDLE
			if wall == "":
				l["flash_end"] = 0.0
	queue_redraw()


## Lights the chosen lights, and logs the request. A flash less than FLASH_GAP after
## the last flash of a light does not show.
func _light(chosen: Array, target: String, color: Color, seconds: float) -> void:
	var now := _now()
	var shown := true
	for l: Dictionary in chosen:
		if seconds <= 0.0:
			l["steady"] = color
		elif now - l["flash_start"] >= FLASH_GAP:
			l["flash"] = color
			l["flash_start"] = now
			l["flash_end"] = now + seconds
		else:
			shown = false
	light_log.append({"target": target, "color": color, "shown": shown})
	queue_redraw()


func _flashing() -> bool:
	var now := _now()
	return lights.any(func(l: Dictionary) -> bool: return now < l["flash_end"])


static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


## Draws each light: a dark socket, the lamp, and a glow when it is not dark blue.
func _draw_lights() -> void:
	for l in lights:
		var p := light_position(l)
		var color := light_color(l)
		draw_circle(p, 7.0, Palette.BACKGROUND)
		if color != LIGHT_IDLE:
			draw_circle(p, 13.0, Color(color, 0.25))
		draw_circle(p, 5.0, color)


## Draws the frame of the stasis bay: soft padding with seams, and the coupling to
## the hold at its right (SPEC Section 31.2).
func _draw_bay_frame(canvas: CanvasItem, grid: Rect2, outer: Rect2) -> void:
	var pad: Color = Palette.TRAIT_COLORS[Defs.TRAIT_CUSHION]
	var bottom := outer.end.y
	for side in [-1.0, 1.0]:
		var y: float = grid.get_center().y + side * cell * 0.25
		canvas.draw_line(Vector2(outer.end.x, y), Vector2(size.x, y), Palette.PANEL_LINE, 6.0)
	canvas.draw_rect(outer, Color(pad, 0.35).darkened(0.4))
	canvas.draw_rect(outer, pad, false, 2.0)
	var seam := Color(pad, 0.6)
	for x in columns + 1:
		var px := grid.position.x + x * cell
		canvas.draw_line(
			Vector2(px, outer.position.y + 3), Vector2(px, grid.position.y - 3), seam, 1.5
		)
		canvas.draw_line(Vector2(px, grid.end.y + 3), Vector2(px, bottom - 3), seam, 1.5)
	canvas.draw_rect(grid.grow(2), Palette.BACKGROUND)


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
	var animating := not offsets.is_empty() or _flashing() or not clamp_bounces.is_empty()
	# One more redraw after the last change: a light goes back to dark blue.
	if animating or _animating:
		queue_redraw()
	_animating = animating
	if not offsets.is_empty() or not links.is_empty():
		_link_layer.queue_redraw()


## Returns the center of a cargo in local coordinates, with its offset.
func cargo_center(c: Dictionary) -> Vector2:
	var off: Vector2 = offsets.get(c["id"], Vector2.ZERO)
	return grid_origin() + _center(c) + off * cell


## The layer of the links on top of the hold. It redraws alone each frame while a
## link pulses.
## The layer of the bulkhead and the deck plates behind the hold. It draws again only
## when the view or its size changes, not in each frame of a warp.
class BackLayer:
	extends Control
	var hold: HoldView

	func _init(view: HoldView) -> void:
		hold = view
		show_behind_parent = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		var o := hold.grid_origin()
		hold._draw_frame(self, o)
		for y in hold.rows:
			for x in hold.columns:
				hold._draw_plate(
					self, Rect2(o + Vector2(x, y) * hold.cell, Vector2.ONE * hold.cell)
				)


class LinkLayer:
	extends Control
	var hold: HoldView

	func _init(view: HoldView) -> void:
		hold = view
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		hold._draw_links(self, hold.grid_origin())
