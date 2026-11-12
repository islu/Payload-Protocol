class_name Run
extends RefCounted
## One run: its state and the actions of the player (SPEC Sections 3, 8, 13 to 19).
##
## Each action returns "" when it works, or an error text for the player. A
## failed action changes nothing. The run uses no floats for game values, and
## its random numbers come from the seed only (SPEC Section 3).

const NOT_AT_STATION_TEXT := "You can do that only at a station."
const NO_CARGO_TEXT := "There is no such cargo."
const NO_FIT_TEXT := "The cargo does not fit there."
const SCRAP_TO_DOCK_TEXT := "Scrap cannot go on the dock."
const NOT_IN_HOLD_TEXT := "That cargo is not in the hold."
const NO_FREE_CLAMP_TEXT := "You have no free clamp."
const CLAMPED_TEXT := "That cargo has a clamp already."
const NOT_CLAMPED_TEXT := "That cargo has no clamp."
const BAD_ROTATION_TEXT := "The rotation is not valid."
const NO_CONTRACT_TEXT := "There is no such contract."
const ACCEPTED_TEXT := "That contract is accepted already."
const NOT_ACCEPTED_TEXT := "That contract is not accepted."
const NO_OFFER_TEXT := "There is no such offer."
const OFFER_BOUGHT_TEXT := "That offer is sold already."
const NOT_ENOUGH_TEXT := "You do not have enough credits."
const IN_DEBT_TEXT := "You cannot buy while your credits are below 0."
const CLAMPS_MAXED_TEXT := "You have the most clamps already."
const HOLD_MAXED_TEXT := "The hold cannot grow more that way."
const BAD_AXIS_TEXT := "Select a column or a row."
const CANNOT_SELL_TEXT := "You can sell only kit."
const NOT_SCRAP_TEXT := "That cargo is not scrap."
const NOT_ARRIVED_TEXT := "The ship has not arrived yet."
const NOT_AT_TOLL_TEXT := "You are not at a toll gate."

## The places that a rotation in place tries, in order, when the new shape does not
## fit: left, right, up, down, then the diagonals (SPEC Section 8.2).
const ROTATE_KICKS: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(0, -1),
	Vector2i(0, 1),
	Vector2i(-1, -1),
	Vector2i(1, -1),
	Vector2i(-1, 1),
	Vector2i(1, 1),
]

var cat: Catalog
var rng := RandomNumberGenerator.new()
var line_rng := RandomNumberGenerator.new()

var seed_value: int
var phase: String
var sector: int = 1
var jump: int = 1
var credits: int
var clamps: int
var columns: int
var rows: int
## Cargo by ID: in the hold and on the dock.
var cargo: Dictionary = {}
## The IDs of the cargo on the dock, in order (SPEC Section 8.1).
var dock: Array[int] = []

var contracts: Array[Contract] = []
## The kit offers: {def: CargoDef, bought: bool} (SPEC Section 17.1).
var shop: Array[Dictionary] = []
var rerolls: int = 0
var upgrades: int = 0
var hazard: PackedStringArray = []

var last_warp: Dictionary = {}
var last_arrival: Dictionary = {}
var won := false
var stats := {"delivered": 0, "scrapped": 0, "explosions": 0}
## The line of the pilot now (SPEC Section 22).
var line: String = ""

## The charges of the Shields in this jump, by ID (SPEC Section 12.2).
var charges: Dictionary = {}

var _next_cargo: int = 0
var _next_contract: int = 0
var _last_line: Dictionary = {}


## Starts a run with the start values of rules.json (SPEC Section 14).
func _init(catalog: Catalog, run_seed: int) -> void:
	cat = catalog
	seed_value = run_seed
	rng.seed = run_seed
	line_rng.seed = run_seed ^ 0x5DEECE66D
	credits = cat.start_credits
	clamps = cat.start_clamps
	columns = cat.start_columns
	rows = cat.start_rows
	_open_station()


# --- Phases (SPEC Sections 3 and 19) ---


