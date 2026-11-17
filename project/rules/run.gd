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
const BAY_MAXED_TEXT := "The shock bay cannot grow more."
const BAY_CLAMP_TEXT := "A cargo in the shock bay cannot have a clamp."
const NO_MOD_LEFT_TEXT := "The ship has each mod already."
const CANNOT_SELL_TEXT := "You can sell only kit."
const NOT_SCRAP_TEXT := "That cargo is not scrap."
const NOT_ARRIVED_TEXT := "The ship has not arrived yet."
const NOT_AT_PAYMENT_TEXT := "No payment is due now."
const CARRIED_TEXT := "This contract is on its way. You cannot cancel it."
const NO_EVENT_TEXT := "No event is open."
const NO_CHOICE_TEXT := "There is no such choice."
const NO_MOD_CHOICE_TEXT := "No mod choice is open."
const OVERWEIGHT_TEXT := "The hold is too heavy to warp. Take cargo out, or reinforce the hull."

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
var leg: int = 1
var jump: int = 1
var credits: int
var clamps: int
var columns: int
## The size of the shock bay: (0, 0) with no shock bay (SPEC Section 31).
var bay_size := Vector2i.ZERO
var rows: int
## Cargo by ID: in the hold and on the dock.
var cargo: Dictionary = {}
## The IDs of the cargo on the dock, in order (SPEC Section 8.1).
var dock: Array[int] = []

var contracts: Array[Contract] = []
## The kit offers: {def: CargoDef, bought: bool} (SPEC Section 17.1).
var shop: Array[Dictionary] = []
var rerolls: int = 0
## The direction of each shift step of the next jump. The last one can be a fork step.
var hazard: PackedStringArray = []
## The two directions of the fork step, or empty (SPEC Section 18). The station shows them.
## The direction that happens is the last of hazard. The station does not show it.
var fork_options: PackedStringArray = []
## The mass that the ship can carry with no fuel fee (SPEC Section 25).
var mass_limit: int
var reinforces: int = 0

var last_warp: Dictionary = {}
var last_arrival: Dictionary = {}
var won := false
var stats := {"delivered": 0, "scrapped": 0, "explosions": 0}
## The line of the pilot now (SPEC Section 22).
var line: String = ""

## The charges of the Shields in this jump, by ID (SPEC Section 12.2).
var charges: Dictionary = {}

## The event of the station now, or null (SPEC Section 26).
var event: EventDef = null
## The IDs of the events that the run showed (SPEC Section 26.1).
var events_seen: PackedStringArray = []
## The credits that events took off the payment of this leg (SPEC Section 26.2).
var payment_cut: int = 0
## The environment of the leg, or "" (SPEC Section 28).
var environment: String = ""
## The incident of the next jump: {kind, x, y}, or empty (SPEC Section 29).
var incident: Dictionary = {}
## The IDs of the mods of the ship (SPEC Section 27).
var mods: PackedStringArray = []
## The IDs of the mods of the open mod choice (SPEC Section 27.1).
var mod_offer: PackedStringArray = []

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
	mass_limit = cat.mass_limit
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
	hazard = Route.make_hazard(self)
	incident = Route.make_incident(self)
	say(Defs.LINE_HAZARD)
	StationEvents.start_event(self)


## Starts the jump: the dock, each shift step, and the arrival (SPEC Sections 9 and 16).
func warp() -> String:
	if phase != Defs.PHASE_STATION:
		return NOT_AT_STATION_TEXT
	if hold_mass() > max_mass():
		return OVERWEIGHT_TEXT
	var warp_log := {
		"sold": [],
		"sold_credits": 0,
		"scrap_cleared": 0,
		"fuel_fee": 0,
		"before": [],
		"steps": [],
		"credits": credits
	}
	_leave_dock(warp_log)
	# The fuel fee comes first (SPEC Sections 9 and 25). The credits can go below 0.
	warp_log["fuel_fee"] = fuel_fee()
	credits -= warp_log["fuel_fee"]
	# The hold before the first shift step, so that the UI can play the log (SPEC Section 20.3).
	warp_log["before"] = RunView.hold_views(self)
	# The shock bay does not change in the warp: the UI shows it still (SPEC Section 31.2).
	warp_log["bay"] = RunView.bay_views(self)
	Shift.charge_shields(self)
	# The incident comes before the first shift step (SPEC Section 29).
	if not incident.is_empty():
		var inc := Shift.incident(self, incident)
		if inc["debris"] != 0:
			for cv: Dictionary in RunView.hold_views(self):
				if cv["id"] == inc["debris"]:
					inc["debris_view"] = cv
		warp_log["incident"] = inc
	for i in hazard.size():
		var step := Shift.step(self, hazard[i])
		if i == hazard.size() - 1 and not fork_options.is_empty():
			step["options"] = Array(fork_options)
		warp_log["steps"].append(step)
	# The total lost pay of the warp (SPEC Section 21.5).
	warp_log["loss"] = 0
	for step: Dictionary in warp_log["steps"] + [warp_log.get("incident", {"reactions": []})]:
		for r: Dictionary in step["reactions"]:
			warp_log["loss"] += r["loss"]
	last_warp = warp_log
	Arrival.arrive(self)
	return ""


