extends RuleTest


func test_fragile_breaks_at_force_2() -> void:
	var vase := put("vase", 2, 0)
	var logs := shift([Defs.DIR_LEFT])
	eq(vase.kind, Defs.KIND_SCRAP, "a Fragile cargo breaks at force 2 (SPEC Section 11.1)")
	eq(reaction_kinds(logs), [Defs.REACT_BREAK], "the log has the break (SPEC Section 11.1)")


func test_fragile_holds_at_force_1() -> void:
	var vase := put("vase", 1, 0)
	shift([Defs.DIR_LEFT])
	eq(
		vase.kind,
		Defs.KIND_FREIGHT,
		"a Fragile cargo does not break at force 1 (SPEC Section 11.1)"
	)


func test_scrap_keeps_shape_and_place() -> void:
	var glass := put("glass", 1, 3)
	shift([Defs.DIR_LEFT])
	eq(glass.kind, Defs.KIND_SCRAP, "the glass breaks at force 2 (SPEC Section 11.1)")
	eq(glass.pos, Vector2i(0, 3), "scrap keeps the cells of the cargo (SPEC Section 6.4)")
	eq(glass.weight(), Defs.WEIGHT_LIGHT, "scrap is light (SPEC Section 6.4)")
	check(not glass.has(Defs.TRAIT_FRAGILE), "scrap has no traits (SPEC Section 6.4)")


func test_volatile_explodes_at_force_3() -> void:
	var bomb := put("bomb", 3, 0)
	shift([Defs.DIR_LEFT])
	check(gone(bomb), "a Volatile cargo explodes at force 3 and is removed (SPEC Section 11.2)")
	eq(run.stats["explosions"], 1, "the run counts the explosion (SPEC Section 19.2)")


func test_volatile_holds_at_force_2() -> void:
	var bomb := put("bomb", 2, 0)
	shift([Defs.DIR_LEFT])
	check(not gone(bomb), "a Volatile cargo does not explode at force 2 (SPEC Section 11.2)")


func test_blast_area() -> void:
	# The bomb slides 3 cells down to (1,5). The clamped box at (0,4) is diagonal to it.
	# The cooler at (2,5) is next to it. The box at (4,5) is outside the area.
	var bomb := put("bomb", 1, 2)
	var diag := put("box", 0, 4)
	run.clamp_cargo(diag.id)
	var kit := put("cooler", 2, 5)
	var far := put("box", 4, 5)
	shift([Defs.DIR_DOWN])
	check(gone(bomb), "the bomb explodes (SPEC Section 11.2)")
	eq(diag.kind, Defs.KIND_SCRAP, "a diagonal cell is in the blast area (SPEC Section 11.2)")
	eq(kit.kind, Defs.KIND_SCRAP, "kit in the blast area becomes scrap (SPEC Section 11.2)")
	eq(far.kind, Defs.KIND_FREIGHT, "cargo outside the blast area is safe (SPEC Section 11.2)")


func test_heavy_is_not_affected() -> void:
	put("bomb", 3, 0)
	var heavy := put("heavy", 0, 1)
	shift([Defs.DIR_LEFT])
	eq(
		heavy.kind,
		Defs.KIND_FREIGHT,
		"heavy cargo is not affected by an explosion (SPEC Section 11.2)"
	)


func test_blast_removes_scrap() -> void:
	put("bomb", 3, 0)
	var scrap := put("box", 0, 1)
	scrap.kind = Defs.KIND_SCRAP
	shift([Defs.DIR_LEFT])
	check(gone(scrap), "an explosion removes the scrap in the blast area (SPEC Section 11.2)")


func test_chain_of_explosions() -> void:
	# a slides to (0,0) with force 3. b slides to (0,1) with force 1. c is at (1,2) behind the
	# heavy box at (0,2): it does not move and is not at the front wall, so it takes no hit.
	var a := put("bomb", 3, 0)
	var b := put("bomb", 1, 1)
	put("heavy", 0, 2)
	var c := put("bigbomb", 1, 2)
	var logs := shift([Defs.DIR_LEFT])
	check(
		gone(a) and gone(b),
		"an explosion explodes each Volatile cargo in the area (SPEC Section 11.2)"
	)
	check(gone(c), "a heavy Volatile cargo explodes in a chain too (SPEC Section 11.2)")
	eq(run.stats["explosions"], 3, "three explosions (SPEC Section 11.2)")
	var causes := []
	for r: Dictionary in logs[0]["reactions"]:
		causes.append(r["cause"])
	eq(causes, [-1, 0, 1], "each explosion names the reaction that started it")


func test_leak_shorts_electronic_next_to_it() -> void:
	# The tank slides 1 cell down to (2,5): force 2. The chip at (3,5) is next to it.
	var tank := put("tank", 2, 4)
	var chip := put("chip", 3, 5)
	var far := put("chip", 5, 5)
	var logs := shift([Defs.DIR_DOWN])
	eq(
		tank.kind,
		Defs.KIND_SCRAP,
		"a Fluid cargo leaks at force 2 and becomes scrap (SPEC Section 11.3)"
	)
	eq(chip.kind, Defs.KIND_SCRAP, "an Electronic cargo next to a leak shorts (SPEC Section 11.3)")
	eq(
		far.kind,
		Defs.KIND_FREIGHT,
		"an Electronic cargo away from the leak is safe (SPEC Section 11.3)"
	)
	eq(reaction_kinds(logs), [Defs.REACT_LEAK, Defs.REACT_SHORT], "the leak, then the short")


func test_one_reaction_by_order() -> void:
	put("drum", 0, 4)
	eq(
		reaction_kinds(shift([Defs.DIR_DOWN])),
		[Defs.REACT_LEAK],
		"a Fluid and Volatile cargo leaks at force 2 (SPEC Section 11)"
	)
	var tr := RuleTest.new()
	tr.put("drum", 0, 3)
	var chip := tr.put("chip", 3, 5)
	var kinds := reaction_kinds(tr.shift([Defs.DIR_DOWN]))
	eq(
		kinds,
		[Defs.REACT_EXPLOSION],
		"at force 4 it explodes and does not leak too (SPEC Section 11)"
	)
	eq(chip.kind, Defs.KIND_FREIGHT, "no leak, so no short (SPEC Section 11)")
	failures.append_array(tr.failures)


func test_scrap_does_not_react_again() -> void:
	put("vase", 2, 0)
	eq(
		reaction_kinds(shift([Defs.DIR_LEFT, Defs.DIR_DOWN])),
		[Defs.REACT_BREAK],
		"scrap does not react again (SPEC Section 11)"
	)