## Opens the station of the next jump: contracts, the shop, and the hazard
## (SPEC Sections 15, 17, and 18). The hazard is fixed now.
func _open_station() -> void:
	phase = Defs.PHASE_STATION
	rerolls = 0
	last_warp = {}
	last_arrival = {}
	_offer_contracts()
	_offer_kit()
	hazard = _make_hazard()
	say(Defs.LINE_HAZARD)


## Starts the jump: the dock, each shift step, and the arrival (SPEC Sections 9 and 16).
func warp() -> String:
	if phase != Defs.PHASE_STATION:
		return NOT_AT_STATION_TEXT
	var warp_log := {"sold": [], "sold_credits": 0, "before": [], "steps": []}
	_leave_dock(warp_log)
	# The hold before the first shift step, so that the UI can play the log (SPEC Section 20.3).
	warp_log["before"] = RunView.hold_views(self)
	charges = {}
	for c in hold_cargo():
		if c.has(Defs.TRAIT_SHIELD):
			charges[c.id] = 1
	for d in hazard:
		warp_log["steps"].append(Shift.step(self, d))
	last_warp = warp_log
	Arrival.arrive(self)
	return ""


## Leaves the arrival report: to the next station, or to the toll gate after
## the last jump of a sector (SPEC Sections 19.1 and 20.4).
func continue_run() -> String:
	if phase != Defs.PHASE_ARRIVAL:
		return NOT_ARRIVED_TEXT
	if jump >= cat.jumps(sector):
		phase = Defs.PHASE_TOLL
		say(Defs.LINE_TOLL)
		return ""
	jump += 1
	_open_station()
	return ""


## Returns the toll of the sector now (SPEC Section 19.1).
func toll() -> int:
	return cat.sectors[sector - 1]["toll"]


## Pays the toll. If the credits are less than the toll, the run ends in a loss
## (SPEC Section 19).
func pay_toll() -> String:
	if phase != Defs.PHASE_TOLL:
		return NOT_AT_TOLL_TEXT
	if credits < toll():
		_end(false)
		return ""
	credits -= toll()
	if sector >= cat.sectors.size():
		_end(true)
		return ""
	sector += 1
	jump = 1
	_open_station()
	return ""


func _end(win: bool) -> void:
	phase = Defs.PHASE_END
	won = win
	say(Defs.LINE_WIN if win else Defs.LINE_LOSE)


## The score is the credits after the last toll (SPEC Section 19.2).
func score() -> int:
	return credits if won else 0


# --- Hold and placement (SPEC Sections 5, 8, and 13) ---


## Makes a cargo on the dock (SPEC Section 8.1).
func new_cargo(def: CargoDef) -> Cargo:
	_next_cargo += 1
	var c := Cargo.new(_next_cargo, def)
	cargo[c.id] = c
	dock.append(c.id)
	return c


## Removes a cargo from the hold or the dock. Its clamp goes back (SPEC Section 13).
func remove_cargo(id: int) -> void:
	cargo.erase(id)
	dock.erase(id)


## Returns the cargo in the hold, in the order of the IDs.
func hold_cargo() -> Array[Cargo]:
	var out: Array[Cargo] = []
	var ids := cargo.keys()
	ids.sort()
	for id: int in ids:
		if cargo[id].in_hold:
			out.append(cargo[id])
	return out


## Returns the ID of the cargo in each cell of the hold that has one.
func occupancy() -> Dictionary:
	var occ := {}
	for c in hold_cargo():
		for cell in c.cells():
			occ[cell] = c.id
	return occ


func inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < columns and c.y < rows


## Reports whether a cargo fits at a place. It ignores the cargo itself (SPEC Section 8.3).
func fits(c: Cargo, pos: Vector2i, rot: int) -> bool:
	var occ := occupancy()
	for cell in Shapes.cells_at(c.def.shape, rot, pos):
		if not inside(cell) or occ.get(cell, c.id) != c.id:
			return false
	return true


