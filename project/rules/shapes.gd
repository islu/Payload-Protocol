class_name Shapes
## Shapes of cargo: a list of cells relative to the origin (SPEC Section 6.1).

## The four cells that share an edge with a cell (SPEC Section 4.4).
const EDGE_NEIGHBORS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]


## Turns a shape 90° clockwise rot times. Then it moves the shape so that its
## smallest x and its smallest y are 0 (SPEC Section 6.1).
static func rotate(shape: Array[Vector2i], rot: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = shape.duplicate()
	for _i in posmod(rot, 4):
		for k in out.size():
			# Clockwise on a grid with y down: (x, y) -> (-y, x).
			out[k] = Vector2i(-out[k].y, out[k].x)
	return normalize(out)


static func normalize(shape: Array[Vector2i]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if shape.is_empty():
		return out
	var low := shape[0]
	for c in shape:
		low = Vector2i(mini(low.x, c.x), mini(low.y, c.y))
	for c in shape:
		out.append(c - low)
	return out


## Returns the columns and the rows of a shape.
static func size(shape: Array[Vector2i]) -> Vector2i:
	var s := Vector2i.ZERO
	for c in shape:
		s = Vector2i(maxi(s.x, c.x + 1), maxi(s.y, c.y + 1))
	return s


## Returns the cells of a shape in a rotation at a place.
static func cells_at(shape: Array[Vector2i], rot: int, pos: Vector2i) -> Array[Vector2i]:
	var out := rotate(shape, rot)
	for k in out.size():
		out[k] += pos
	return out


## Reports whether all cells of a shape are connected by edges (SPEC Section 6.1).
static func connected(shape: Array[Vector2i]) -> bool:
	if shape.is_empty():
		return false
	var seen := {shape[0]: true}
	var stack: Array[Vector2i] = [shape[0]]
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		for d in EDGE_NEIGHBORS:
			var n := c + d
			if n in shape and not seen.has(n):
				seen[n] = true
				stack.append(n)
	return seen.size() == shape.size()


## Reads a shape from JSON: a list of [x, y] pairs. JSON numbers are floats.
static func from_json(list: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for pair in list:
		out.append(Vector2i(int(pair[0]), int(pair[1])))
	return out


## Returns a shape as JSON-like data for the view: a list of {x, y}.
static func to_view(shape: Array[Vector2i]) -> Array:
	var out := []
	for c in shape:
		out.append({"x": c.x, "y": c.y})
	return out


## Returns the shape in each of the 4 rotations, for the view (SPEC Section 8.2).
static func rotations_view(shape: Array[Vector2i]) -> Array:
	var out := []
	for rot in 4:
		out.append(to_view(rotate(shape, rot)))
	return out