## Leaves the arrival report: to the next station, or to the payment screen after
## the last jump of a leg (SPEC Sections 19.1 and 20.4).
func continue_run() -> String:
	if phase != Defs.PHASE_ARRIVAL:
		return NOT_ARRIVED_TEXT
	if jump >= cat.jumps(leg):
		phase = Defs.PHASE_PAYMENT
		say(Defs.LINE_PAYMENT)
		return ""
	jump += 1
	_open_station()
	return ""


## Returns the payment of the leg now (SPEC Section 19.1).
func payment() -> int:
	return maxi(0, cat.legs[leg - 1]["payment"] - payment_cut)


## Pays the payment. If the credits are less than the payment, the run ends in a loss
## (SPEC Section 19).
func make_payment() -> String:
	if phase != Defs.PHASE_PAYMENT:
		return NOT_AT_PAYMENT_TEXT
	if credits < payment():
		_end(false)
		return ""
	credits -= payment()
	if leg >= cat.legs.size():
		_end(true)
		return ""
	leg += 1
	jump = 1
	payment_cut = 0
	Route.pick_environment(self)
	_open_station()
	# A mod choice after the payment of each leg but the last (SPEC Section 27.1).
	StationEvents.offer_mods(self)
	return ""


# --- Environments (SPEC Section 28). Route selects them. ---


## Returns a number of the environment now, or the default (SPEC Section 28.2).
func env_value(id: String, key: String, default: int) -> int:
	if environment != id:
		return default
	return cat.environment_values.get(id, {}).get(key, default)


## Returns the break limit of a trait in the environment now (SPEC Sections 7 and 28.2).
func break_limit(trait_id: String) -> int:
	return env_value(Defs.ENV_HEAT_ZONE, trait_id, cat.break_limit(trait_id))


# --- Events and mods (SPEC Sections 26 and 27). StationEvents has their rules. ---


## Selects a choice of the event. It pays the cost, then does the effects in order
## (SPEC Section 26.2).
func choose_event(index: int) -> String:
	if phase != Defs.PHASE_EVENT or event == null:
		return NO_EVENT_TEXT
	if index < 0 or index >= event.choices.size():
		return NO_CHOICE_TEXT
	var err := StationEvents.choice_error(self, index)
	if err != "":
		return err
	var choice: Dictionary = event.choices[index]
	credits -= choice["cost"]
	event = null
	phase = Defs.PHASE_STATION
	var mod := false
	for f: Dictionary in choice["effects"]:
		mod = StationEvents.do_effect(self, f) or mod
	if mod:
		StationEvents.offer_mods(self)
	return ""


## Selects a mod of the mod choice. Then the event of the station shows, or the
## station opens (SPEC Section 27.1).
func choose_mod(index: int) -> String:
	if phase != Defs.PHASE_MOD:
		return NO_MOD_CHOICE_TEXT
	if index < 0 or index >= mod_offer.size():
		return NO_CHOICE_TEXT
	mods.append(mod_offer[index])
	mod_offer = []
	phase = Defs.PHASE_EVENT if event != null else Defs.PHASE_STATION
	return ""


func has_mod(id: String) -> bool:
	return id in mods


## Returns the pay of a freight: the pay of its contract, or 0 (SPEC Section 21.5).
func pay_of(c: Cargo) -> int:
	var k := contract_by_id(c.contract)
	return k.template.pay if k != null else 0


func _end(win: bool) -> void:
	phase = Defs.PHASE_END
	won = win
	say(Defs.LINE_WIN if win else Defs.LINE_LOSE)


## The score is the credits after the last payment (SPEC Section 19.2).
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
	return _cargo_in(false)


## Returns the cargo in the shock bay, in the order of the IDs (SPEC Section 31).
func bay_cargo() -> Array[Cargo]:
	return _cargo_in(true)


## Returns the cargo in the shock bay with bay, else in the hold, in the order of the IDs.
func _cargo_in(bay: bool) -> Array[Cargo]:
	var out: Array[Cargo] = []
	var ids := cargo.keys()
	ids.sort()
	for id: int in ids:
		var c: Cargo = cargo[id]
		if c.in_bay if bay else c.in_hold:
			out.append(c)
	return out


