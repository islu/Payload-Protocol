class_name RunView
## The view of a run for the UI. The UI reads only the view, and it does not
## calculate game values (SPEC Section 20). The view is plain data: dictionaries,
## arrays, strings, ints, and bools. A cell is {x, y}. A text for the player with
## arguments is {key, args}.

## The help of a kit offer for the freight on the dock and in the hold (SPEC Section 20.2).
const HELPS_TEXT := "Helps {count} of your freight"
const FORK_HELP_TEXT := "The next jump has a fork step"
## The texts of the effects of an event choice (SPEC Sections 20.8 and 26.2).
const EFFECT_TEXT := {
	"gain": "+{amount} credits",
	"loss": "{amount} credits",
	Defs.EFFECT_KIT: "Kit on the dock: {name}",
	Defs.EFFECT_CLAMP: "+1 clamp",
	Defs.EFFECT_SCRAP: "Scrap on the dock: {name}",
	Defs.EFFECT_CONTRACT: "New contract: {name}",
	Defs.EFFECT_MOD: "Select a ship mod",
	Defs.EFFECT_PAYMENT: "Payment of this leg -{amount}",
}


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
## Returns the IDs of the cargo at the front wall of the first shift step that would
## react to its wall jolt, as a set (SPEC Sections 10.4 and 12.3).
static func jolt_risks(run: Run) -> Dictionary:
	var out := {}
	if run.hazard.is_empty():
		return out
	var delta := Defs.delta(run.hazard[0])
	for c in run.hold_cargo():
		var at_wall := false
		for cell in c.cells():
			if not run.inside(cell + delta):
				at_wall = true
		if not at_wall:
			continue
		if run.has_mod(Defs.MOD_PADDED_WALLS):
			continue
		var f := Shift.taken(run, c, 0 if c.has(Defs.TRAIT_CUSHION) else Shift.force_weight(run, c))
		for t in Defs.LIMIT_TRAITS:
			if c.has(t) and f >= run.break_limit(t):
				out[c.id] = true
	return out


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


## Returns how a kit definition helps the cargo on the dock and in the hold, as a
## text, or {} (SPEC Section 20.2).
static func kit_helps(run: Run, d: CargoDef) -> Dictionary:
	if d.traits.has(Defs.TRAIT_SENSOR):
		return text(FORK_HELP_TEXT) if not run.fork_options.is_empty() else {}
	var wants: Array = []
	var kind := Defs.KIND_FREIGHT
	if d.traits.has(Defs.TRAIT_COOLER):
		wants = [Defs.TRAIT_PERISHABLE]
	elif d.traits.has(Defs.TRAIT_CUSHION):
		wants = [Defs.TRAIT_FRAGILE]
	elif d.traits.has(Defs.TRAIT_SHIELD):
		wants = [Defs.TRAIT_FRAGILE, Defs.TRAIT_VOLATILE, Defs.TRAIT_FLUID, Defs.TRAIT_ELECTRONIC]
	elif d.traits.has(Defs.TRAIT_BATTERY):
		wants = [Defs.TRAIT_SHIELD]
		kind = Defs.KIND_KIT
	var count := 0
	for c: Cargo in run.cargo.values():
		if c.kind != kind:
			continue
		for t: String in wants:
			if c.has(t):
				count += 1
				break
	return text(HELPS_TEXT, {"count": count}) if count > 0 else {}


## Returns the visible state of a run.
static func view(run: Run) -> Dictionary:
	var cat := run.cat
	var v := {
		"seed": str(run.seed_value),
		"phase": run.phase,
		"leg": run.leg,
		"legs": cat.legs.size(),
		"jump": run.jump,
		"jumps": cat.jumps(run.leg),
		"jumps_to_payment": cat.jumps(run.leg) - run.jump + 1,
		"credits": run.credits,
		"payment": run.payment(),
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
		"front_wall": run.hazard[0] if not run.hazard.is_empty() else "",
		"mass":
		{
			"hold": run.hold_mass(),
			"limit": run.mass_limit,
			"max": run.max_mass(),
			"fee": run.fuel_fee(),
		},
		"warp": run.last_warp,
		"arrival": run.last_arrival,
		"payment_screen": {},
		"end": {},
		"line": run.line,
		"mods": mods(run, run.mods),
		"mod_offer": mods(run, run.mod_offer),
		"mod_areas": mod_areas(run),
		"event": event(run),
		"environment": environment(run),
		"incident": incident(run),
	}
	var ids := run.cargo.keys()
	ids.sort()
	var powered := Shift.power_check(run)
	var hold := run.hold_cargo()
	var risky := jolt_risks(run)
	for id: int in ids:
		var cv := _cargo(run, run.cargo[id], hold, powered)
		cv["jolt_risk"] = risky.has(id)
		v["cargo"].append(cv)
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
					"helps": kit_helps(run, d),
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
		"clamps": run.clamps,
		"clamps_after": run.clamps + 1,
		"hold": {"columns": run.columns, "rows": run.rows},
		"column_after": {"columns": run.columns + 1, "rows": run.rows},
		"row_after": {"columns": run.columns, "rows": run.rows + 1},
		"mass_limit": run.mass_limit,
		"mass_limit_after": run.mass_limit + cat.reinforce_amount,
	}
	if run.phase == Defs.PHASE_PAYMENT:
		v["payment_screen"] = {
			"payment": run.payment(),
			"credits": run.credits,
			"after": run.credits - run.payment(),
			"can_pay": run.credits >= run.payment(),
			"last": run.leg >= cat.legs.size(),
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
		"no_cooler":
		(
			# The warnings of SPEC Section 12.3.
			c.in_hold
			and c.has(Defs.TRAIT_PERISHABLE)
			and not Arrival.cooled(c, hold)
			and not Arrival.cryo(run, c)
		),
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


## Adds the values of a contract card to its view: the freight groups, the totals,
## the mass after it is accepted, and the loaded pieces (SPEC Section 20.2).
static func _contract_card(run: Run, k: Contract, kv: Dictionary) -> void:
	var groups := []
	var by_id := {}
	var mass := 0
	for f: Dictionary in kv["freight"]:
		mass += f["mass"]
		if by_id.has(f["def_id"]):
			by_id[f["def_id"]]["count"] += 1
			continue
		var g := f.duplicate()
		g["count"] = 1
		by_id[f["def_id"]] = g
		groups.append(g)
	var carried := 0
	for c in run.hold_cargo():
		carried += run.cargo_mass(c)
	for id in run.dock:
		carried += run.cargo_mass(run.cargo[id])
	var after := carried + mass
	var loaded := 0
	for c in run.hold_cargo():
		if k.accepted and c.contract == k.id:
			loaded += 1
	kv["groups"] = groups
	kv["pieces"] = kv["freight"].size()
	kv["total_pay"] = k.template.pay * kv["freight"].size()
	kv["mass"] = mass
	kv["mass_after"] = after
	kv["mass_state"] = (
		"over" if after > run.max_mass() else "fee" if after > run.mass_limit else "ok"
	)
	kv["loaded"] = loaded


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
		"penalty": t.penalty,
		"jumps": t.jumps,
		"jumps_left": k.jumps_left,
		"carried": k.carried(),
	}
	_contract_card(run, k, kv)
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


