class_name Arrival
## The arrival and the cold chain (SPEC Sections 12.1 and 16).
##
## The report for the UI: {spoiled: [id], sold, total, contracts: [{client_name,
## pieces: [{id, def_id, name, state, shape, weight_value}], groups: [{def_id, name,
## state, count, ids, shape, weight_value}],
## pay, bonus, has_bonus, bonus_met, breach, insurance}], ledger: {deliveries, bonuses,
## insurance, breaches, sold, scrap_cleared, fuel_fee, net}, credits_before,
## credits_after} (SPEC Section 20.4).


## Does the arrival: spoil, delivery, bonus, breach, and the report (SPEC Section 16).
static func arrive(run: Run) -> void:
	var report := {
		"spoiled": [], "sold": run.last_warp.get("sold_credits", 0), "total": 0, "contracts": []
	}
	for c in spoil_check(run):
		run.stats["scrapped"] += 1
		c.kind = Defs.KIND_SCRAP
		c.spoiled = true
		report["spoiled"].append(c.id)
	var leaving: Array[int] = []
	var carried: Array[int] = []
	for k in run.contracts:
		if not k.accepted:
			continue
		if k.jumps_left > 1:
			# A long contract: its freight stays until its last jump (SPEC Section 30.2).
			k.jumps_left -= 1
			carried.append(k.id)
			continue
		var res := {
			"client_name": k.template.client_name,
			"pieces": [],
			"pay": 0,
			"bonus": 0,
			"has_bonus": k.template.has_bonus(),
			"bonus_met": false,
			"breach": 0,
			"insurance": 0,
			"penalty": 0,
		}
		var delivered: Array[Cargo] = []
		for i in k.cargo.size():
			var id := k.cargo[i]
			var state := ""
			var c: Cargo = run.cargo.get(id)
			if id in k.breached:
				state = Defs.PIECE_BREACHED
				res["breach"] += run.cat.price("breach_fee")
			elif c == null:
				state = Defs.PIECE_LOST
				res["insurance"] += _insurance(run, k)
			elif c.spoiled:
				state = Defs.PIECE_SPOILED
				res["insurance"] += _insurance(run, k)
			elif c.kind == Defs.KIND_SCRAP:
				state = Defs.PIECE_SCRAP
				res["insurance"] += _insurance(run, k)
			else:
				state = Defs.PIECE_DELIVERED
				res["pay"] += k.template.pay
				delivered.append(c)
			var def: CargoDef = run.cat.cargo[k.template.freight[i]]
			(
				res["pieces"]
				. append(
					{
						"id": id,
						"def_id": def.id,
						"name": def.name,
						"state": state,
						"shape": Shapes.to_view(def.shape),
						"weight_value": run.cat.weight_value(def.weight),
					}
				)
			)
		# A VIP contract pays its penalty when a piece is not delivered (SPEC Section 30.1).
		if delivered.size() != k.cargo.size():
			res["penalty"] = k.template.penalty
		if bonus_met(run, k, delivered):
			res["bonus_met"] = true
			res["bonus"] = k.template.bonus["pay"]
		for c in delivered:
			leaving.append(c.id)
		run.stats["delivered"] += delivered.size()
		report["total"] += (
			res["pay"] + res["bonus"] + res["insurance"] - res["breach"] - res["penalty"]
		)
		res["groups"] = groups(res["pieces"])
		report["contracts"].append(res)
	for id in leaving:
		run.remove_cargo(id)
	for c: Cargo in run.cargo.values():
		if not c.contract in carried:
			c.contract = 0
		c.spoiled = false
	run.credits += report["total"]
	_ledger(run, report)
	run.last_arrival = report
	run.phase = Defs.PHASE_ARRIVAL
	run.say(_line_event(run, report))


## Returns each Perishable cargo that is not next to a Cooler (SPEC Section 12.1).
static func spoil_check(run: Run) -> Array[Cargo]:
	var out: Array[Cargo] = []
	var hold := run.hold_cargo()
	for c in hold:
		if c.has(Defs.TRAIT_PERISHABLE) and not cooled(c, hold) and not cryo(run, c):
			out.append(c)
	return out


## Reports whether the Cryo Line mod cools a cargo: a cell in the left column
## (SPEC Section 27.2).
static func cryo(run: Run, c: Cargo) -> bool:
	if not run.has_mod(Defs.MOD_CRYO_LINE):
		return false
	for cell in c.cells():
		if cell.x == 0:
			return true
	return false


