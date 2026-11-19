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
## With a run, the limits are the limits of the leg (SPEC Section 28.2).
static func terms(cat: Catalog, run: Run = null) -> Array:
	var out := []
	for t in Defs.TRAITS:
		var limit := _limit(cat, run, t)
		var rule := text(cat.term_text("traits", t), {"limit": limit})
		out.append({"id": t, "name": cat.term_name("traits", t), "rule": rule, "limit": limit})
	return out


## Returns the IDs of the cargo that would react to its wall jolt or a press in the
## first shift step, as a set (SPEC Sections 10.4, 10.5, and 12.3).
static func jolt_risks(run: Run) -> Dictionary:
	var out := {}
	var forces := Shift.first_step_forces(run)
	for id: int in forces:
		if Shift.reaction_at(run, run.cargo[id], forces[id]) != "":
			out[id] = true
	return out


## Returns the warp checklist (SPEC Section 20.2): the fuel fee, the number of cargo on
## the dock, the number of cargo with a wall jolt warning, and the kind of the incident
## of the jump ("" with no incident). risky is the result of jolt_risks.
static func checklist(run: Run, risky: Dictionary) -> Dictionary:
	return {
		"fee": run.fuel_fee(),
		"dock": run.dock.size(),
		"jolts": risky.size(),
		"incident": str(run.incident.get("kind", "")),
	}


## Returns the hazard of the next jump: each step is {directions, fork, known}.
## A step that is not a fork has one direction, and known is that direction. A fork
## step has two directions. Its known is "" unless a Sensor is in the hold (SPEC Section 18).
static func hazard(run: Run) -> Array:
	var out := []
	var sensor := false
	for c in run.ship_cargo():
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


## Returns the names of the words of the rules: {kinds, weights, directions}, each a
## map from the ID to the name (SPEC Section 4.4). It also has the weight value of each
## weight (weight_values) and the break limit of each trait (limits), for the rules text.
## With a run, the limits are the limits of the leg (SPEC Section 28.2).
static func names(cat: Catalog, run: Run = null) -> Dictionary:
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
		out["limits"][t] = _limit(cat, run, t)
	return out


static func _limit(cat: Catalog, run: Run, trait_id: String) -> int:
	return run.break_limit(trait_id) if run != null else cat.break_limit(trait_id)


## Returns a size as {columns, rows}, or {} for (0, 0).
static func _size(s: Vector2i) -> Dictionary:
	return {} if s == Vector2i.ZERO else {"columns": s.x, "rows": s.y}


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
	var risky := jolt_risks(run)
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
		"hold": {"columns": run.columns, "rows": run.rows},
		"shock_bay": _size(run.bay_size),
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
			"state": mass_state(run, run.hold_mass()),
		},
		"can_warp": run.hold_mass() <= run.max_mass(),
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
		"checklist": checklist(run, risky),
	}
	var ids := run.cargo.keys()
	ids.sort()
	var powered := Shift.power_check(run)
	var hold := run.hold_cargo()
	var bay := run.bay_cargo()
	for id: int in ids:
		var c: Cargo = run.cargo[id]
		var cv := _cargo(run, c, bay if c.in_bay else hold, powered)
		cv["jolt_risk"] = risky.has(id)
		v["cargo"].append(cv)
	var carried := _carried_mass(run)
	for i in run.contracts.size():
		v["contracts"].append(_contract(run, i, run.contracts[i], carried))
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
					"afford": d.price <= run.credits,
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
	var bay_offer := run.shock_bay_offer()
	v["shop"] = {
		"offers": offers,
		"reroll_price": run.reroll_price(),
		"reroll_afford": run.reroll_price() <= run.credits,
		"clamp_price": cat.price("clamp"),
		"clamp_afford": cat.price("clamp") <= run.credits,
		"clamp_max": cat.price("clamp_max"),
		"can_buy_clamp": run.clamps < cat.price("clamp_max"),
		"bay":
		{
			"now": _size(run.bay_size),
			"after": _size(bay_offer.get("size", Vector2i.ZERO)),
			"price": bay_offer.get("price", 0),
			"afford": bay_offer.get("price", 0) <= run.credits,
		},
		"breach_fee": cat.price("breach_fee"),
		"reinforce_price": run.reinforce_price(),
		"reinforce_afford": run.reinforce_price() <= run.credits,
		"reinforce_amount": cat.reinforce_amount,
		"scrap_cell": cat.price("scrap_cell"),
		"clamps": run.clamps,
		"clamps_after": mini(run.clamps + 1, cat.price("clamp_max")),
		"mass_limit": run.mass_limit,
		"mass_limit_after": run.mass_limit + cat.reinforce_amount,
	}
	if run.phase == Defs.PHASE_ARRIVAL:
		# The credits against the payment of the leg (SPEC Section 20.4).
		v["leg_progress"] = {
			"credits": run.credits,
			"payment": run.payment(),
			"jumps_left": cat.jumps(run.leg) - run.jump,
		}
	if run.phase == Defs.PHASE_PAYMENT:
		var last := run.leg >= cat.legs.size()
		var next := {}
		if not last:
			next = {
				"leg": run.leg + 1,
				"jumps": cat.jumps(run.leg + 1),
				"payment": int(cat.legs[run.leg]["payment"]),
			}
		v["payment_screen"] = {
			"payment": run.payment(),
			"credits": run.credits,
			"after": run.credits - run.payment(),
			"can_pay": run.credits >= run.payment(),
			"last": last,
			"jumps": run.history.filter(func(j: Dictionary) -> bool: return j["leg"] == run.leg),
			"next": next,
		}
	if run.phase == Defs.PHASE_END:
		v["end"] = {
			"won": run.won,
			"score": run.score(),
			"seed": v["seed"],
			"stats": run.stats.duplicate(),
			"legs": end_legs(run),
			"best_jump": best_jump(run),
			"ship":
			{
				"mods": v["mods"],
				"clamps": run.clamps,
				"shock_bay": v["shock_bay"],
				"mass_limit": run.mass_limit,
			},
		}
	return v


