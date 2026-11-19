class_name Shift
## One shift step: the power check, the slide, the hits, and the reactions
## (SPEC Sections 9 to 12). It uses no random numbers.
##
## A step returns its event log for the UI:
## {direction, powered: [id], slides: [{cargo, from, to, distance}],
##  hits: [{cargo, other, wall, jolt, meteor, press, force, contact}], reactions: [...],
##  after: [{cargo, x, y, kind}]}.
## A cell in the log is {x, y}. "other" is 0 for a wall. In a press, "cargo" presses
## and "other" takes the force.


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
	# A clamped cargo does not slide (SPEC Section 13).
	if c.clamped or dist.get(c.id, 0) >= slide_limit(run, c):
		return false
	for cell in c.cells():
		var n := cell + delta
		if not run.inside(n) or occ.get(n, c.id) != c.id:
			return false
	return true


## Returns the slide limit of a cargo: 1 for a Thruster, the number of Low Gravity, or
## no limit (SPEC Sections 10.2 and 28.2).
static func slide_limit(run: Run, c: Cargo) -> int:
	var limit: int = run.env_value(Defs.ENV_LOW_GRAVITY, "max_slide", 1 << 30)
	if c.has(Defs.TRAIT_THRUSTER):
		limit = mini(limit, 1)
	return limit


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
			_still(run, c, delta, occ, out, forces)
			continue
		var force := force_weight(run, c) * d
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
			var f := hit_force(run, c, force)
			out["hits"].append(_hit(c, 0, f, wall))
			_take(forces, c.id, f)
		var ids := others.keys()
		ids.sort()
		for id: int in ids:
			var o: Cargo = run.cargo[id]
			# Two cargo that stop at their slide limits moved together: no hit (SPEC Section 10.2).
			if d >= slide_limit(run, c) and dist.get(id, 0) >= slide_limit(run, o):
				continue
			var f := hit_force(run, c, force, o)
			out["hits"].append(_hit(c, id, f, others[id]))
			_take(forces, c.id, f)
			_take(forces, id, hit_force(run, o, force, c))
	return forces


## Returns the force that a cargo takes from a hit of a raw force (SPEC Sections 10.3,
## 11.3, and 27.2): 0 when it or the other cargo of the hit is Cushion, then less with
## Shock Floor. other is null for a wall, a jolt, or a meteor.
static func hit_force(run: Run, c: Cargo, raw: int, other: Cargo = null) -> int:
	var cushion := c.has(Defs.TRAIT_CUSHION) or (other != null and other.has(Defs.TRAIT_CUSHION))
	return _taken(run, c, 0 if cushion else raw)


## Returns a hit of the log. other is the ID of the other cargo, or 0 for a wall, a
## jolt, or a meteor.
static func _hit(
	c: Cargo, other: int, force: int, contact: Array, jolt := false, meteor := false, press := false
) -> Dictionary:
	return {
		"cargo": c.id,
		"other": other,
		"wall": other == 0 and not meteor,
		"jolt": jolt,
		"meteor": meteor,
		"press": press,
		"force": force,
		"contact": contact,
	}


## Gives the hits of a cargo that did not slide: its wall jolt and its presses
## (SPEC Sections 10.4 and 10.5). occ is the occupancy after the slide.
static func _still(
	run: Run, c: Cargo, delta: Vector2i, occ: Dictionary, out: Dictionary, forces: Dictionary
) -> void:
	_jolt(run, c, delta, out, forces)
	_press(run, c, delta, occ, out, forces)


## Gives the presses of a cargo that did not slide: one hit on each cargo directly in
## front of it, with the force of its weight value. Only the cargo in front takes it.
## A clamped cargo does not press (SPEC Section 10.5).
static func _press(
	run: Run, c: Cargo, delta: Vector2i, occ: Dictionary, out: Dictionary, forces: Dictionary
) -> void:
	if c.clamped:
		return
	var fronts := {}
	for cell in c.cells():
		var id: int = occ.get(cell + delta, c.id)
		if id != c.id:
			if not fronts.has(id):
				fronts[id] = []
			fronts[id].append(_cell(cell))
	var ids := fronts.keys()
	ids.sort()
	for id: int in ids:
		var f := hit_force(run, run.cargo[id], force_weight(run, c), c)
		out["hits"].append(_hit(c, id, f, fronts[id], false, false, true))
		_take(forces, id, f)


## Returns the force that each cargo would take from its wall jolt and its presses in
## the first shift step, by ID (SPEC Section 12.3). It tries the slide, then puts each
## cargo back.
static func first_step_forces(run: Run) -> Dictionary:
	var forces := {}
	if run.hazard.is_empty():
		return forces
	var direction := run.hazard[0]
	var delta := Defs.delta(direction)
	var from := {}
	for c in run.hold_cargo():
		from[c.id] = c.pos
	var out := {"slides": [], "hits": []}
	var dist := _slide(run, direction, out)
	var occ := run.occupancy()
	for c in run.hold_cargo():
		if dist.get(c.id, 0) < 1:
			_still(run, c, delta, occ, out, forces)
	for c in run.hold_cargo():
		c.pos = from[c.id]
	return forces