## Reports whether a drop of a cargo at a place is valid (SPEC Section 8.3).
func can_place(id: int, pos: Vector2i, rot: int) -> bool:
	return (
		phase == Defs.PHASE_STATION
		and cargo.has(id)
		and rot >= 0
		and rot < 4
		and fits(cargo[id], pos, rot)
	)


## Returns the error of an action on a cargo at the station, or "".
func _station_cargo_error(id: int) -> String:
	if phase != Defs.PHASE_STATION:
		return NOT_AT_STATION_TEXT
	if not cargo.has(id):
		return NO_CARGO_TEXT
	return ""


## Moves a cargo from the dock or the hold to a place in the hold (SPEC Section 8.2).
## The clamp of the cargo moves with it.
func place_cargo(id: int, pos: Vector2i, rot: int) -> String:
	var err := _station_cargo_error(id)
	if err != "":
		return err
	if rot < 0 or rot > 3:
		return BAD_ROTATION_TEXT
	var c: Cargo = cargo[id]
	if not fits(c, pos, rot):
		return NO_FIT_TEXT
	c.pos = pos
	c.rot = rot
	if not c.in_hold:
		c.in_hold = true
		dock.erase(id)
	return ""


## Moves a cargo from the hold to the dock. Its clamp goes back (SPEC Sections 8.2 and 13).
func dock_cargo(id: int) -> String:
	var err := _station_cargo_error(id)
	if err != "":
		return err
	var c: Cargo = cargo[id]
	if c.kind == Defs.KIND_SCRAP:
		return SCRAP_TO_DOCK_TEXT
	if c.in_hold:
		c.in_hold = false
		c.clamped = false
		dock.append(id)
	return ""


## Rotates a cargo in the hold in its place. If the new shape does not fit, the
## cargo goes to the first place 1 cell away where it fits (SPEC Section 8.2).
func rotate_cargo(id: int) -> String:
	var err := _station_cargo_error(id)
	if err != "":
		return err
	var c: Cargo = cargo[id]
	if not c.in_hold:
		return NOT_IN_HOLD_TEXT
	var rot := (c.rot + 1) % 4
	for kick in ROTATE_KICKS:
		if fits(c, c.pos + kick, rot):
			c.pos += kick
			c.rot = rot
			return ""
	return NO_FIT_TEXT


## Returns the clamps that are not on a cargo (SPEC Section 13).
func free_clamps() -> int:
	var used := 0
	for c: Cargo in cargo.values():
		if c.clamped:
			used += 1
	return clamps - used


## Puts a clamp on a cargo in the hold (SPEC Section 13).
func clamp_cargo(id: int) -> String:
	var err := _station_cargo_error(id)
	if err != "":
		return err
	var c: Cargo = cargo[id]
	if not c.in_hold:
		return NOT_IN_HOLD_TEXT
	if c.clamped:
		return CLAMPED_TEXT
	if free_clamps() <= 0:
		return NO_FREE_CLAMP_TEXT
	c.clamped = true
	return ""


## Takes the clamp off a cargo (SPEC Section 13).
func unclamp_cargo(id: int) -> String:
	var err := _station_cargo_error(id)
	if err != "":
		return err
	if not cargo[id].clamped:
		return NOT_CLAMPED_TEXT
	cargo[id].clamped = false
	return ""


# --- Contracts (SPEC Section 15) ---


## Accepts a contract of the board. Its freight goes to the dock (SPEC Section 15.1).
func accept_contract(index: int) -> String:
	var err := _contract_error(index)
	if err != "":
		return err
	var k := contracts[index]
	if k.accepted:
		return ACCEPTED_TEXT
	k.accepted = true
	k.cargo.clear()
	for id in k.template.freight:
		var c := new_cargo(cat.cargo[id])
		c.contract = k.id
		k.cargo.append(c.id)
	return ""


## Cancels an accepted contract. Its freight leaves the hold and the dock, with
## no fee (SPEC Section 15.1).
func cancel_contract(index: int) -> String:
	var err := _contract_error(index)
	if err != "":
		return err
	var k := contracts[index]
	if not k.accepted:
		return NOT_ACCEPTED_TEXT
	for id in k.cargo:
		remove_cargo(id)
	k.accepted = false
	k.cargo.clear()
	return ""


