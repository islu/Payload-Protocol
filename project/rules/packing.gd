class_name Packing
## The check that a list of shapes fits in an empty hold (content.md: the offers
## of a station fit together in an empty hold).


## Reports whether all shapes fit in an empty grid. It tries at most budget
## places, and returns false when the budget ends.
static func packs(shapes: Array, columns: int, rows: int, budget: int) -> bool:
	var total := 0
	for s: Array[Vector2i] in shapes:
		total += s.size()
	if total > columns * rows:
		return false
	# Large shapes first: they have the fewest places.
	var order := shapes.duplicate()
	order.sort_custom(func(a: Array, b: Array) -> bool: return a.size() > b.size())
	var state := {"budget": budget, "used": {}}
	return _place(order, 0, columns, rows, state)


static func _place(order: Array, i: int, columns: int, rows: int, state: Dictionary) -> bool:
	if i == order.size():
		return true
	var used: Dictionary = state["used"]
	for rot in 4:
		var s := Shapes.rotate(order[i], rot)
		var size := Shapes.size(s)
		for y in range(rows - size.y + 1):
			for x in range(columns - size.x + 1):
				state["budget"] -= 1
				if state["budget"] < 0:
					return false
				var cells: Array[Vector2i] = []
				var free := true
				for c in s:
					var cell := c + Vector2i(x, y)
					if used.has(cell):
						free = false
						break
					cells.append(cell)
				if not free:
					continue
				for c in cells:
					used[c] = true
				if _place(order, i + 1, columns, rows, state):
					return true
				for c in cells:
					used.erase(c)
	return false
