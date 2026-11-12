class_name RunView
## The view of a run for the UI. The UI reads only the view, and it does not
## calculate game values (SPEC Section 20). The view is plain data: dictionaries,
## arrays, strings, ints, and bools. A cell is {x, y}. A text for the player with
## arguments is {key, args}.


## Returns the name, the rule, and the break limit of each trait (SPEC Section 8.4).
static func terms(cat: Catalog) -> Array:
	var out := []
	for t in Defs.TRAITS:
		var limit := cat.break_limit(t)
		var rule := text(cat.term_text("traits", t), {"limit": limit})
		out.append({"id": t, "name": cat.term_name("traits", t), "rule": rule, "limit": limit})
	return out


## Returns the names of the words of the rules: {kinds, weights, directions}, each a
## map from the ID to the name (SPEC Section 4.4). It also has the weight value of each
## weight (weight_values) and the break limit of each trait (limits), for the rules text.
## Returns the hazard of the next jump: each step is {directions, fork, known}.
## A step that is not a fork has one direction, and known is that direction. A fork
## step has two directions. Its known is "" unless a Sensor is in the hold (SPEC Section 18).
static func hazard(run: Run) -> Array:
	var out := []
	var sensor := false
	for c in run.hold_cargo():
		if c.has(Defs.TRAIT_SENSOR):
			sensor = true
	for i in run.hazard.size():
		var fork := i == run.hazard.size() - 1 and not run.fork_options.is_empty()
		if fork:
			var known: String = run.hazard[i] if sensor else ""
			out.append({"directions": Array(run.fork_options), "fork": true, "known": known})
		else:
			out.append({"directions": [run.hazard[i]], "fork": false, "known": run.hazard[i]})
	return out


static func names(cat: Catalog) -> Dictionary:
	var out := {}
	var groups := {"kinds": Defs.KINDS, "weights": Defs.WEIGHTS, "directions": Defs.DIRECTIONS}
	for group: String in groups:
		out[group] = {}
		for id: String in groups[group]:
			out[group][id] = cat.term_name(group, id)
	out["weight_values"] = {}
	for w in Defs.WEIGHTS:
		out["weight_values"][w] = cat.weight_value(w)
	out["limits"] = {}
	for t in Defs.LIMIT_TRAITS:
		out["limits"][t] = cat.break_limit(t)
	return out


static func text(key: String, args: Dictionary = {}) -> Dictionary:
	return {"key": key, "args": args}


## Returns the visible state of a run.
static func view(run: Run) -> Dictionary:
	var cat := run.cat
	var v := {
		"seed": str(run.seed_value),
		"phase": run.phase,
		"sector": run.sector,
		"sectors": cat.sectors.size(),
		"jump": run.jump,
		"jumps": cat.jumps(run.sector),
		"jumps_to_toll": cat.jumps(run.sector) - run.jump + 1,
		"credits": run.credits,
		"toll": run.toll(),
		"clamps": run.clamps,
		"free_clamps": run.free_clamps(),
		"hold":
		{
			"columns": run.columns,
			"rows": run.rows,
			"max_columns": cat.max_columns,
			"max_rows": cat.max_rows,
		},
		"cargo": [],
		"dock": run.dock.duplicate(),
		"links": links(run),
		"contracts": [],
		"shop": {},
		"hazard": hazard(run),
		"mass":
		{
			"hold": run.hold_mass(),
			"limit": run.mass_limit,
			"max": run.max_mass(),
			"fee": run.fuel_fee(),
		},
		"warp": run.last_warp,
		"arrival": run.last_arrival,
		"toll_gate": {},
		"end": {},
		"line": run.line,
	}
	var ids := run.cargo.keys()
	ids.sort()
	var powered := Shift.power_check(run)
	var hold := run.hold_cargo()
	for id: int in ids:
		v["cargo"].append(_cargo(run, run.cargo[id], hold, powered))
	for i in run.contracts.size():
		v["contracts"].append(_contract(run, i, run.contracts[i]))
	var offers := []
	for i in run.shop.size():
		var d: CargoDef = run.shop[i]["def"]
		(
			offers
			. append(
				{
					"index": i,
					"def_id": d.id,
					"name": d.name,
					"price": d.price,
					"bought": run.shop[i]["bought"],
					"weight": d.weight,
					"weight_value": cat.weight_value(d.weight),
					"mass": run.def_mass(d),
					"traits": Array(d.traits),
					"shape": Shapes.to_view(d.shape),
				}
			)
		)
	v["shop"] = {
		"offers": offers,
		"reroll_price": run.reroll_price(),
		"clamp_price": cat.price("clamp"),
		"clamp_max": cat.price("clamp_max"),
		"upgrade_price": run.upgrade_price(),
		"can_column": run.can_upgrade(Defs.AXIS_COLUMN),
		"can_row": run.can_upgrade(Defs.AXIS_ROW),
		"breach_fee": cat.price("breach_fee"),
		"reinforce_price": run.reinforce_price(),
		"reinforce_amount": cat.reinforce_amount,
		"scrap_cell": cat.price("scrap_cell"),
	}
	if run.phase == Defs.PHASE_TOLL:
		v["toll_gate"] = {
			"toll": run.toll(),
			"credits": run.credits,
			"after": run.credits - run.toll(),
			"can_pay": run.credits >= run.toll(),
			"last": run.sector >= cat.sectors.size(),
		}
	if run.phase == Defs.PHASE_END:
		v["end"] = {
			"won": run.won, "score": run.score(), "seed": v["seed"], "stats": run.stats.duplicate()
		}
	return v


