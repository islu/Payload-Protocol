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
		"hazard": Array(run.hazard),
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


static func _cargo(run: Run, c: Cargo, hold: Array[Cargo], powered: Dictionary) -> Dictionary:
	var cv := {
		"id": c.id,
		"def_id": c.def.id,
		"name": c.def.name,
		"kind": c.kind,
		"weight": c.weight(),
		"weight_value": run.cat.weight_value(c.weight()),
		"traits": [] if c.kind == Defs.KIND_SCRAP else Array(c.def.traits),
		"shape": Shapes.to_view(c.shape()),
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