## Returns the insurance of a lost piece: half of its pay, rounded down, with the
## Insurance mod (SPEC Section 27.2).
static func _insurance(run: Run, k: Contract) -> int:
	return k.template.pay / 2 if run.has_mod(Defs.MOD_INSURANCE) else 0


static func cooled(c: Cargo, hold: Array[Cargo]) -> bool:
	for o in hold:
		if o.has(Defs.TRAIT_COOLER) and Cargo.next_to(c, o):
			return true
	return false


## Reports whether the bonus condition of a contract is true at the arrival.
## delivered has the pieces that are delivered (SPEC Section 15.3).
static func bonus_met(run: Run, k: Contract, delivered: Array[Cargo]) -> bool:
	var b := k.template.bonus
	# Each piece must be delivered: one piece that is scrap, spoiled, lost, or
	# breached cancels the bonus.
	if b.is_empty() or delivered.size() != k.cargo.size() or not k.breached.is_empty():
		return false
	match b["type"]:
		Defs.BONUS_ALL_INTACT:
			return delivered.size() == k.cargo.size()
		Defs.BONUS_ZONE:
			for d in delivered:
				for cell in d.cells():
					if not k.template.in_zone(cell, run.columns, run.rows):
						return false
			return true
		Defs.BONUS_NOT_NEXT_TO:
			for d in delivered:
				for o in run.hold_cargo():
					if o.has(b["trait"]) and Cargo.next_to(d, o):
						return false
			return true
	return false


## Selects the line event of an arrival (SPEC Section 22).
static func _line_event(run: Run, report: Dictionary) -> String:
	var explosions := 0
	var leaks := 0
	var breaks := 0
	for s: Dictionary in run.last_warp.get("steps", []):
		for r: Dictionary in s["reactions"]:
			match r["kind"]:
				Defs.REACT_EXPLOSION:
					explosions += 1
				Defs.REACT_LEAK:
					leaks += 1
				Defs.REACT_BREAK, Defs.REACT_SHORT, Defs.REACT_BLAST:
					breaks += 1
	var pieces := 0
	for c: Dictionary in report["contracts"]:
		pieces += c["pieces"].size()
	if explosions >= 2:
		return Defs.LINE_CHAIN
	if explosions == 1:
		return Defs.LINE_EXPLOSION
	if leaks > 0:
		return Defs.LINE_LEAK
	if not report["spoiled"].is_empty():
		return Defs.LINE_SPOIL
	if breaks > 0:
		return Defs.LINE_BREAK
	if pieces == 0:
		return Defs.LINE_EMPTY
	return Defs.LINE_ALL_INTACT


## Returns the pieces in groups of the same freight and the same state, in the order
## of the pieces: [{def_id, name, state, count, ids}] (SPEC Section 20.4).
static func groups(pieces: Array) -> Array:
	var out := []
	for p: Dictionary in pieces:
		var found := false
		for g: Dictionary in out:
			if g["def_id"] == p["def_id"] and g["state"] == p["state"]:
				g["ids"].append(p["id"])
				g["count"] += 1
				found = true
				break
		if not found:
			(
				out
				. append(
					{
						"def_id": p["def_id"],
						"name": p["name"],
						"shape": p.get("shape", []),
						"weight_value": p.get("weight_value", 0),
						"state": p["state"],
						"count": 1,
						"ids": [p["id"]],
					}
				)
			)
	return out


## Adds the ledger and the credits before and after to the report (SPEC Section 20.4).
static func _ledger(run: Run, report: Dictionary) -> void:
	var ledger := {"deliveries": 0, "bonuses": 0, "insurance": 0, "breaches": 0}
	for res: Dictionary in report["contracts"]:
		ledger["deliveries"] += res["pay"]
		ledger["bonuses"] += res["bonus"]
		ledger["insurance"] += res["insurance"]
		ledger["breaches"] += res["breach"]
		ledger["penalties"] = ledger.get("penalties", 0) + res["penalty"]
	ledger["penalties"] = ledger.get("penalties", 0)
	ledger["sold"] = report["sold"]
	ledger["scrap_cleared"] = run.last_warp.get("scrap_cleared", 0)
	ledger["fuel_fee"] = run.last_warp.get("fuel_fee", 0)
	report["credits_before"] = run.last_warp.get("credits", run.credits)
	report["credits_after"] = run.credits
	ledger["net"] = report["credits_after"] - report["credits_before"]
	report["ledger"] = ledger