## Returns a row for each leg that started: {leg, payment, paid, net}. The net of a
## leg is the sum of the nets of its jumps (SPEC Section 19.2).
static func end_legs(run: Run) -> Array:
	var rows := []
	for leg in range(1, run.leg + 1):
		var net := 0
		for j: Dictionary in run.history:
			if j["leg"] == leg:
				net += j["net"]
		var payment: int = (
			run.payment() if leg == run.leg else int(run.cat.legs[leg - 1]["payment"])
		)
		rows.append({"leg": leg, "payment": payment, "paid": leg < run.leg or run.won, "net": net})
	return rows


## Returns the jump with the largest net, or {} (SPEC Section 19.2).
static func best_jump(run: Run) -> Dictionary:
	var best := {}
	for j: Dictionary in run.history:
		if best.is_empty() or j["net"] > best["net"]:
			best = j
	return best.duplicate()


## Returns the state of a mass: Defs.MASS_OK, MASS_FEE, or MASS_OVER (SPEC Section 25).
static func mass_state(run: Run, mass: int) -> String:
	if mass > run.max_mass():
		return Defs.MASS_OVER
	return Defs.MASS_FEE if mass > run.mass_limit else Defs.MASS_OK


static func _sell_action(c: Cargo) -> String:
	match c.kind:
		Defs.KIND_KIT:
			return Defs.ACT_SELL_KIT
		Defs.KIND_SCRAP:
			return Defs.ACT_CLEAR_SCRAP
	return ""


## Returns the view of each cargo in the hold, in the order of the IDs.
static func hold_views(run: Run) -> Array:
	var out := []
	var powered := Shift.power_check(run)
	var hold := run.hold_cargo()
	for c in hold:
		out.append(_cargo(run, c, hold, powered))
	return out


