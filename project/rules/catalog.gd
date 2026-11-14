class_name Catalog
extends RefCounted
## All definitions of the game data, and the checks of the data (content.md).
## It does not read files: the caller gives it the parsed JSON.

## The number of lines that each event of the pilot needs (content.md).
const MIN_LINES := 4

var errors: PackedStringArray = []

# rules.json (SPEC Sections 14 to 19)
var start_credits: int
var start_clamps: int
var start_columns: int
var start_rows: int
var max_columns: int
var max_rows: int
var weights: Dictionary = {}
var break_limits: Dictionary = {}
var offer_contracts: int
var offer_kit: int
var prices: Dictionary = {}
# The mass of SPEC Section 25
var mass_limit: int
var over_percent: int
var fuel_fee: int
var reinforce_amount: int
## The offers of a station have this percent of the mass limit or more (content.md).
var offer_mass_percent: int
## Each leg: {payment: int, hazard_steps: Array of Vector2i(min, max), kit_pool: PackedStringArray,
## fork: bool}. fork is true when the last step of each jump is a fork step (SPEC Section 18).
var legs: Array[Dictionary] = []
## The station of each leg that always has an event, the station with a chance, and
## the chance in percent (SPEC Section 26.1).
var event_station: int
var chance_station: int
var chance_percent: int
## The number of mods in a mod choice (SPEC Section 27.1).
var mod_offers: int

## terms.json: the words of the rules.
var terms: Dictionary = {}
## CargoDef by ID.
var cargo: Dictionary = {}
var contracts: Array[ContractTemplate] = []
## The lines of each event: PackedStringArray by event.
var lines: Dictionary = {}
## The events of the stations, in the order of the IDs (SPEC Section 26).
var events: Array[EventDef] = []
## The name and the rule text of each mod: {name, text} by ID (SPEC Section 27).
var mods: Dictionary = {}


## Makes a catalog from the parsed data: {rules, terms, cargo, contracts, lines}.
## cargo, contracts, and lines map each file name (no extension) to its data.
## Read errors before you use the catalog.
static func from_data(data: Dictionary) -> Catalog:
	var cat := Catalog.new()
	cat._read_rules(data.get("rules", {}))
	cat.terms = data.get("terms", {})
	var files: Dictionary = data.get("cargo", {})
	for name: String in _sorted(files):
		var d := CargoDef.from_dict(files[name])
		cat._check_id(d.id, name, "cargo")
		cat.cargo[d.id] = d
	files = data.get("contracts", {})
	for name: String in _sorted(files):
		var t := ContractTemplate.from_dict(files[name])
		cat._check_id(t.id, name, "contract")
		cat.contracts.append(t)
	files = data.get("lines", {})
	for name: String in _sorted(files):
		var line_set: Dictionary = files[name]
		cat._check_id(str(line_set.get("id", "")), name, "lines")
		var texts: PackedStringArray = []
		for line in line_set.get("lines", []):
			texts.append(str(line.get("text", "")))
		cat.lines[name] = texts
	files = data.get("events", {})
	for name: String in _sorted(files):
		var e := EventDef.from_dict(files[name])
		cat._check_id(e.id, name, "event")
		cat.events.append(e)
	files = data.get("mods", {})
	for name: String in _sorted(files):
		var m: Dictionary = files[name]
		cat._check_id(str(m.get("id", "")), name, "mod")
		cat.mods[name] = {"name": str(m.get("name", "")), "text": str(m.get("text", ""))}
	cat._check()
	return cat


static func _sorted(d: Dictionary) -> Array:
	var keys := d.keys()
	keys.sort()
	return keys


func _read_rules(r: Dictionary) -> void:
	var start: Dictionary = r.get("start", {})
	start_credits = int(start.get("credits", 0))
	start_clamps = int(start.get("clamps", 0))
	start_columns = int(start.get("hold", {}).get("columns", 0))
	start_rows = int(start.get("hold", {}).get("rows", 0))
	max_columns = int(r.get("hold_max", {}).get("columns", 0))
	max_rows = int(r.get("hold_max", {}).get("rows", 0))
	for k: String in r.get("weights", {}):
		weights[k] = int(r["weights"][k])
	for k: String in r.get("break_limits", {}):
		break_limits[k] = int(r["break_limits"][k])
	offer_contracts = int(r.get("offers", {}).get("contracts", 0))
	offer_kit = int(r.get("offers", {}).get("kit", 0))
	for k: String in r.get("prices", {}):
		prices[k] = int(r["prices"][k])
	var mass: Dictionary = r.get("mass", {})
	mass_limit = int(mass.get("limit", 0))
	over_percent = int(mass.get("over_percent", 0))
	fuel_fee = int(mass.get("fuel_fee", 0))
	reinforce_amount = int(mass.get("reinforce", 0))
	offer_mass_percent = int(mass.get("offer_percent", 0))
	var ev: Dictionary = r.get("events", {})
	event_station = int(ev.get("station", 0))
	chance_station = int(ev.get("chance_station", 0))
	chance_percent = int(ev.get("chance_percent", 0))
	mod_offers = int(r.get("mod_offers", 0))
	for s: Dictionary in r.get("legs", []):
		var steps: Array[Vector2i] = []
		for span in s.get("hazard_steps", []):
			steps.append(Vector2i(int(span[0]), int(span[1])))
		var pool: PackedStringArray = []
		for id in s.get("kit_pool", []):
			pool.append(str(id))
		(
			legs
			. append(
				{
					"payment": int(s.get("payment", 0)),
					"hazard_steps": steps,
					"kit_pool": pool,
					"fork": bool(s.get("fork", false)),
				}
			)
		)


