extends TestCase
## The checks of the real data in project/data (content.md).


func test_the_real_data_loads() -> void:
	var cat := DataFiles.catalog()
	eq(cat.errors, PackedStringArray(), "the data check finds no errors (content.md)")
	eq(cat.cargo.size(), 19, "the first content has 14 freight and 5 kit (content.md)")


func test_offers_fit_an_empty_hold() -> void:
	var cat := DataFiles.catalog()
	for run_seed in range(1, 41):
		var r := Run.new(cat, run_seed)
		for sector in [1, 2, 3]:
			r.sector = sector
			r._offer_contracts()
			var shapes := []
			for k in r.contracts:
				for id in k.template.freight:
					shapes.append(cat.cargo[id].shape)
			check(
				Packing.packs(shapes, r.columns, r.rows, 200000),
				(
					"the 3 offers of sector %d fit in an empty hold, seed %d (content.md)"
					% [sector, run_seed]
				)
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
				Defs.PHASE_TOLL:
					eq(r.pay_toll(), "", "the bot pays")
		eq(r.phase, Defs.PHASE_END, "a run ends, seed %d (SPEC Section 19)" % run_seed)


func _bot_station(r: Run) -> void:
	for i in r.contracts.size():
		r.accept_contract(i)
	for id in r.dock.duplicate():
		var placed := false
		for y in r.rows:
			for x in r.columns:
				if not placed and r.can_place(id, Vector2i(x, y), 0):
					r.place_cargo(id, Vector2i(x, y), 0)
					placed = true
