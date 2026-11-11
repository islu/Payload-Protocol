class_name Shift
## One shift step: the power check, the slide, the hits, and the reactions
## (SPEC Sections 9 to 12). It uses no random numbers.
##
## A step returns its event log for the UI:
## {direction, powered: [id], slides: [{cargo, from, to, distance}],
##  hits: [{cargo, other, wall, force, contact}], reactions: [...], after: [{cargo, x, y, kind}]}.
## A cell in the log is {x, y}. "other" is 0 for a wall.


## Plays one shift step on the run (SPEC Section 9).
static func step(run: Run, direction: String) -> Dictionary:
	var out := {
		"direction": direction,
		"powered": [],
		"slides": [],
		"hits": [],
		"reactions": [],
		"after": []
	}
	var powered := power_check(run)
	for c in run.hold_cargo():
		if powered.has(c.id):
			out["powered"].append(c.id)
	var dist := _slide(run, direction, out)
	var forces := _hits(run, direction, dist, out)
	_react(run, forces, powered, out)
	for c in run.hold_cargo():
		out["after"].append({"cargo": c.id, "x": c.pos.x, "y": c.pos.y, "kind": c.kind})
	return out


## Moves each cargo that can slide until a wall or a cargo that stopped blocks
## it (SPEC Section 10). It returns the distance of each cargo by ID.
##
## The cargo nearest to the wall in the direction moves first, one cell at a
## time. The passes repeat until no cargo can move, so the order does not change
## the result: a cargo that waits behind a moving cargo moves in a later pass.
static func _slide(run: Run, direction: String, out: Dictionary) -> Dictionary:
	var delta := Defs.delta(direction)
	var order := run.hold_cargo()
	var lead := func(c: Cargo) -> int:
		var best := -(1 << 30)
		for cell in c.cells():
			best = maxi(best, cell.x * delta.x + cell.y * delta.y)
		return best
	# A stable sort: equal leads keep the order of the IDs.
	var keyed: Array = []
	for i in order.size():
		keyed.append([lead.call(order[i]), i, order[i]])
	keyed.sort_custom(
		func(a: Array, b: Array) -> bool: return a[0] > b[0] or (a[0] == b[0] and a[1] < b[1])
	)
	var from := {}
	for c in order:
		from[c.id] = c.pos
	var occ := run.occupancy()
	var dist := {}
	var moved := true
	while moved:
		moved = false
		for k: Array in keyed:
			var c: Cargo = k[2]
			if not _can_step(run, c, delta, occ, dist):
				continue
			for cell in c.cells():
				occ.erase(cell)
			c.pos += delta
			for cell in c.cells():
				occ[cell] = c.id
			dist[c.id] = dist.get(c.id, 0) + 1
			moved = true
	for c in run.hold_cargo():
		if dist.get(c.id, 0) > 0:
			out["slides"].append(
				{
					"cargo": c.id,
					"from": _cell(from[c.id]),
					"to": _cell(c.pos),
					"distance": dist[c.id]
				}
			)
	return dist


static func _can_step(
	run: Run, c: Cargo, delta: Vector2i, occ: Dictionary, dist: Dictionary
) -> bool:
	# A clamped cargo does not slide. A Thruster slides 1 cell at most (SPEC Section 10.2).
	if c.clamped or (c.has(Defs.TRAIT_THRUSTER) and dist.get(c.id, 0) >= 1):
		return false
	for cell in c.cells():
		var n := cell + delta
		if not run.inside(n) or occ.get(n, c.id) != c.id:
			return false
	return true


## Finds the hit of each cargo that slid (SPEC Section 10.3). It returns the
## largest force that each cargo took, by ID. Each hit checks the break limits
## alone, so the largest force is enough.
static func _hits(run: Run, direction: String, dist: Dictionary, out: Dictionary) -> Dictionary:
	var delta := Defs.delta(direction)
	var occ := run.occupancy()
	var forces := {}
	for c in run.hold_cargo():
		var d: int = dist.get(c.id, 0)
		if d < 1:
			continue
		var force := run.cat.weight_value(c.weight()) * d
		var wall: Array = []
		var others := {}
		for cell in c.cells():
			var n := cell + delta
			if not run.inside(n):
				wall.append(_cell(cell))
			elif occ.has(n) and occ[n] != c.id:
				if not others.has(occ[n]):
					others[occ[n]] = []
				others[occ[n]].append(_cell(cell))
		# A Thruster that stops by itself has no wall and no cargo in front: no hit.
		if not wall.is_empty():
			var f := 0 if c.has(Defs.TRAIT_CUSHION) else force
			out["hits"].append(
				{"cargo": c.id, "other": 0, "wall": true, "force": f, "contact": wall}
			)
			_take(forces, c.id, f)
		var ids := others.keys()
		ids.sort()
		for id: int in ids:
			var cushion: bool = c.has(Defs.TRAIT_CUSHION) or run.cargo[id].has(Defs.TRAIT_CUSHION)
			var f := 0 if cushion else force
			out["hits"].append(
				{"cargo": c.id, "other": id, "wall": false, "force": f, "contact": others[id]}
			)
			_take(forces, c.id, f)
			_take(forces, id, f)
	return forces


static func _take(forces: Dictionary, id: int, force: int) -> void:
	forces[id] = maxi(forces.get(id, -1), force)


