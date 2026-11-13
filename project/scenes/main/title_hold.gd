class_name TitleHold
extends Control
## A faint small hold behind the title that shows the idea of the game: every
## STEP seconds, the cargo slides in a random direction and hits (SPEC Section 20.1).
## It is decoration only: it is not a run, and it uses no game rules or state.

const COLUMNS := 9
const ROWS := 6
const CELL := 96.0
const STEP := 2.5
const SLIDE_TIME := 0.45
const ALPHA := 0.18
## The cargo: a shape, its first cell, and how it looks.
const START: Array[Dictionary] = [
	{
		"id": "steel_ingot",
		"cell": Vector2i(0, 0),
		"shape": [[0, 0], [1, 0]],
		"traits": [],
		"weight": 3
	},
	{
		"id": "specimen_tube",
		"cell": Vector2i(4, 1),
		"shape": [[0, 0], [0, 1]],
		"traits": ["fragile"],
		"weight": 2
	},
	{
		"id": "fuel_drum",
		"cell": Vector2i(7, 0),
		"shape": [[0, 0]],
		"traits": ["fluid", "volatile"],
		"weight": 2
	},
	{
		"id": "coolant_pipe",
		"cell": Vector2i(2, 3),
		"shape": [[0, 0], [1, 0], [0, 1]],
		"traits": ["fluid"],
		"weight": 2
	},
	{
		"id": "circuit_boards",
		"cell": Vector2i(6, 4),
		"shape": [[0, 0], [1, 0]],
		"traits": ["electronic"],
		"weight": 1
	},
	{
		"id": "shield_generator",
		"cell": Vector2i(0, 5),
		"shape": [[0, 0]],
		"traits": ["shield"],
		"weight": 2
	},
]
const DIRECTIONS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var _cargo: Array[Dictionary] = []
var _wait := STEP


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(COLUMNS, ROWS) * CELL
	for c in START:
		var shape := []
		for xy: Array in c["shape"]:
			shape.append({"x": xy[0], "y": xy[1]})
		var look := {
			"def_id": c["id"],
			"kind": Defs.KIND_FREIGHT,
			"traits": c["traits"],
			"weight_value": c["weight"],
		}
		_cargo.append(
			{"cell": c["cell"], "shape": shape, "look": look, "from": c["cell"], "t": 1.0}
		)


## Returns the cell of each cargo now. The UI check uses it.
func cells() -> Array:
	return _cargo.map(func(c: Dictionary) -> Vector2i: return c["cell"])


func _process(delta: float) -> void:
	_wait -= delta
	for c in _cargo:
		c["t"] = minf(1.0, c["t"] + delta / SLIDE_TIME)
	if _wait <= 0.0:
		_wait = STEP
		_slide()
	queue_redraw()


## Slides each cargo in a random direction that moves at least one cargo.
func _slide() -> void:
	var order := DIRECTIONS.duplicate()
	order.shuffle()
	for d: Vector2i in order:
		if _slide_to(d):
			return


func _slide_to(d: Vector2i) -> bool:
	# The cargo nearest to the front wall moves first.
	var sorted := _cargo.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _lead(a, d) > _lead(b, d))
	var moved := false
	for c in sorted:
		var start: Vector2i = c["cell"]
		while _free(c, c["cell"] + d):
			c["cell"] += d
		if c["cell"] != start:
			moved = true
			c["from"] = start
			c["t"] = 0.0
	return moved


func _lead(c: Dictionary, d: Vector2i) -> int:
	var best := -1000
	for s: Dictionary in c["shape"]:
		var cell: Vector2i = c["cell"] + Vector2i(s["x"], s["y"])
		best = maxi(best, cell.x * d.x + cell.y * d.y)
	return best


func _free(c: Dictionary, at: Vector2i) -> bool:
	for s: Dictionary in c["shape"]:
		var cell := at + Vector2i(s["x"], s["y"])
		if cell.x < 0 or cell.y < 0 or cell.x >= COLUMNS or cell.y >= ROWS:
			return false
		for o in _cargo:
			if o == c:
				continue
			for os: Dictionary in o["shape"]:
				if o["cell"] + Vector2i(os["x"], os["y"]) == cell:
					return false
	return true


func _draw() -> void:
	var origin := (size - Vector2(COLUMNS, ROWS) * CELL) / 2.0
	var line := Color(Palette.PANEL_LINE, ALPHA)
	draw_rect(Rect2(origin, Vector2(COLUMNS, ROWS) * CELL), line, false, 2.0)
	for x in range(1, COLUMNS):
		draw_line(origin + Vector2(x * CELL, 0), origin + Vector2(x * CELL, ROWS * CELL), line)
	for y in range(1, ROWS):
		draw_line(origin + Vector2(0, y * CELL), origin + Vector2(COLUMNS * CELL, y * CELL), line)
	for c in _cargo:
		# Ease out: a fast start and a hard stop, as a slide into a wall.
		var k: float = 1.0 - pow(1.0 - c["t"], 3.0)
		var at := Vector2(c["from"]).lerp(Vector2(c["cell"]), k)
		CargoDraw.draw(self, c["look"], c["shape"], origin + at * CELL, CELL, ALPHA)
