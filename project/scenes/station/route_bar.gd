class_name RouteBar
extends VBoxContainer
## The route bar above the hold (SPEC Section 20.2): the next jump as a route, from
## left to right. Depart, the incident, each shift step in order, and arrive, joined
## by a line. The environment of the leg is a band below the line. The ship marks
## the point where it is: depart at the station, and the point that plays now
## during the warp (SPEC Section 20.3). It reads the view only.

## The mouse is on the card of a shift step (its index), or left it (-1).
signal step_hovered(index: int)

const DEPART_TEXT := "Depart"
const ARRIVE_TEXT := "Arrive"
const SENSOR_TEXT := "Sensor"
## The size of a step card and of the incident card.
const CARD_WIDTH := 120.0
const ARROW_SIZE := 52
## The strip above the cards where the ship flies.
const SHIP_HEIGHT := 26.0
const LINE_WIDTH := 3.0

## The points from left to right: Depart, Incident, Step1, ..., Arrive. The checks
## read their names.
var points: Array[Control] = []
## The index of each point that the ship went to, in order (for the checks).
var visited: Array = []
## The band of the environment, or null.
var env_band: Control
## The index of the point where the ship is.
var at := 0

var _row: HBoxContainer


func _init() -> void:
	add_theme_constant_override("separation", 6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The arrows of the cards are display text (SPEC Section 4.2).
	TextSize.display(self)
	var sky := Control.new()
	sky.custom_minimum_size.y = SHIP_HEIGHT
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)
	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 28)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	_row.sort_children.connect(queue_redraw)


## Builds the route: the environment and the incident of the jump ({} for none), and
## its steps as in view.run.hazard ({directions, fork, known}).
func set_route(env: Dictionary, incident: Dictionary, steps: Array, view: Dictionary) -> void:
	Ui.clear(_row)
	if env_band != null:
		env_band.queue_free()
		env_band = null
	points.clear()
	points.append(_end(DEPART_TEXT, "Depart"))
	if not incident.is_empty():
		var card := RouteCards.incident_card(_row, incident)
		card.custom_minimum_size.x = CARD_WIDTH
		points.append(card)
	var i := 0
	for step: Dictionary in steps:
		points.append(_step_card(i, step, view))
		i += 1
	points.append(_end(ARRIVE_TEXT, "Arrive"))
	if not env.is_empty():
		env_band = RouteCards.env_tag(self, env)
		env_band.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	at = 0
	visited = [0]
	queue_redraw()


## Moves the ship to a point by its name: "Incident", "Step2", or "Arrive"
## (SPEC Section 20.3). A name that the route does not have does nothing.
func go_to(point_name: String) -> void:
	for k in points.size():
		if points[k].name == point_name:
			at = k
			visited.append(k)
			queue_redraw()
			return


## A shift step: a large arrow, its number, and its direction. A fork step shows its
## two directions and "?", or its one direction and the Sensor mark (SPEC Section 18).
func _step_card(index: int, step: Dictionary, view: Dictionary) -> Control:
	var color: Color = Palette.BAD if step["fork"] else Palette.WARN
	var card := Ui.panel(_row)
	card.name = "Step%d" % (index + 1)
	var style: StyleBoxFlat = card.get_theme_stylebox("panel")
	style.border_color = color
	card.custom_minimum_size = Vector2(CARD_WIDTH, 0)
	# The mouse on a card marks the front wall of its step (SPEC Section 20.2).
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.mouse_entered.connect(func() -> void: step_hovered.emit(index))
	card.mouse_exited.connect(func() -> void: step_hovered.emit(-1))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	card.add_child(box)
	var look := StationScreen.step_card(step, view)
	var big := Ui.label(box, "", ARROW_SIZE, color)
	big.text = look["arrow"]
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var name_label := Ui.label(box, "", TextSize.SMALL, color)
	name_label.text = "%d · %s" % [index + 1, look["names"]]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if look["sensor"]:
		# The Sensor icon of the shop: the font has no glyph for it (SPEC Section 20.2).
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 4)
		box.add_child(row)
		var icon := ShopPanel.trait_icon(Defs.TRAIT_SENSOR)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
		Ui.label(row, "", TextSize.SMALL, Palette.ACCENT).text = tr(SENSOR_TEXT)
	return card


## An end of the route: a ring and its name.
func _end(text: String, node_name: String) -> Control:
	var box := VBoxContainer.new()
	box.name = node_name
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(box)
	var ring := RouteEnd.new()
	ring.station = node_name == "Arrive"
	ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(ring)
	var l := Ui.label(box, text, TextSize.SMALL, Palette.ACCENT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return box


## Draws the line through the points, and the ship above the point where it is.
func _draw() -> void:
	if points.size() < 2:
		return
	var y := _row.position.y + _row.size.y / 2.0
	var a := _center_x(points[0])
	var b := _center_x(points[-1])
	draw_line(Vector2(a, y), Vector2(b, y), Palette.PANEL_LINE, LINE_WIDTH)
	if at >= points.size():
		return
	# The ship: a triangle that points to the right, above the point.
	var x := _center_x(points[at])
	var c := Vector2(x, SHIP_HEIGHT / 2.0)
	var ship := PackedVector2Array([c + Vector2(12, 0), c + Vector2(-9, -9), c + Vector2(-9, 9)])
	draw_colored_polygon(ship, Palette.ACCENT)
	draw_line(c + Vector2(-9, 0), c + Vector2(-18, 0), Color(Palette.WARN, 0.8), 3.0)


func _center_x(point: Control) -> float:
	return _row.position.x + point.position.x + point.size.x / 2.0


## A ring at an end of the route. The station end has a second ring.
class RouteEnd:
	extends Control
	var station := false

	func _init() -> void:
		custom_minimum_size = Vector2(34, 34)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		draw_circle(c, 15.0, Palette.BACKGROUND)
		draw_arc(c, 13.0, 0.0, TAU, 32, Palette.ACCENT, 3.0)
		if station:
			draw_arc(c, 6.0, 0.0, TAU, 24, Palette.ACCENT, 3.0)
		else:
			draw_circle(c, 5.0, Palette.ACCENT)