## Gives the wall jolt to a cargo that did not slide and is next to the front wall:
## a hit with a force of its weight value (SPEC Section 10.4). It does not go to the
## cargo behind it.
static func _jolt(run: Run, c: Cargo, delta: Vector2i, out: Dictionary, forces: Dictionary) -> void:
	var contact: Array = []
	for cell in c.cells():
		if not run.inside(cell + delta):
			contact.append(_cell(cell))
	if contact.is_empty():
		return
	var f := jolt_force(run, c)
	out["hits"].append(_hit(c, 0, f, contact, true))
	_take(forces, c.id, f)


## Returns the force of the wall jolt of a cargo: its weight value, 0 for Cushion.
## The Padded Walls mod makes it less by its value, and 0 at least (SPEC Sections 10.4 and 27.2).
static func jolt_force(run: Run, c: Cargo) -> int:
	var f := hit_force(run, c, force_weight(run, c))
	if run.has_mod(Defs.MOD_PADDED_WALLS):
		f = maxi(0, f - run.cat.mod_value(Defs.MOD_PADDED_WALLS, "less"))
	return f


## Returns the weight value of a cargo for the force of its hits. With the Gravity
## Damper mod, heavy cargo has the value of standard cargo (SPEC Section 27.2).
static func force_weight(run: Run, c: Cargo) -> int:
	if c.weight() == Defs.WEIGHT_HEAVY and run.has_mod(Defs.MOD_GRAVITY_DAMPER):
		return run.cat.weight_value(Defs.WEIGHT_STANDARD)
	return run.cat.weight_value(c.weight())


## Returns the force that a cargo takes from a hit. With the Shock Floor mod, a cargo
## with a cell in the bottom row takes less by the mod value, and 0 at least (SPEC Section 27.2).
static func _taken(run: Run, c: Cargo, force: int) -> int:
	if run.has_mod(Defs.MOD_SHOCK_FLOOR):
		for cell in c.cells():
			if cell.y == run.rows - 1:
				return maxi(0, force - run.cat.mod_value(Defs.MOD_SHOCK_FLOOR, "less"))
	return force


## Returns the force that shorts an Electronic cargo: the number of the Radiation
## Belt, or no force with no Radiation Belt (SPEC Section 28.2).
static func _radiation(run: Run) -> int:
	return run.env_value(Defs.ENV_RADIATION_BELT, "electronic", 1 << 30)


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
		var kind := reaction_at(run, c, forces[c.id])
		if kind != "":
			queue.append([kind, c.id, -1])
	_run_queue(run, queue, powered, out)


## Returns the reaction of a cargo that takes a hit of a force, or "". One reaction
## for each cargo: the first in this order (SPEC Section 11). A Radiation Belt
## shorts Electronic cargo (SPEC Section 28.2).
static func reaction_at(run: Run, c: Cargo, force: int) -> String:
	if c.has(Defs.TRAIT_VOLATILE) and force >= run.break_limit(Defs.TRAIT_VOLATILE):
		return Defs.REACT_EXPLOSION
	if c.has(Defs.TRAIT_FLUID) and force >= run.break_limit(Defs.TRAIT_FLUID):
		return Defs.REACT_LEAK
	if c.has(Defs.TRAIT_FRAGILE) and force >= run.break_limit(Defs.TRAIT_FRAGILE):
		return Defs.REACT_BREAK
	if c.has(Defs.TRAIT_ELECTRONIC) and force >= _radiation(run):
		return Defs.REACT_SHORT
	return ""


## Does the reactions of a queue, and each reaction that they start, in order.
## Each item is [kind, cargo ID, cause].
static func _run_queue(run: Run, queue: Array, powered: Dictionary, out: Dictionary) -> void:
	while not queue.is_empty():
		var p: Array = queue.pop_front()
		queue.append_array(_apply(run, p[0], p[1], p[2], powered, out))


## Gives each Shield in the hold its one charge for the jump (SPEC Section 12.2).
static func charge_shields(run: Run) -> void:
	run.charges = {}
	for c in run.hold_cargo():
		if c.has(Defs.TRAIT_SHIELD):
			run.charges[c.id] = 1


