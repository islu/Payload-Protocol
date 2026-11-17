extends TestCase
## The checks of the real data in project/data (content.md).


func test_the_real_data_loads() -> void:
	var cat := DataFiles.catalog()
	eq(cat.errors, PackedStringArray(), "the data check finds no errors (content.md)")
	eq(cat.cargo.size(), 50, "the first content has 43 freight, 6 kit, and the debris (content.md)")
	eq(
		cat.cargo[cat.debris].name,
		"Hull Debris",
		"the debris of a Hull Breach has the name Hull Debris (SPEC Section 29.2)"
	)


## The contract rules of content.md.
func test_contract_rules() -> void:
	var cat := DataFiles.catalog()
	var in_contract := {}
	for t in cat.contracts:
		var traits := {}
		for id in t.freight:
			in_contract[id] = true
			for tr in cat.cargo[id].traits:
				traits[tr] = true
		for s in t.legs:
			var n := t.freight.size()
			var hi := 6 if s == 1 else 5
			check(
				n >= 1 and n <= hi,
				"contract %s: leg %d has 1 to %d pieces (content.md)" % [t.id, s, hi]
			)
			check(
				s != 1 or traits.size() <= 1,
				"contract %s: a leg 1 contract has one trait at most (content.md)" % t.id
			)
			check(
				s != 1 or not traits.has(Defs.TRAIT_PERISHABLE),
				"contract %s: Perishable freight is only in legs 2 and 3 (content.md)" % t.id
			)
	for id: String in cat.cargo:
		# The debris of a Hull Breach is in no contract (SPEC Section 29.2).
		if cat.cargo[id].kind == Defs.KIND_FREIGHT and id != cat.debris:
			check(in_contract.has(id), "freight %s is in one contract at least (content.md)" % id)


func test_leg_1_has_no_route_rule() -> void:
	var d := Fixture.data()
	d["rules"]["legs"][0]["environment"] = true
	d["rules"]["legs"][0]["incident_percent"] = 50
	eq(
		Catalog.from_data(d).errors.size(),
		2,
		"the data check rejects an environment and incidents in leg 1 (SPEC Sections 28.1 and 29.1)"
	)


func test_debris_is_not_contract_freight() -> void:
	var d := Fixture.data()
	d["rules"]["incidents"]["debris"] = "box"
	eq(
		Catalog.from_data(d).errors.size(),
		1,
		"the data check rejects a debris that a contract has as freight (SPEC Section 29.2)"
	)


## A bot accepts each contract, packs the freight where it fits, and warps. The
## runs must end with no script error, and each phase must follow the spec.
func test_bot_runs_end() -> void:
	var cat := DataFiles.catalog()
	for run_seed in range(1, 21):
		var r := Run.new(cat, run_seed)
		var actions := 0
		while r.phase != Defs.PHASE_END and actions < 200:
			actions += 1
			match r.phase:
				Defs.PHASE_STATION:
					_bot_station(r)
					eq(r.warp(), "", "the bot warps")
				Defs.PHASE_ARRIVAL:
					eq(r.continue_run(), "", "the bot continues")
				Defs.PHASE_PAYMENT:
					eq(r.make_payment(), "", "the bot pays")
				Defs.PHASE_EVENT:
					eq(r.choose_event(r.event.choices.size() - 1), "", "the bot selects a choice")
				Defs.PHASE_MOD:
					eq(r.choose_mod(0), "", "the bot selects a mod")
		eq(r.phase, Defs.PHASE_END, "a run ends, seed %d (SPEC Section 19)" % run_seed)


func _bot_station(r: Run) -> void:
	# Take contracts while the mass stays under the limit (SPEC Section 25).
	var mass := r.hold_mass()
	for i in r.contracts.size():
		var add := 0
		for id in r.contracts[i].template.freight:
			add += r.def_mass(r.cat.cargo[id])
		if mass + add <= r.mass_limit:
			r.accept_contract(i)
			mass += add
	for id in r.dock.duplicate():
		var placed := false
		for y in r.rows:
			for x in r.columns:
				if not placed and r.can_place(id, Vector2i(x, y), 0):
					r.place_cargo(id, Vector2i(x, y), 0)
					placed = true
