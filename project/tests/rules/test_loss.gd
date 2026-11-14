extends RuleTest
## The losses of a warp: the lost pay of each reaction, the chain count, and the
## total (SPEC Section 21.5).


func test_freight_loss() -> void:
	accept(["k_vases"])
	eq(run.place_cargo(run.dock[0], Vector2i(2, 0), 0), "", "place a vase")
	var logs := shift([Defs.DIR_LEFT])
	var r: Dictionary = logs[0]["reactions"][0]
	eq(r["kind"], Defs.REACT_BREAK, "the vase breaks at force 2 (SPEC Section 11.1)")
	eq(
		r["loss"],
		8,
		"a freight that becomes scrap has the pay of its contract as its loss (SPEC Section 21.5)"
	)


func test_kit_no_loss() -> void:
	put("bomb", 3, 0)
	put("foam", 0, 1)
	var logs := shift([Defs.DIR_LEFT])
	var losses := []
	for r: Dictionary in logs[0]["reactions"]:
		losses.append(r["loss"])
	eq(reaction_kinds(logs), [Defs.REACT_EXPLOSION, Defs.REACT_BLAST], "the bomb blasts the foam")
	eq(losses, [0, 0], "a kit and a freight with no contract have no loss (SPEC Section 21.5)")


func test_chain_count() -> void:
	put("bomb", 3, 0)
	put("foam", 0, 1)
	put("vase", 2, 1)
	put("box", 5, 5)
	var logs := shift([Defs.DIR_LEFT])
	var chain := []
	for r: Dictionary in logs[0]["reactions"]:
		chain.append(r["chain"])
	eq(
		reaction_kinds(logs),
		[Defs.REACT_EXPLOSION, Defs.REACT_BLAST, Defs.REACT_BLAST],
		"the explosion blasts the foam and the vase"
	)
	eq(chain, [1, 2, 3], "each reaction has its number in its chain (SPEC Section 21.5)")


func test_new_chain_starts_at_1() -> void:
	put("vase", 2, 0)
	put("vase", 2, 3)
	var logs := shift([Defs.DIR_LEFT])
	var chain := []
	for r: Dictionary in logs[0]["reactions"]:
		chain.append(r["chain"])
	eq(chain, [1, 1], "two breaks with no cause are two chains of 1 (SPEC Section 21.5)")


func test_total_loss() -> void:
	accept(["k_vases"])
	eq(run.place_cargo(run.dock[0], Vector2i(2, 0), 0), "", "place a vase")
	eq(run.place_cargo(run.dock[0], Vector2i(2, 3), 0), "", "place a vase")
	warp_with([Defs.DIR_LEFT])
	eq(run.last_warp["loss"], 16, "the warp has the total lost pay (SPEC Section 21.5)")
