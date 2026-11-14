class_name StationEvents
## The rules of the events of a station and of the mod choice (SPEC Sections 26 and
## 27). The actions are on Run: choose_event() and choose_mod().


## Selects the event of a new station, if it has one (SPEC Section 26.1).
static func start_event(run: Run) -> void:
	run.event = null
	var cat := run.cat
	var due := run.jump == cat.event_station
	if run.jump == cat.chance_station:
		due = run.rng.randi_range(1, 100) <= cat.chance_percent
	if not due:
		return
	var pool: Array = []
	for e in cat.events:
		if not e.id in run.events_seen:
			pool.append(e)
	if pool.is_empty():
		return
	run.event = pool[run.rng.randi_range(0, pool.size() - 1)]
	run.events_seen.append(run.event.id)
	run.phase = Defs.PHASE_EVENT


## Returns why the player cannot select a choice of the open event, or "". A choice
## with a cost needs the credits, and each of its effects must be able to happen
## (SPEC Section 26.2).
static func choice_error(run: Run, index: int) -> String:
	var choice: Dictionary = run.event.choices[index]
	if choice["cost"] == 0:
		return ""
	if run.credits < 0:
		return Run.IN_DEBT_TEXT
	if choice["cost"] > run.credits:
		return Run.NOT_ENOUGH_TEXT
	for f: Dictionary in choice["effects"]:
		if f["type"] == Defs.EFFECT_CLAMP and run.clamps >= run.cat.price("clamp_max"):
			return Run.CLAMPS_MAXED_TEXT
		if f["type"] == Defs.EFFECT_MOD and mod_pool(run).is_empty():
			return Run.NO_MOD_LEFT_TEXT
	return ""


## Does one effect of an event choice (SPEC Section 26.2). It returns true for a mod
## effect: the caller starts the mod choice after all effects.
static func do_effect(run: Run, f: Dictionary) -> bool:
	var cat := run.cat
	match f["type"]:
		Defs.EFFECT_CREDITS:
			run.credits += f["amount"]
		Defs.EFFECT_KIT:
			run.new_cargo(cat.cargo[f["cargo"]])
		Defs.EFFECT_CLAMP:
			run.clamps = mini(run.clamps + 1, cat.price("clamp_max"))
		Defs.EFFECT_SCRAP:
			run.new_cargo(cat.cargo[f["cargo"]]).kind = Defs.KIND_SCRAP
		Defs.EFFECT_CONTRACT:
			run.add_contract(cat.contract(f["contract"]))
		Defs.EFFECT_PAYMENT:
			run.payment_cut += f["amount"]
		Defs.EFFECT_MOD:
			return true
	return false


## Returns the IDs of the mods that the ship does not have.
static func mod_pool(run: Run) -> Array:
	var pool: Array = []
	for id in Defs.MODS:
		if run.cat.mods.has(id) and not id in run.mods:
			pool.append(id)
	return pool


## Starts a mod choice with the mods that the ship does not have. With no mod left,
## nothing happens (SPEC Section 27.1).
static func offer_mods(run: Run) -> void:
	var pool := mod_pool(run)
	if pool.is_empty():
		return
	run.mod_offer = PackedStringArray(Run.pick_n(run.rng, pool, run.cat.mod_offers))
	run.phase = Defs.PHASE_MOD
