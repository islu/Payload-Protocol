extends RuleTest


func test_power() -> void:
	var shield := put("shield", 0, 5)
	put("battery", 1, 5)
	var lone := put("shield", 5, 0)
	var s: Dictionary = shift([Defs.DIR_DOWN])[0]
	eq(s["powered"], [shield.id], "a Shield next to a Battery has power (SPEC Section 12.2)")
	check(not lone.id in s["powered"], "a Shield with no Battery has no power (SPEC Section 12.2)")


func test_shield_protects_a_neighbor() -> void:
	# The vase slides 2 cells down to (0,5), next to the shield at (1,5).
	var shield := put("shield", 1, 5)
	put("battery", 2, 5)
	var vase := put("vase", 0, 3)
	var logs := shift([Defs.DIR_DOWN])
	eq(
		vase.kind,
		Defs.KIND_FREIGHT,
		"a Shield with power protects a cargo next to it (SPEC Section 12.2)"
	)
	var r: Dictionary = logs[0]["reactions"][0]
	eq(r["kind"], Defs.REACT_SHIELD, "the log has the shield (SPEC Section 12.2)")
	eq(r["canceled"], Defs.REACT_BREAK, "the shield canceled a break")
	eq(r["shield"], shield.id, "the log names the shield")


func test_one_charge_per_jump() -> void:
	# Both vases slide to the shield with force 2. The vase with the smaller ID reacts first.
	put("shield", 1, 5)
	put("battery", 2, 5)
	var a := put("vase", 0, 3)
	var b := put("vase", 1, 2)
	shift([Defs.DIR_DOWN])
	eq(a.kind, Defs.KIND_FREIGHT, "the first reaction is canceled (SPEC Section 12.2)")
	eq(b.kind, Defs.KIND_SCRAP, "a Shield has 1 charge in each jump (SPEC Section 12.2)")


func test_no_power_no_protection() -> void:
	put("shield", 1, 5)
	var vase := put("vase", 0, 3)
	shift([Defs.DIR_DOWN])
	eq(vase.kind, Defs.KIND_SCRAP, "a Shield with no power does not protect (SPEC Section 12.2)")


func test_shorted_battery_gives_no_power() -> void:
	# Step 1 (down): two tanks leak next to the battery at (1,5). The shield cancels the
	# first short. The second short makes the battery scrap.
	var shield := put("shield", 0, 5)
	var battery := put("battery", 1, 5)
	put("tank", 2, 4)
	put("tank", 1, 3)
	var logs := shift([Defs.DIR_DOWN, Defs.DIR_LEFT])
	eq(battery.kind, Defs.KIND_SCRAP, "the second short breaks the battery (SPEC Section 12.2)")
	eq(logs[0]["powered"], [shield.id], "the shield has power in step 1 (SPEC Section 12.2)")
	eq(
		logs[1]["powered"],
		[],
		"a Battery that shorts gives no power in the next steps (SPEC Section 12.2)"
	)


func test_shield_order() -> void:
	# The vase slides to (1,5), next to both shields. The batteries are above them.
	var right := put("shield", 2, 5)
	var left := put("shield", 0, 5)
	put("battery", 0, 4)
	put("battery", 2, 4)
	var vase := put("vase", 1, 2)
	shift([Defs.DIR_DOWN])
	eq(vase.kind, Defs.KIND_FREIGHT, "the vase is protected (SPEC Section 12.2)")
	eq(
		run.charges[left.id],
		0,
		"the Shield with the smaller (y, x) spends its charge first (SPEC Section 12.2)"
	)
	eq(run.charges[right.id], 1, "the other Shield keeps its charge (SPEC Section 12.2)")


func test_shield_protects_itself() -> void:
	# The bomb stops at (1,4) on the heavy cargo, diagonal to the shield at (2,5).
	# The battery at (3,5) is outside the blast area.
	var shield := put("shield", 2, 5)
	put("battery", 3, 5)
	put("heavy", 1, 5)
	put("bomb", 1, 1)
	var logs := shift([Defs.DIR_DOWN])
	eq(
		reaction_kinds(logs),
		[Defs.REACT_EXPLOSION, Defs.REACT_SHIELD],
		"the bomb explodes (SPEC Section 11.2)"
	)
	eq(shield.kind, Defs.KIND_KIT, "a Shield protects itself (SPEC Section 12.2)")


func test_spoil_at_arrival() -> void:
	var cold := on_dock("cheese")
	var warm := on_dock("cheese")
	run.place_cargo(cold.id, Vector2i(0, 5), 0)
	run.place_cargo(warm.id, Vector2i(5, 0), 0)
	put("cooler", 1, 5)
	warp_with([Defs.DIR_DOWN])
	eq(
		cold.kind,
		Defs.KIND_FREIGHT,
		"a Perishable cargo next to a Cooler stays fresh (SPEC Section 12.1)"
	)
	eq(
		warm.kind,
		Defs.KIND_SCRAP,
		"a Perishable cargo with no Cooler spoils at the arrival (SPEC Section 12.1)"
	)
	eq(run.last_arrival["spoiled"], [warm.id], "the report has the spoil (SPEC Section 16)")