## Returns the weight value of a weight class (SPEC Section 6.1).
func weight_value(weight: String) -> int:
	return weights.get(weight, 0)


## Returns the break limit of a trait (SPEC Section 7).
func break_limit(trait_id: String) -> int:
	return break_limits.get(trait_id, 0)


## Returns a price of rules.json (SPEC Section 17.5).
func price(key: String) -> int:
	return prices.get(key, 0)


## Returns the number of jumps of a leg (1-based).
func jumps(leg: int) -> int:
	return legs[leg - 1]["hazard_steps"].size()


## Returns the name of a term: terms[group][id].name.
func term_name(group: String, id: String) -> String:
	return str(terms.get(group, {}).get(id, {}).get("name", id))


## Returns the text of a term: terms[group][id].text.
func term_text(group: String, id: String) -> String:
	return str(terms.get(group, {}).get(id, {}).get("text", ""))


func _fail(message: String) -> void:
	errors.append(message)


func _check_id(id: String, file: String, what: String) -> void:
	if id != file:
		_fail("%s %s: the id %s is not the file name" % [what, file, id])


func _check() -> void:
	_check_rules()
	_check_terms()
	for id: String in _sorted(cargo):
		_check_cargo(cargo[id])
	for t in contracts:
		_check_contract(t)
	for e in Defs.LINE_EVENTS:
		if lines.get(e, PackedStringArray()).size() < MIN_LINES:
			_fail("lines: the event %s needs %d lines at least" % [e, MIN_LINES])
	for e in events:
		_check_event(e)
	for id in Defs.MODS:
		if mods.get(id, {}).get("name", "") == "" or mods.get(id, {}).get("text", "") == "":
			_fail("mods: the mod %s needs a name and a text" % id)
	for id: String in mods:
		if not id in Defs.MODS:
			_fail("mods: %s is not a mod of the code" % id)


func _check_rules() -> void:
	if legs.is_empty():
		_fail("rules: no legs")
	if start_columns < 1 or start_rows < 1 or max_columns < start_columns or max_rows < start_rows:
		_fail("rules: the hold sizes are not valid")
	for w in Defs.WEIGHTS:
		if weight_value(w) < 1:
			_fail("rules: the weight %s needs a value" % w)
	for t in Defs.LIMIT_TRAITS:
		if break_limit(t) < 1:
			_fail("rules: the trait %s needs a break limit" % t)
	if price("sell_divisor") < 1:
		_fail("rules: sell_divisor must be 1 or more")
	if mass_limit < 1 or fuel_fee < 0 or reinforce_amount < 1 or over_percent < 0:
		_fail("rules: the mass values are not valid")
	if offer_contracts < 1 or offer_kit < 1 or mod_offers < 1:
		_fail("rules: the offers must be 1 or more")
	if chance_percent < 0 or chance_percent > 100:
		_fail("rules: the chance of an event must be 0 to 100")
	for i in legs.size():
		var s: Dictionary = legs[i]
		if s["hazard_steps"].is_empty():
			_fail("rules: leg %d has no jumps" % (i + 1))
		for span: Vector2i in s["hazard_steps"]:
			if span.x < 1 or span.y < span.x or span.y > 3:
				_fail("rules: leg %d: the hazard steps are not 1 to 3" % (i + 1))
		if s["kit_pool"].is_empty():
			_fail("rules: leg %d has no kit pool" % (i + 1))
		for id: String in s["kit_pool"]:
			if not cargo.has(id) or cargo[id].kind != Defs.KIND_KIT:
				_fail("rules: leg %d: %s is not a kit" % [i + 1, id])