func _contract_error(index: int) -> String:
	if phase != Defs.PHASE_STATION:
		return NOT_AT_STATION_TEXT
	if index < 0 or index >= contracts.size():
		return NO_CONTRACT_TEXT
	return ""


func contract_by_id(id: int) -> Contract:
	for k in contracts:
		if k.id == id:
			return k
	return null


## Selects the contracts of a new station from the templates of the sector. The
## offers must fit together in an empty hold (content.md).
func _offer_contracts() -> void:
	var pool: Array = []
	for t in cat.contracts:
		if sector in t.sectors:
			pool.append(t)
	var n := mini(cat.offer_contracts, pool.size())
	var picked: Array = []
	for attempt in 20:
		picked = pick_n(rng, pool, n)
		if attempt == 19 or _fits_empty(picked):
			break
	contracts.clear()
	for t: ContractTemplate in picked:
		_next_contract += 1
		contracts.append(Contract.new(_next_contract, t))


func _fits_empty(templates: Array) -> bool:
	var shapes: Array = []
	for t: ContractTemplate in templates:
		for id in t.freight:
			shapes.append(cat.cargo[id].shape)
	return Packing.packs(shapes, columns, rows, 20000)


# --- Shop (SPEC Section 17) ---


func _offer_kit() -> void:
	shop.clear()
	for id: String in pick_n(rng, Array(cat.sectors[sector - 1]["kit_pool"]), cat.offer_kit):
		shop.append({"def": cat.cargo[id], "bought": false})


## Takes a price from the credits (SPEC Section 17.5). It returns an error, or "".
func _pay(amount: int) -> String:
	if credits < 0:
		return IN_DEBT_TEXT
	if amount > credits:
		return NOT_ENOUGH_TEXT
	credits -= amount
	return ""


## Buys a kit offer. The kit goes to the dock (SPEC Section 17.1).
func buy_kit(index: int) -> String:
	if phase != Defs.PHASE_STATION:
		return NOT_AT_STATION_TEXT
	if index < 0 or index >= shop.size():
		return NO_OFFER_TEXT
	var o: Dictionary = shop[index]
	if o["bought"]:
		return OFFER_BOUGHT_TEXT
	var err := _pay(o["def"].price)
	if err != "":
		return err
	o["bought"] = true
	new_cargo(o["def"])
	return ""


## Returns the price of the next reroll at this station (SPEC Section 17.1).
func reroll_price() -> int:
	return cat.price("reroll_first") + cat.price("reroll_step") * rerolls


## Replaces the kit offers (SPEC Section 17.1).
func reroll() -> String:
	if phase != Defs.PHASE_STATION:
		return NOT_AT_STATION_TEXT
	var err := _pay(reroll_price())
	if err != "":
		return err
	rerolls += 1
	_offer_kit()
	return ""


## Adds one clamp (SPEC Section 17.2).
func buy_clamp() -> String:
	if phase != Defs.PHASE_STATION:
		return NOT_AT_STATION_TEXT
	if clamps >= cat.price("clamp_max"):
		return CLAMPS_MAXED_TEXT
	var err := _pay(cat.price("clamp"))
	if err != "":
		return err
	clamps += 1
	return ""


## Returns the price of the next hold upgrade (SPEC Section 17.2).
func upgrade_price() -> int:
	return cat.price("upgrade_first") + cat.price("upgrade_step") * upgrades


## Reports whether the hold can grow on an axis (SPEC Sections 5 and 17.2).
func can_upgrade(axis: String) -> bool:
	match axis:
		Defs.AXIS_COLUMN:
			return columns < cat.max_columns
		Defs.AXIS_ROW:
			return rows < cat.max_rows
	return false