func test_only_arrival_positions_count() -> void:
	# Step 1 (right) takes the cheese away from the cooler. Step 2 (left) brings it back.
	var cooler := put("cooler", 0, 0)
	run.clamp_cargo(cooler.id)
	var cheese := put("cheese", 1, 0)
	warp_with([Defs.DIR_RIGHT, Defs.DIR_LEFT])
	eq(
		cheese.kind,
		Defs.KIND_FREIGHT,
		"only the positions at the arrival count (SPEC Section 12.1)"
	)


func test_link_view() -> void:
	put("cooler", 0, 0)
	put("cheese", 1, 0)
	put("cheese", 4, 4)
	put("battery", 0, 3)
	put("shield", 0, 4)
	put("shield", 5, 5)
	var v := RunView.view(run)
	eq(v["links"].size(), 2, "the view has a cold link and a power link (SPEC Section 12.3)")
	var warnings := []
	for c: Dictionary in v["cargo"]:
		if c["no_cooler"] or c["no_power"]:
			warnings.append(c["def_id"])
	eq(
		warnings,
		["cheese", "shield"],
		"the lone cheese and the lone shield show a warning (SPEC Section 12.3)"
	)


func test_view_has_each_rotation() -> void:
	put("ell", 0, 0, 1)
	var c: Dictionary = RunView.view(run)["cargo"][0]
	eq(c["rotations"].size(), 4, "the view has the shape in each rotation (SPEC Section 8.2)")
	eq(
		c["rotations"][1],
		c["shape"],
		"the shape now is the shape of its rotation (SPEC Section 8.2)"
	)


func test_preview_links() -> void:
	put("cooler", 0, 0)
	var cheese := on_dock("cheese")
	var links := RunView.preview_links(run, cheese.id, Vector2i(1, 0), 0)
	eq(links.size(), 1, "a drag shows the link that the cargo would make (SPEC Section 8.3)")
	eq(
		RunView.preview_links(run, cheese.id, Vector2i(3, 3), 0),
		[],
		"no link away from the Cooler (SPEC Section 8.3)"
	)
	check(
		not cheese.in_hold and cheese.id in run.dock,
		"a preview does not move the cargo (SPEC Section 8.3)"
	)
	eq(
		RunView.preview_links(run, cheese.id, Vector2i(0, 0), 0),
		[],
		"no preview for a drop that is not valid"
	)


func test_jolt_risk_view() -> void:
	# The first step is RIGHT. The glass (standard Fragile) and the vase (light Fragile) are at
	# the right wall. A glass away from the wall has no risk.
	run.hazard = PackedStringArray([Defs.DIR_RIGHT, Defs.DIR_UP])
	run.fork_options = PackedStringArray()
	var glass := put("glass", 5, 0)
	var vase := put("vase", 5, 2)
	var away := put("glass", 2, 4)
	var v := RunView.view(run)
	eq(
		v["front_wall"],
		Defs.DIR_RIGHT,
		"the view has the front wall of the first step (SPEC Section 12.3)"
	)
	var risk := {}
	for c: Dictionary in v["cargo"]:
		risk[c["id"]] = c["jolt_risk"]
	check(risk[glass.id], "a cargo that the jolt would break shows a warning (SPEC Section 12.3)")
	check(
		not risk[vase.id],
		"a cargo that the jolt would not break shows no warning (SPEC Section 12.3)"
	)
	check(
		not risk[away.id], "a cargo away from the front wall shows no warning (SPEC Section 12.3)"
	)


func test_padded_walls_jolt_risk() -> void:
	# In a Heat Zone, Volatile breaks at 2. The heavy bomb at the left wall takes a
	# jolt of 3 - 1 = 2 with Padded Walls, so it still explodes.
	run.environment = Defs.ENV_HEAT_ZONE
	run.mods.append(Defs.MOD_PADDED_WALLS)
	run.hazard = PackedStringArray([Defs.DIR_LEFT, Defs.DIR_UP])
	run.fork_options = PackedStringArray()
	var bomb := put("bigbomb", 0, 2)
	var glass := put("glass", 0, 4)
	var risks := RunView.jolt_risks(run)
	check(
		risks.has(bomb.id),
		"the warning uses the jolt that Padded Walls makes 1 less (SPEC Sections 12.3 and 27.2)"
	)
	check(not risks.has(glass.id), "a jolt of 2 - 1 does not break glass (SPEC Section 27.2)")


func test_link_within_2_cells() -> void:
	# The Battery at (0, 0) and the Shield at (2, 0) are 2 cells apart.
	var battery := put("battery", 0, 0)
	var shield := put("shield", 2, 0)
	eq(RunView.links(run), [], "with no mod, cargo 2 cells apart have no link (SPEC Section 12.3)")
	run.mods.append(Defs.MOD_ARRAY_POWER)
	eq(
		RunView.links(run),
		[{"kind": Defs.LINK_POWER, "from": battery.id, "to": shield.id}],
		"with Array Power, the link of a Battery within 2 cells shows (SPEC Sections 12.3 and 27.2)"
	)
