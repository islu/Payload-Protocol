class_name Arrival
## The arrival and the cold chain (SPEC Sections 12.1 and 16).
##
## The report for the UI: {spoiled: [id], sold, total, contracts: [{client_name,
## pieces: [{id, name, state}], pay, bonus, has_bonus, bonus_met, breach}]}.


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
	for k in run.contracts:
		if not k.accepted:
			continue
		var res := {
			"client_name": k.template.client_name,
			"pieces": [],
			"pay": 0,
			"bonus": 0,
			"has_bonus": k.template.has_bonus(),
			"bonus_met": false,
			"breach": 0,
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
			elif c.spoiled:
				state = Defs.PIECE_SPOILED
			elif c.kind == Defs.KIND_SCRAP:
				state = Defs.PIECE_SCRAP
			else:
				state = Defs.PIECE_DELIVERED
				res["pay"] += k.template.pay
				delivered.append(c)
			res["pieces"].append(
				{"id": id, "name": run.cat.cargo[k.template.freight[i]].name, "state": state}
			)
		if bonus_met(run, k, delivered):
			res["bonus_met"] = true
			res["bonus"] = k.template.bonus["pay"]
		for c in delivered:
			leaving.append(c.id)
		run.stats["delivered"] += delivered.size()
		report["total"] += res["pay"] + res["bonus"] - res["breach"]
		report["contracts"].append(res)
	for id in leaving:
		run.remove_cargo(id)
	for c: Cargo in run.cargo.values():
		c.contract = 0
		c.spoiled = false
	run.credits += report["total"]
	run.last_arrival = report
	run.phase = Defs.PHASE_ARRIVAL
	run.say(_line_event(run, report))


## Returns each Perishable cargo that is not next to a Cooler (SPEC Section 12.1).
static func spoil_check(run: Run) -> Array[Cargo]:
	var out: Array[Cargo] = []
	var hold := run.hold_cargo()
	for c in hold:
		if c.has(Defs.TRAIT_PERISHABLE) and not cooled(c, hold):
			out.append(c)
	return out


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