## Adds one column at the right or one row at the bottom (SPEC Section 17.2).
func upgrade_hold(axis: String) -> String:
	if phase != Defs.PHASE_STATION:
		return NOT_AT_STATION_TEXT
	if axis != Defs.AXIS_COLUMN and axis != Defs.AXIS_ROW:
		return BAD_AXIS_TEXT
	if not can_upgrade(axis):
		return HOLD_MAXED_TEXT
	var err := _pay(upgrade_price())
	if err != "":
		return err
	upgrades += 1
	if axis == Defs.AXIS_COLUMN:
		columns += 1
	else:
		rows += 1
	return ""


## Returns the sell price of a kit: half of the shop price, rounded down (SPEC Section 17.3).
func sell_price(def: CargoDef) -> int:
	return def.price / cat.price("sell_divisor")


## Sells a kit from the hold or the dock (SPEC Section 17.3).
func sell_kit(id: int) -> String:
	var err := _station_cargo_error(id)
	if err != "":
		return err
	var c: Cargo = cargo[id]
	if c.kind != Defs.KIND_KIT:
		return CANNOT_SELL_TEXT
	credits += sell_price(c.def)
	remove_cargo(id)
	return ""


## Returns the price to clear a scrap (SPEC Section 17.4).
func clear_price(c: Cargo) -> int:
	return cat.price("scrap_cell") * c.def.shape.size()


## Removes a scrap from the hold for a price (SPEC Section 17.4).
func clear_scrap(id: int) -> String:
	var err := _station_cargo_error(id)
	if err != "":
		return err
	var c: Cargo = cargo[id]
	if c.kind != Defs.KIND_SCRAP:
		return NOT_SCRAP_TEXT
	err = _pay(clear_price(c))
	if err != "":
		return err
	remove_cargo(id)
	return ""


# --- Warp helpers (SPEC Sections 9 and 18) ---


## Selects the shift steps of the next jump (SPEC Section 18). Two steps next
## to each other have different directions.
func _make_hazard() -> PackedStringArray:
	var span: Vector2i = cat.sectors[sector - 1]["hazard_steps"][jump - 1]
	var n := rng.randi_range(span.x, span.y)
	var steps: PackedStringArray = []
	for _i in n:
		var choices: PackedStringArray = []
		for d in Defs.DIRECTIONS:
			if steps.is_empty() or steps[-1] != d:
				choices.append(d)
		steps.append(choices[rng.randi_range(0, choices.size() - 1)])
	return steps


## Handles the cargo on the dock at the warp (SPEC Sections 9 and 15.4): freight
## stays at the station and breaches its contract, and kit is sold.
func _leave_dock(warp_log: Dictionary) -> void:
	for id in dock.duplicate():
		var c: Cargo = cargo[id]
		if c.kind == Defs.KIND_FREIGHT:
			var k := contract_by_id(c.contract)
			if k != null:
				k.breached.append(id)
		elif c.kind == Defs.KIND_KIT:
			var p := sell_price(c.def)
			credits += p
			warp_log["sold"].append({"name": c.def.name, "price": p})
			warp_log["sold_credits"] += p
		remove_cargo(id)


# --- Lines (SPEC Section 22) ---


## Selects a line of an event with the line stream of the seed. It does not
## select the same line two times in a row (SPEC Section 22).
func say(event: String) -> void:
	var texts: PackedStringArray = cat.lines.get(event, PackedStringArray())
	if texts.is_empty():
		line = ""
		return
	var n := texts.size()
	var i := line_rng.randi_range(0, n - 1)
	if n > 1 and _last_line.get(event, -1) == i:
		i = (i + 1 + line_rng.randi_range(0, n - 2)) % n
	_last_line[event] = i
	line = texts[i]


## Returns n different items of a list, in a random order.
static func pick_n(r: RandomNumberGenerator, list: Array, n: int) -> Array:
	var items := list.duplicate()
	for i in range(items.size() - 1, 0, -1):
		var j := r.randi_range(0, i)
		var tmp = items[i]
		items[i] = items[j]
		items[j] = tmp
	return items.slice(0, mini(n, items.size()))