## Returns the cargo of the ship: the hold, then the shock bay (SPEC Section 31.1).
func ship_cargo() -> Array[Cargo]:
	var out := hold_cargo()
	out.append_array(bay_cargo())
	return out


## Returns the ID of the cargo in each cell of the hold, or of the shock bay, that has one.
func occupancy(to_bay := false) -> Dictionary:
	var occ := {}
	for c in bay_cargo() if to_bay else hold_cargo():
		for cell in c.cells():
			occ[cell] = c.id
	return occ


func inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < columns and c.y < rows


## Reports whether a cell is inside the shock bay (SPEC Section 31.1).
func _inside_bay(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < bay_size.x and c.y < bay_size.y


## Reports whether a cargo fits at a place of the hold or of the shock bay. It
## ignores the cargo itself (SPEC Section 8.3).
func fits(c: Cargo, pos: Vector2i, rot: int, to_bay := false) -> bool:
	var occ := occupancy(to_bay)
	for cell in Shapes.cells_at(c.def.shape, rot, pos):
		var inside_area := _inside_bay(cell) if to_bay else inside(cell)
		if not inside_area or occ.get(cell, c.id) != c.id:
			return false
	return true


## Reports whether a drop of a cargo at a place is valid (SPEC Section 8.3).
func can_place(id: int, pos: Vector2i, rot: int, to_bay := false) -> bool:
	return (
		phase == Defs.PHASE_STATION
		and cargo.has(id)
		and rot >= 0
		and rot < 4
		and fits(cargo[id], pos, rot, to_bay)
	)


## Returns the error of an action on a cargo at the station, or "".
func _station_cargo_error(id: int) -> String:
	if phase != Defs.PHASE_STATION:
		return NOT_AT_STATION_TEXT
	if not cargo.has(id):
		return NO_CARGO_TEXT
	return ""


## Moves a cargo from the dock, the hold, or the shock bay to a place in the hold or
## in the shock bay (SPEC Sections 8.2 and 31.1). The clamp of the cargo moves with it
## in the hold. A cargo in the shock bay has no clamp.
func place_cargo(id: int, pos: Vector2i, rot: int, to_bay := false) -> String:
	var err := _station_cargo_error(id)
	if err != "":
		return err
	if rot < 0 or rot > 3:
		return BAD_ROTATION_TEXT
	var c: Cargo = cargo[id]
	if not fits(c, pos, rot, to_bay):
		return NO_FIT_TEXT
	c.pos = pos
	c.rot = rot
	c.in_hold = not to_bay
	c.in_bay = to_bay
	if to_bay:
		c.clamped = false
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
	if c.in_hold or c.in_bay:
		c.in_hold = false
		c.in_bay = false
		c.clamped = false
		dock.append(id)
	return ""


## Puts each cargo on the dock into the hold, in the order of the dock: in the first
## place where it fits, row by row from (0, 0), in its rotation now and then in the next
## rotations. A cargo that does not fit stays on the dock (SPEC Section 8.1).
func load_all() -> String:
	if phase != Defs.PHASE_STATION:
		return NOT_AT_STATION_TEXT
	for id in dock.duplicate():
		_load_one(cargo[id])
	return ""


## Puts a cargo in the first place of the hold where it fits, for load_all().
func _load_one(c: Cargo) -> void:
	for turn in 4:
		var rot := (c.rot + turn) % 4
		for y in rows:
			for x in columns:
				if fits(c, Vector2i(x, y), rot):
					place_cargo(c.id, Vector2i(x, y), rot)
					return


## Rotates a cargo in the hold in its place. If the new shape does not fit, the
## cargo goes to the first place 1 cell away where it fits (SPEC Section 8.2).
func rotate_cargo(id: int) -> String:
	var err := _station_cargo_error(id)
	if err != "":
		return err
	var c: Cargo = cargo[id]
	if not c.in_hold and not c.in_bay:
		return NOT_IN_HOLD_TEXT
	var rot := (c.rot + 1) % 4
	for kick in ROTATE_KICKS:
		if fits(c, c.pos + kick, rot, c.in_bay):
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
	if c.in_bay:
		return BAY_CLAMP_TEXT
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
	if k.carried():
		return CARRIED_TEXT
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


## Selects the contracts of a new station from the templates of the leg. The
## offers must fit together in an empty hold (content.md).
func _offer_contracts() -> void:
	var pool: Array = []
	var left := jumps_left()
	for t in cat.contracts:
		# A long contract needs its jumps before the run ends (SPEC Section 30.2).
		if leg in t.legs and t.jumps <= left:
			pool.append(t)
	var n := mini(cat.offer_contracts, pool.size())
	var picked: Array = []
	for attempt in 20:
		picked = pick_n(rng, pool, n)
		if attempt == 19 or _offer_mass(picked) * 100 >= mass_limit * cat.offer_mass_percent:
			break
	# A long contract on its way stays on the board (SPEC Section 30.2).
	var kept: Array[Contract] = []
	for k in contracts:
		if k.accepted and k.carried():
			kept.append(k)
	contracts = kept
	for t: ContractTemplate in picked:
		add_contract(t)


## Returns the jumps that are left in the run, with the jump of this station.
func jumps_left() -> int:
	var left := cat.jumps(leg) - jump + 1
	for l in range(leg + 1, cat.legs.size() + 1):
		left += cat.jumps(l)
	return left


## Adds a contract of a template to the board.
func add_contract(t: ContractTemplate) -> Contract:
	_next_contract += 1
	var k := Contract.new(_next_contract, t)
	contracts.append(k)
	return k


## Returns the mass of all freight of the templates (content.md).
func _offer_mass(templates: Array) -> int:
	var total := 0
	for t: ContractTemplate in templates:
		for id in t.freight:
			total += def_mass(cat.cargo[id])
	return total


# --- Mass (SPEC Section 25) ---


## Returns the mass of a definition: its weight value multiplied by its cells.
func def_mass(def: CargoDef) -> int:
	# Kit has no mass (SPEC Section 25).
	if def.kind == Defs.KIND_KIT:
		return 0
	return cat.weight_value(def.weight) * def.shape.size()


## Returns the mass of a cargo now. Kit has no mass. Scrap is light, also the scrap
## of a kit (SPEC Section 25).
func cargo_mass(c: Cargo) -> int:
	if c.kind == Defs.KIND_KIT:
		return 0
	return cat.weight_value(c.weight()) * c.def.shape.size()


## Returns the mass of the cargo in the hold and in the shock bay. The dock does not
## count (SPEC Section 25).
func hold_mass() -> int:
	var total := 0
	for c in ship_cargo():
		total += cargo_mass(c)
	return total


## Returns the most mass that the ship can warp with: the limit plus over_percent, rounded down.
func max_mass() -> int:
	return mass_limit * (100 + cat.over_percent) / 100


## Returns the fuel fee of a warp now: for each point of mass over the limit.
func fuel_fee() -> int:
	return maxi(0, hold_mass() - mass_limit) * cat.fuel_fee


## Returns the price of the next Reinforce hull (SPEC Section 17.2).
func reinforce_price() -> int:
	return cat.price("reinforce_first") + cat.price("reinforce_step") * reinforces


## Adds to the mass limit (SPEC Section 17.2).
func reinforce_hull() -> String:
	if phase != Defs.PHASE_STATION:
		return NOT_AT_STATION_TEXT
	var err := _pay(reinforce_price())
	if err != "":
		return err
	reinforces += 1
	mass_limit += cat.reinforce_amount
	return ""


# --- Shop (SPEC Section 17) ---


func _offer_kit() -> void:
	shop.clear()
	for id: String in pick_n(rng, Array(cat.legs[leg - 1]["kit_pool"]), cat.offer_kit):
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


## Returns the next purchase of the shock bay: {size: Vector2i, price}, or {} at its
## maximum (SPEC Section 17.2).
func shock_bay_offer() -> Dictionary:
	var level := cat.bay_sizes.find(bay_size) + 1
	if level >= cat.bay_sizes.size():
		return {}
	return {"size": cat.bay_sizes[level], "price": cat.bay_prices[level]}


## Installs the shock bay, or makes it larger (SPEC Sections 17.2 and 31.1).
func buy_shock_bay() -> String:
	if phase != Defs.PHASE_STATION:
		return NOT_AT_STATION_TEXT
	var offer := shock_bay_offer()
	if offer.is_empty():
		return BAY_MAXED_TEXT
	var err := _pay(offer["price"])
	if err != "":
		return err
	bay_size = offer["size"]
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


# --- Warp helpers (SPEC Section 9) ---


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
		elif c.kind == Defs.KIND_SCRAP:
			# Scrap on the dock is cleared at its clear price (SPEC Section 26.3).
			credits -= clear_price(c)
			warp_log["scrap_cleared"] += clear_price(c)
		remove_cargo(id)


# --- Lines (SPEC Section 22) ---


## Selects a line of an event with the line stream of the seed. It does not
## select the same line two times in a row (SPEC Section 22).
func say(line_event: String) -> void:
	var texts: PackedStringArray = cat.lines.get(line_event, PackedStringArray())
	if texts.is_empty():
		line = ""
		return
	var n := texts.size()
	var i := line_rng.randi_range(0, n - 1)
	if n > 1 and _last_line.get(line_event, -1) == i:
		i = (i + 1 + line_rng.randi_range(0, n - 2)) % n
	_last_line[line_event] = i
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