## Returns the name and the rule of each mod of a list (SPEC Section 27).
static func mods(run: Run, ids: PackedStringArray) -> Array:
	var out := []
	for id in ids:
		var m: Dictionary = run.cat.mods.get(id, {})
		out.append({"id": id, "name": m.get("name", id), "text": m.get("text", "")})
	return out


## Returns the area of each mod that has one: {mod, cells}. Shock Floor has the bottom
## row, and Cryo Line has the left column (SPEC Section 27.2).
static func mod_areas(run: Run) -> Array:
	var out := []
	if run.has_mod(Defs.MOD_SHOCK_FLOOR):
		var cells := []
		for x in run.columns:
			cells.append({"x": x, "y": run.rows - 1})
		out.append({"mod": Defs.MOD_SHOCK_FLOOR, "cells": cells})
	if run.has_mod(Defs.MOD_CRYO_LINE):
		var cells := []
		for y in run.rows:
			cells.append({"x": 0, "y": y})
		out.append({"mod": Defs.MOD_CRYO_LINE, "cells": cells})
	return out


## Returns the open event: {name, text, choices: [{index, text, cost, can, effects}]},
## or {}. Each effect is a text {key, args} (SPEC Section 20.8).
static func event(run: Run) -> Dictionary:
	if run.phase != Defs.PHASE_EVENT or run.event == null:
		return {}
	var choices := []
	for i in run.event.choices.size():
		var c: Dictionary = run.event.choices[i]
		var effects := []
		for f: Dictionary in c["effects"]:
			effects.append(_effect(run, f))
		var can: bool = c["cost"] == 0 or (run.credits >= 0 and c["cost"] <= run.credits)
		choices.append(
			{"index": i, "text": c["text"], "cost": c["cost"], "can": can, "effects": effects}
		)
	return {"id": run.event.id, "name": run.event.name, "text": run.event.text, "choices": choices}


static func _effect(run: Run, f: Dictionary) -> Dictionary:
	match f["type"]:
		Defs.EFFECT_CREDITS:
			var key: String = EFFECT_TEXT["gain"] if f["amount"] > 0 else EFFECT_TEXT["loss"]
			return text(key, {"amount": f["amount"]})
		Defs.EFFECT_KIT, Defs.EFFECT_SCRAP:
			return text(EFFECT_TEXT[f["type"]], {"name": run.cat.cargo[f["cargo"]].name})
		Defs.EFFECT_CONTRACT:
			var name := run.cat.contract(f["contract"]).client_name
			return text(EFFECT_TEXT[f["type"]], {"name": name})
		Defs.EFFECT_PAYMENT:
			return text(EFFECT_TEXT[f["type"]], {"amount": f["amount"]})
	return text(EFFECT_TEXT.get(f["type"], ""), {})


## Returns the environment of the leg: {id, name, text}, or {} (SPEC Section 28.1).
static func environment(run: Run) -> Dictionary:
	if run.environment == "":
		return {}
	var e: Dictionary = run.cat.environments.get(run.environment, {})
	return {"id": run.environment, "name": e.get("name", ""), "text": e.get("text", "")}


## Returns the incident of the next jump: {kind, x, y, cells}, or {}. cells has the
## cells of its place: a column, a row, or a cell (SPEC Section 29.3).
static func incident(run: Run) -> Dictionary:
	var i := run.incident
	if i.is_empty():
		return {}
	var cells := []
	match i["kind"]:
		Defs.INCIDENT_METEOR:
			for y in run.rows:
				cells.append({"x": i["x"], "y": y})
		Defs.INCIDENT_ION_PULSE:
			for x in run.columns:
				cells.append({"x": x, "y": i["y"]})
		_:
			cells.append({"x": i["x"], "y": i["y"]})
	return {"kind": i["kind"], "x": i.get("x", -1), "y": i.get("y", -1), "cells": cells}