func _check_terms() -> void:
	for t in Defs.TRAITS:
		if term_text("traits", t) == "" or not terms.get("traits", {}).has(t):
			_fail("terms: the trait %s needs a name and a text" % t)
	var groups := {
		"kinds": Defs.KINDS,
		"weights": Defs.WEIGHTS,
		"directions": Defs.DIRECTIONS,
		"sides": Defs.SIDES,
	}
	for group: String in groups:
		for id: String in groups[group]:
			if not terms.get(group, {}).has(id):
				_fail("terms: the %s %s needs a name" % [group, id])
	for b in Defs.BONUSES:
		if term_text("bonuses", b) == "":
			_fail("terms: the bonus %s needs a text" % b)


func _check_cargo(d: CargoDef) -> void:
	if d.kind != Defs.KIND_FREIGHT and d.kind != Defs.KIND_KIT:
		_fail("cargo %s: the kind must be freight or kit" % d.id)
	if not d.weight in Defs.WEIGHTS:
		_fail("cargo %s: the weight %s is not valid" % [d.id, d.weight])
	if d.shape.size() < 1 or d.shape.size() > 5:
		_fail("cargo %s: a shape has 1 to 5 cells" % d.id)
	var seen := {}
	for c in d.shape:
		if c.x < 0 or c.y < 0 or seen.has(c):
			_fail("cargo %s: the shape has a bad cell %s" % [d.id, c])
		seen[c] = true
	if not Shapes.connected(d.shape):
		_fail("cargo %s: the cells of the shape are not connected" % d.id)
	if d.traits.size() > 2:
		_fail("cargo %s: two traits at most" % d.id)
	for t in d.traits:
		if not t in Defs.TRAITS:
			_fail("cargo %s: the trait %s is not valid" % [d.id, t])
	if d.kind == Defs.KIND_KIT and d.price < 1:
		_fail("cargo %s: a kit needs a price" % d.id)


func _check_contract(t: ContractTemplate) -> void:
	if t.client_name == "" or t.pay < 1 or t.freight.is_empty():
		_fail("contract %s: it needs a client_name, a pay, and freight" % t.id)
	for s in t.legs:
		if s < 1 or s > legs.size():
			_fail("contract %s: the leg %d is not valid" % [t.id, s])
	for id in t.freight:
		if not cargo.has(id) or cargo[id].kind != Defs.KIND_FREIGHT:
			_fail("contract %s: %s is not a freight" % [t.id, id])
	if not t.has_bonus():
		return
	if t.bonus["pay"] < 1:
		_fail("contract %s: the bonus needs a pay" % t.id)
	match t.bonus["type"]:
		Defs.BONUS_ALL_INTACT:
			pass
		Defs.BONUS_ZONE:
			if t.bonus["size"] < 1 or not t.bonus["side"] in Defs.SIDES:
				_fail("contract %s: the zone is not valid" % t.id)
		Defs.BONUS_NOT_NEXT_TO:
			if not t.bonus["trait"] in Defs.TRAITS:
				_fail("contract %s: the bonus trait %s is not valid" % [t.id, t.bonus["trait"]])
		_:
			_fail("contract %s: the bonus type %s is not valid" % [t.id, t.bonus["type"]])


## Checks an event: 2 or 3 choices, one free choice, and valid effects (SPEC Section 26.2).
func _check_event(e: EventDef) -> void:
	if e.name == "" or e.text == "":
		_fail("event %s: it needs a name and a text" % e.id)
	if e.choices.size() < 2 or e.choices.size() > 3:
		_fail("event %s: 2 or 3 choices" % e.id)
	var free := false
	for c: Dictionary in e.choices:
		if c["text"] == "":
			_fail("event %s: each choice needs a text" % e.id)
		free = free or c["cost"] == 0
		for f: Dictionary in c["effects"]:
			_check_effect(e.id, f)
	if not free:
		_fail("event %s: one choice must have no cost" % e.id)


func _check_effect(event_id: String, f: Dictionary) -> void:
	match f["type"]:
		Defs.EFFECT_KIT:
			if not cargo.has(f["cargo"]) or cargo[f["cargo"]].kind != Defs.KIND_KIT:
				_fail("event %s: %s is not a kit" % [event_id, f["cargo"]])
		Defs.EFFECT_SCRAP:
			if not cargo.has(f["cargo"]):
				_fail("event %s: %s is not a cargo" % [event_id, f["cargo"]])
		Defs.EFFECT_CONTRACT:
			if contract(f["contract"]) == null:
				_fail("event %s: %s is not a contract" % [event_id, f["contract"]])
		Defs.EFFECT_CREDITS, Defs.EFFECT_PAYMENT:
			if f["amount"] == 0:
				_fail("event %s: the %s effect needs an amount" % [event_id, f["type"]])
		Defs.EFFECT_CLAMP, Defs.EFFECT_MOD:
			pass
		_:
			_fail("event %s: the effect %s is not valid" % [event_id, f["type"]])


## Returns the contract template with an ID, or null.
func contract(id: String) -> ContractTemplate:
	for t in contracts:
		if t.id == id:
			return t
	return null