## Returns the view of each cargo in the hold, in the order of the IDs.
static func hold_views(run: Run) -> Array:
	var out := []
	var powered := Shift.power_check(run)
	var hold := run.hold_cargo()
	for c in hold:
		out.append(_cargo(run, c, hold, powered))
	return out


static func _cargo(run: Run, c: Cargo, hold: Array[Cargo], powered: Dictionary) -> Dictionary:
	var cv := {
		"id": c.id,
		"def_id": c.def.id,
		"name": c.def.name,
		"kind": c.kind,
		"weight": c.weight(),
		"weight_value": run.cat.weight_value(c.weight()),
		"mass": run.cargo_mass(c),
		"traits": [] if c.kind == Defs.KIND_SCRAP else Array(c.def.traits),
		"shape": Shapes.to_view(c.shape()),
		# The shape in each rotation, so that a drag can rotate it (SPEC Section 8.2).
		"rotations": Shapes.rotations_view(c.def.shape),
		"rot": c.rot,
		"x": c.pos.x,
		"y": c.pos.y,
		"in_hold": c.in_hold,
		"clamped": c.clamped,
		"contract": -1,
		"pay": 0,
		"sell_price": run.sell_price(c.def) if c.kind == Defs.KIND_KIT else 0,
		"clear_price": run.clear_price(c) if c.kind == Defs.KIND_SCRAP else 0,
		# The warnings of SPEC Section 12.3.
		"no_cooler": c.in_hold and c.has(Defs.TRAIT_PERISHABLE) and not Arrival.cooled(c, hold),
		"no_power": c.in_hold and c.has(Defs.TRAIT_SHIELD) and not powered.has(c.id),
	}
	for i in run.contracts.size():
		if c.contract != 0 and run.contracts[i].id == c.contract:
			cv["contract"] = i
			cv["pay"] = run.contracts[i].template.pay
	return cv


## Returns each link in the hold now (SPEC Section 12.3).
static func links(run: Run) -> Array:
	var out := []
	var hold := run.hold_cargo()
	for a in hold:
		for b in hold:
			if a.has(Defs.TRAIT_COOLER) and b.has(Defs.TRAIT_PERISHABLE) and Cargo.next_to(a, b):
				out.append({"kind": Defs.LINK_COLD, "from": a.id, "to": b.id})
			elif a.has(Defs.TRAIT_BATTERY) and b.has(Defs.TRAIT_SHIELD) and Cargo.next_to(a, b):
				out.append({"kind": Defs.LINK_POWER, "from": a.id, "to": b.id})
	return out


## Returns the links that a cargo would make at a place in the hold: the links
## with that cargo only (SPEC Section 8.3). It returns [] when the drop is not valid.
## It puts the cargo at the place, reads the links, and puts it back.
static func preview_links(run: Run, id: int, pos: Vector2i, rot: int) -> Array:
	if not run.can_place(id, pos, rot):
		return []
	var c: Cargo = run.cargo[id]
	var old := [c.pos, c.rot, c.in_hold]
	c.pos = pos
	c.rot = rot
	c.in_hold = true
	var out := []
	for l: Dictionary in links(run):
		if l["from"] == id or l["to"] == id:
			out.append(l)
	c.pos = old[0]
	c.rot = old[1]
	c.in_hold = old[2]
	return out


static func _contract(run: Run, i: int, k: Contract) -> Dictionary:
	var t := k.template
	var freight := []
	for id in t.freight:
		var d: CargoDef = run.cat.cargo[id]
		(
			freight
			. append(
				{
					"def_id": d.id,
					"name": d.name,
					"weight": d.weight,
					"weight_value": run.cat.weight_value(d.weight),
					"mass": run.def_mass(d),
					"traits": Array(d.traits),
					"shape": Shapes.to_view(d.shape),
				}
			)
		)
	var kv := {
		"index": i,
		"client_name": t.client_name,
		"freight": freight,
		"pay": t.pay,
		"bonus": {},
		"accepted": k.accepted,
	}
	if t.has_bonus():
		var b := t.bonus
		var key := run.cat.term_text("bonuses", b["type"])
		var bv := {"type": b["type"], "pay": b["pay"], "zone": [], "text": text(key)}
		match b["type"]:
			Defs.BONUS_ZONE:
				for y in run.rows:
					for x in run.columns:
						if t.in_zone(Vector2i(x, y), run.columns, run.rows):
							bv["zone"].append({"x": x, "y": y})
				bv["text"] = text(
					key, {"side": run.cat.term_name("sides", b["side"]), "size": b["size"]}
				)
			Defs.BONUS_NOT_NEXT_TO:
				bv["text"] = text(key, {"trait": run.cat.term_name("traits", b["trait"])})
		kv["bonus"] = bv
	return kv
