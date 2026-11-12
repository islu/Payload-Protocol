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
## Each sector: {toll: int, hazard_steps: Array of Vector2i(min, max), kit_pool: PackedStringArray,
## fork: bool}. fork is true when the last step of each jump is a fork step (SPEC Section 18).
var sectors: Array[Dictionary] = []

## terms.json: the words of the rules.
var terms: Dictionary = {}
## CargoDef by ID.
var cargo: Dictionary = {}
var contracts: Array[ContractTemplate] = []
## The lines of each event: PackedStringArray by event.
var lines: Dictionary = {}


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
	for s: Dictionary in r.get("sectors", []):
		var steps: Array[Vector2i] = []
		for span in s.get("hazard_steps", []):
			steps.append(Vector2i(int(span[0]), int(span[1])))
		var pool: PackedStringArray = []
		for id in s.get("kit_pool", []):
			pool.append(str(id))
		(
			sectors
			. append(
				{
					"toll": int(s.get("toll", 0)),
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


## Returns the number of jumps of a sector (1-based).
func jumps(sector: int) -> int:
	return sectors[sector - 1]["hazard_steps"].size()


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


func _check_rules() -> void:
	if sectors.is_empty():
		_fail("rules: no sectors")
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
	if offer_contracts < 1 or offer_kit < 1:
		_fail("rules: the offers must be 1 or more")
	for i in sectors.size():
		var s: Dictionary = sectors[i]
		if s["hazard_steps"].is_empty():
			_fail("rules: sector %d has no jumps" % (i + 1))
		for span: Vector2i in s["hazard_steps"]:
			if span.x < 1 or span.y < span.x or span.y > 3:
				_fail("rules: sector %d: the hazard steps are not 1 to 3" % (i + 1))
		if s["kit_pool"].is_empty():
			_fail("rules: sector %d has no kit pool" % (i + 1))
		for id: String in s["kit_pool"]:
			if not cargo.has(id) or cargo[id].kind != Defs.KIND_KIT:
				_fail("rules: sector %d: %s is not a kit" % [i + 1, id])


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
	if t.sectors.is_empty():
		_fail("contract %s: no sectors" % t.id)
	for s in t.sectors:
		if s < 1 or s > sectors.size():
			_fail("contract %s: the sector %d is not valid" % [t.id, s])
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