## Does the reactions of a step until no new reaction starts (SPEC Section 11).
## A reaction in the log: {kind, cargo, cause, area, shield, canceled}. cause is
## the index of the reaction that started it, or -1 for a hit.
static func _react(run: Run, forces: Dictionary, powered: Dictionary, out: Dictionary) -> void:
	var queue: Array = []
	for c in run.hold_cargo():
		if not forces.has(c.id):
			continue
		var f: int = forces[c.id]
		# One reaction for each cargo: the first in this order (SPEC Section 11).
		if c.has(Defs.TRAIT_VOLATILE) and f >= run.cat.break_limit(Defs.TRAIT_VOLATILE):
			queue.append([Defs.REACT_EXPLOSION, c.id, -1])
		elif c.has(Defs.TRAIT_FLUID) and f >= run.cat.break_limit(Defs.TRAIT_FLUID):
			queue.append([Defs.REACT_LEAK, c.id, -1])
		elif c.has(Defs.TRAIT_FRAGILE) and f >= run.cat.break_limit(Defs.TRAIT_FRAGILE):
			queue.append([Defs.REACT_BREAK, c.id, -1])
	while not queue.is_empty():
		var p: Array = queue.pop_front()
		queue.append_array(_apply(run, p[0], p[1], p[2], powered, out))


## Does one reaction, and returns the reactions that it starts.
static func _apply(
	run: Run, kind: String, id: int, cause: int, powered: Dictionary, out: Dictionary
) -> Array:
	var c: Cargo = run.cargo.get(id)
	if c == null or not c.in_hold:
		return []
	if c.kind == Defs.KIND_SCRAP and kind != Defs.REACT_CLEAR:
		return []
	if kind != Defs.REACT_CLEAR:
		var s := protector(run, c, powered)
		if s != null:
			run.charges[s.id] -= 1
			out["reactions"].append(
				{
					"kind": Defs.REACT_SHIELD,
					"cargo": id,
					"cause": cause,
					"shield": s.id,
					"canceled": kind
				}
			)
			return []
	var index: int = out["reactions"].size()
	var rec := {"kind": kind, "cargo": id, "cause": cause}
	var next: Array = []
	match kind:
		Defs.REACT_BREAK, Defs.REACT_SHORT, Defs.REACT_BLAST:
			_scrap(run, c)
		Defs.REACT_LEAK:
			_scrap(run, c)
			for o in run.hold_cargo():
				if o.has(Defs.TRAIT_ELECTRONIC) and Cargo.next_to(c, o):
					next.append([Defs.REACT_SHORT, o.id, index])
		Defs.REACT_CLEAR:
			run.remove_cargo(id)
		Defs.REACT_EXPLOSION:
			var area := blast_area(run, c)
			var cells := []
			for cell: Vector2i in area:
				cells.append(_cell(cell))
			rec["area"] = cells
			run.remove_cargo(id)
			run.stats["explosions"] += 1
			for o in run.hold_cargo():
				if not o.touches(area):
					continue
				if o.kind == Defs.KIND_SCRAP:
					next.append([Defs.REACT_CLEAR, o.id, index])
				elif o.has(Defs.TRAIT_VOLATILE):
					next.append([Defs.REACT_EXPLOSION, o.id, index])
				elif o.weight() != Defs.WEIGHT_HEAVY:
					next.append([Defs.REACT_BLAST, o.id, index])
	out["reactions"].append(rec)
	return next


## Turns a cargo into scrap (SPEC Section 6.4).
static func _scrap(run: Run, c: Cargo) -> void:
	c.kind = Defs.KIND_SCRAP
	run.stats["scrapped"] += 1


## Returns the blast area of a cargo as a set of cells: each cell in the hold at
## a distance of 1 from a cell of the cargo, diagonal cells too, and not a cell
## of the cargo (SPEC Section 11.2).
static func blast_area(run: Run, c: Cargo) -> Dictionary:
	var own := c.cells()
	var area := {}
	for cell in own:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var n := cell + Vector2i(dx, dy)
				if not n in own and run.inside(n):
					area[n] = true
	return area


## Returns the Shields with power in this step, as a set of IDs: each Shield
## next to a Battery that is not scrap (SPEC Section 12.2).
static func power_check(run: Run) -> Dictionary:
	var powered := {}
	var hold := run.hold_cargo()
	for s in hold:
		if not s.has(Defs.TRAIT_SHIELD):
			continue
		for b in hold:
			if b.has(Defs.TRAIT_BATTERY) and Cargo.next_to(s, b):
				powered[s.id] = true
				break
	return powered


## Returns the Shield that spends its charge to protect a cargo, or null. The
## Shield with the smaller (y, x) of its origin is first (SPEC Section 12.2).
static func protector(run: Run, c: Cargo, powered: Dictionary) -> Cargo:
	var best: Cargo = null
	for s in run.hold_cargo():
		if not powered.has(s.id) or not s.has(Defs.TRAIT_SHIELD) or run.charges.get(s.id, 0) <= 0:
			continue
		if s != c and not Cargo.next_to(s, c):
			continue
		if best == null or s.pos.y < best.pos.y or (s.pos.y == best.pos.y and s.pos.x < best.pos.x):
			best = s
	return best


static func _cell(c: Vector2i) -> Dictionary:
	return {"x": c.x, "y": c.y}