## Returns the views of the cargo in the shock bay (SPEC Section 31.2).
static func bay_views(run: Run) -> Array:
	var out := []
	var bay := run.bay_cargo()
	for c in bay:
		out.append(_cargo(run, c, bay, {}))
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
		"in_bay": c.in_bay,
		"clamped": c.clamped,
		"contract": -1,
		"pay": 0,
		"sell_price": run.sell_price(c.def) if c.kind == Defs.KIND_KIT else 0,
		"clear_price": run.clear_price(c) if c.kind == Defs.KIND_SCRAP else 0,
		# The action of the sell area for this cargo, or "" (SPEC Section 17.1).
		"sell_action": _sell_action(c),
		"no_cooler":
		(
			# The warnings of SPEC Section 12.3.
			(c.in_hold or c.in_bay)
			and c.has(Defs.TRAIT_PERISHABLE)
			and not Arrival.cooled(run, c, hold)
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
	var hold := run.ship_cargo()
	for a in hold:
		for b in hold:
			if Arrival.cools(run, a, b):
				out.append({"kind": Defs.LINK_COLD, "from": a.id, "to": b.id})
			elif Shift.powers(run, a, b):
				out.append({"kind": Defs.LINK_POWER, "from": a.id, "to": b.id})
	return out


## Returns the preview of a drop of a cargo at a place in the hold, or in the shock bay
## with to_bay (SPEC Section 8.3): {ok, cells: [{cell, free}], blocking: [cargo IDs],
## nearest}. A cell is not free when it is outside the area or has a different cargo.
## nearest is the first valid place 1 cell away, in the order of Section 8.2, when the
## drop is not valid. Else it is null.
static func drop_preview(run: Run, id: int, pos: Vector2i, rot: int, to_bay := false) -> Dictionary:
	var out := {"ok": false, "cells": [], "blocking": [], "nearest": null}
	if not run.cargo.has(id) or rot < 0 or rot > 3:
		return out
	var c: Cargo = run.cargo[id]
	var occ := run.occupancy(to_bay)
	var area := run.bay_size if to_bay else Vector2i(run.columns, run.rows)
	# Freight cannot go in the shock bay (SPEC Section 31.1).
	var refused := to_bay and c.kind == Defs.KIND_FREIGHT
	for cell in Shapes.cells_at(c.def.shape, rot, pos):
		var inside := cell.x >= 0 and cell.y >= 0 and cell.x < area.x and cell.y < area.y
		var other: int = occ.get(cell, id)
		out["cells"].append({"cell": cell, "free": inside and other == id and not refused})
		if other != id and not other in out["blocking"]:
			out["blocking"].append(other)
	out["ok"] = run.can_place(id, pos, rot, to_bay)
	if not out["ok"]:
		for kick in Run.ROTATE_KICKS:
			if kick != Vector2i.ZERO and run.can_place(id, pos + kick, rot, to_bay):
				out["nearest"] = pos + kick
				break
	return out


## Returns the links that a cargo would make at a place in the hold: the links
## with that cargo only (SPEC Section 8.3). It returns [] when the drop is not valid.
## It puts the cargo at the place, reads the links, and puts it back.
static func preview_links(run: Run, id: int, pos: Vector2i, rot: int, to_bay := false) -> Array:
	if not run.can_place(id, pos, rot, to_bay):
		return []
	var c: Cargo = run.cargo[id]
	var old := [c.pos, c.rot, c.in_hold, c.in_bay]
	c.pos = pos
	c.rot = rot
	c.in_hold = not to_bay
	c.in_bay = to_bay
	var out := []
	for l: Dictionary in links(run):
		if l["from"] == id or l["to"] == id:
			out.append(l)
	c.pos = old[0]
	c.rot = old[1]
	c.in_hold = old[2]
	c.in_bay = old[3]
	return out


## Adds the values of a contract card to its view: the freight groups, the totals,
## the mass after it is accepted, and the loaded pieces (SPEC Section 20.2).
static func _contract_card(run: Run, k: Contract, kv: Dictionary, carried: int) -> void:
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
	var after := carried + mass
	var loaded := 0
	if k.accepted:
		for c in run.ship_cargo():
			if c.contract == k.id:
				loaded += 1
	kv["groups"] = groups
	kv["pieces"] = kv["freight"].size()
	kv["total_pay"] = k.template.pay * kv["freight"].size()
	kv["mass"] = mass
	kv["mass_after"] = after
	kv["mass_state"] = mass_state(run, after)
	kv["loaded"] = loaded


## The mass of the cargo in the ship and on the dock: a contract adds to it when the
## player accepts it (SPEC Section 20.2).
static func _carried_mass(run: Run) -> int:
	var carried := 0
	for c in run.ship_cargo():
		carried += run.cargo_mass(c)
	for id in run.dock:
		carried += run.cargo_mass(run.cargo[id])
	return carried


static func _contract(run: Run, i: int, k: Contract, carried: int) -> Dictionary:
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
	_contract_card(run, k, kv, carried)
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
		out.append(
			{
				"id": id,
				"name": m.get("name", id),
				"text": text(m.get("text", ""), m.get("values", {}))
			}
		)
	return out


## Returns the area of each mod that has one: {mod, cells}. Shock Floor has the bottom
## row (SPEC Section 27.2).
static func mod_areas(run: Run) -> Array:
	var out := []
	if run.has_mod(Defs.MOD_SHOCK_FLOOR):
		var cells := []
		for x in run.columns:
			cells.append({"x": x, "y": run.rows - 1})
		out.append({"mod": Defs.MOD_SHOCK_FLOOR, "cells": cells})
	return out


## Returns the open event: {name, text, choices: [{index, text, cost, can, why,
## effects}]}, or {}. why is the error text of a choice that cannot be selected.
## Each effect is a text {key, args} (SPEC Section 20.8).
static func event(run: Run) -> Dictionary:
	if run.phase != Defs.PHASE_EVENT or run.event == null:
		return {}
	var choices := []
	for i in run.event.choices.size():
		var c: Dictionary = run.event.choices[i]
		var effects := []
		for f: Dictionary in c["effects"]:
			effects.append(_effect(run, f))
		var why := StationEvents.choice_error(run, i)
		(
			choices
			. append(
				{
					"index": i,
					"text": c["text"],
					"cost": c["cost"],
					"can": why == "",
					"why": why,
					"effects": effects,
				}
			)
		)
	var speaker: Dictionary = run.cat.speakers[run.event.speaker]
	return {
		"id": run.event.id,
		"name": run.event.name,
		"text": run.event.text,
		"speaker": {"id": run.event.speaker, "name": speaker["name"]},
		"choices": choices,
	}


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