## Plays an incident before the first shift step (SPEC Section 29). incident is
## {kind, x, y}. It returns the log: {kind, x, y, hits, reactions, after, debris}.
## debris is the ID of a new debris, or 0.
static func incident(run: Run, inc: Dictionary) -> Dictionary:
	var out := {
		"kind": inc["kind"],
		"x": inc.get("x", -1),
		"y": inc.get("y", -1),
		"hits": [],
		"reactions": [],
		"after": [],
		"debris": 0,
	}
	var powered := power_check(run)
	var queue: Array = []
	match inc["kind"]:
		Defs.INCIDENT_METEOR:
			var top: Cargo = null
			var top_y := 1 << 30
			for c in run.hold_cargo():
				for cell in c.cells():
					if cell.x == inc["x"] and cell.y < top_y:
						top = c
						top_y = cell.y
			if top != null:
				var f := hit_force(run, top, run.cat.meteor_force)
				var contact := [_cell(Vector2i(inc["x"], top_y))]
				out["hits"].append(_hit(top, 0, f, contact, false, true))
				_react(run, {top.id: f}, powered, out)
		Defs.INCIDENT_ION_PULSE:
			for c in run.hold_cargo():
				if (
					c.has(Defs.TRAIT_ELECTRONIC)
					and c.cells().any(func(v: Vector2i) -> bool: return v.y == inc["y"])
				):
					queue.append([Defs.REACT_SHORT, c.id, -1])
		Defs.INCIDENT_HULL_BREACH:
			var cell := Vector2i(inc["x"], inc["y"])
			var occ := run.occupancy()
			if occ.has(cell):
				queue.append([Defs.REACT_BREAK, occ[cell], -1])
			else:
				var d := run.new_cargo(run.cat.cargo[run.cat.debris])
				d.kind = Defs.KIND_SCRAP
				d.in_hold = true
				d.pos = cell
				run.dock.erase(d.id)
				out["debris"] = d.id
	_run_queue(run, queue, powered, out)
	for c in run.hold_cargo():
		out["after"].append({"cargo": c.id, "x": c.pos.x, "y": c.pos.y, "kind": c.kind})
	return out


## Does one reaction, and returns the reactions that it starts.
static func _apply(
	run: Run, kind: String, id: int, cause: int, powered: Dictionary, out: Dictionary
) -> Array:
	var c: Cargo = run.cargo.get(id)
	if c == null or not c.in_hold:
		return []
	if c.kind == Defs.KIND_SCRAP and kind != Defs.REACT_CLEAR:
		return []
	var index: int = out["reactions"].size()
	# The number of the reaction in its chain (SPEC Section 21.5).
	var chain := (
		1 if cause < 0 else _chain_size(out["reactions"], _root(out["reactions"], cause)) + 1
	)
	if kind != Defs.REACT_CLEAR:
		var s := protector(run, c, powered)
		if s != null:
			run.charges[s.id] -= 1
			(
				out["reactions"]
				. append(
					{
						"kind": Defs.REACT_SHIELD,
						"cargo": id,
						"cause": cause,
						"shield": s.id,
						"canceled": kind,
						"loss": 0,
						"chain": chain,
						"result": Defs.RESULT_KEPT,
					}
				)
			)
			return []
	var loss := 0
	if kind != Defs.REACT_CLEAR and c.kind == Defs.KIND_FREIGHT:
		loss = run.pay_of(c)
	var rec := {
		"kind": kind,
		"cargo": id,
		"cause": cause,
		"loss": loss,
		"chain": chain,
		"result": Defs.RESULT_SCRAP,
	}
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
			rec["result"] = Defs.RESULT_REMOVED
		Defs.REACT_EXPLOSION:
			var area := blast_area(run, c)
			var cells := []
			for cell: Vector2i in area:
				cells.append(_cell(cell))
			rec["area"] = cells
			run.remove_cargo(id)
			rec["result"] = Defs.RESULT_REMOVED
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


## Returns the number of reactions in the log of the chain that starts at "root".
static func _chain_size(reactions: Array, root: int) -> int:
	var n := 0
	for i in reactions.size():
		if _root(reactions, i) == root:
			n += 1
	return n


## Returns the index of the first reaction of the chain of a reaction.
static func _root(reactions: Array, i: int) -> int:
	while reactions[i]["cause"] >= 0:
		i = reactions[i]["cause"]
	return i


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
## that a Battery that is not scrap powers (SPEC Section 12.2).
static func power_check(run: Run) -> Dictionary:
	var powered := {}
	# A Magnetic Storm takes the power of each Shield, with Array Power too (SPEC Section 28.2).
	if run.environment == Defs.ENV_MAGNETIC_STORM:
		return powered
	var hold := run.hold_cargo()
	for s in hold:
		if not s.has(Defs.TRAIT_SHIELD):
			continue
		for b in hold:
			if powers(run, b, s):
				powered[s.id] = true
				break
	return powered


## Reports whether a Battery powers a Shield: next to it, or within the range of the
## Array Power mod (SPEC Sections 12.2 and 27.2). It does not check the environment.
static func powers(run: Run, battery: Cargo, shield: Cargo) -> bool:
	if not battery.has(Defs.TRAIT_BATTERY) or not shield.has(Defs.TRAIT_SHIELD):
		return false
	if run.has_mod(Defs.MOD_ARRAY_POWER):
		return Cargo.within(battery, shield, run.cat.mod_value(Defs.MOD_ARRAY_POWER, "range"))
	return Cargo.next_to(battery, shield)


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
