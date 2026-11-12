extends RuleTest


func test_slides_to_the_wall() -> void:
	var c := put("box", 3, 2)
	shift([Defs.DIR_LEFT])
	eq(c.pos, Vector2i(0, 2), "a cargo slides until a wall stops it (SPEC Section 10.1)")


func test_slides_to_a_stopped_cargo() -> void:
	var a := put("box", 4, 0)
	var b := put("box", 1, 0)
	shift([Defs.DIR_RIGHT])
	eq(a.pos, Vector2i(5, 0), "the front cargo reaches the wall (SPEC Section 10.1)")
	eq(
		b.pos,
		Vector2i(4, 0),
		"a cargo slides until a cargo that stopped blocks it (SPEC Section 10.1)"
	)


func test_order_does_not_change_the_result() -> void:
	# The box behind has the smaller ID, so one pass in ID order would stop it early.
	var back := put("box", 0, 0)
	var front := put("box", 3, 0)
	shift([Defs.DIR_RIGHT])
	eq(front.pos, Vector2i(5, 0), "the front box (SPEC Section 10.1)")
	eq(
		back.pos,
		Vector2i(4, 0),
		"the order of the cargo does not change the result (SPEC Section 10.1)"
	)


func test_interlocked_shapes() -> void:
	# The L at (2,0) has the cells (2,0) (2,1) (3,1). The box at (3,0) sits in its corner.
	var ell := put("ell", 2, 0)
	var box := put("box", 3, 0)
	shift([Defs.DIR_RIGHT])
	eq(box.pos, Vector2i(5, 0), "the box reaches the wall (SPEC Section 10.1)")
	eq(ell.pos, Vector2i(4, 0), "the L slides until the box blocks it (SPEC Section 10.1)")


func test_no_push() -> void:
	var wall := put("box", 3, 0)
	run.clamp_cargo(wall.id)
	var heavy := put("heavy", 0, 0)
	shift([Defs.DIR_RIGHT])
	eq(wall.pos, Vector2i(3, 0), "cargo does not push other cargo (SPEC Section 10.1)")
	eq(heavy.pos, Vector2i(2, 0), "the heavy cargo stops at the clamped cargo (SPEC Section 10.2)")


func test_clamped_does_not_slide() -> void:
	var c := put("box", 2, 2)
	run.clamp_cargo(c.id)
	shift([Defs.DIR_LEFT, Defs.DIR_DOWN])
	eq(c.pos, Vector2i(2, 2), "a clamped cargo does not slide in any step (SPEC Section 10.2)")


func test_thruster_slides_one_cell() -> void:
	var c := put("drone", 3, 3)
	shift([Defs.DIR_UP, Defs.DIR_LEFT])
	eq(c.pos, Vector2i(2, 2), "a Thruster slides 1 cell at most in each step (SPEC Section 10.2)")


func test_scrap_slides() -> void:
	var c := put("box", 2, 2)
	c.kind = Defs.KIND_SCRAP
	shift([Defs.DIR_DOWN])
	eq(c.pos, Vector2i(2, 5), "scrap slides as other cargo does (SPEC Section 6.4)")


func test_steps_start_where_the_last_stopped() -> void:
	var c := put("box", 2, 2)
	shift([Defs.DIR_LEFT, Defs.DIR_UP])
	eq(c.pos, Vector2i(0, 0), "each step starts where the last step stopped (SPEC Section 9)")


func test_force_is_weight_times_distance() -> void:
	var c := put("heavy", 3, 0)
	var s: Dictionary = shift([Defs.DIR_LEFT])[0]
	var hits := hits_of(s, c.id)
	eq(hits.size(), 1, "one hit (SPEC Section 10.3)")
	check(hits[0]["wall"], "the wall stopped it (SPEC Section 10.3)")
	eq(
		hits[0]["force"],
		9,
		"the force is the weight value times the distance: 3 x 3 (SPEC Section 10.3)"
	)
	eq(s["slides"][0]["distance"], 3, "the distance is the number of cells (SPEC Section 10.1)")


func test_blocker_takes_the_same_force() -> void:
	var front := put("vase", 0, 0)
	var back := put("heavy", 2, 0)
	var s: Dictionary = shift([Defs.DIR_LEFT])[0]
	var hits := hits_of(s, back.id)
	eq(hits[0]["other"], front.id, "the heavy cargo hits the vase (SPEC Section 10.3)")
	eq(hits[0]["force"], 3, "force 3 x 1 (SPEC Section 10.3)")
	eq(
		front.kind,
		Defs.KIND_SCRAP,
		"the cargo that blocks takes the same force (SPEC Section 10.3)"
	)


func test_no_distance_no_hit() -> void:
	# The box at (0,0) is at the front wall. The vase at (1,0) is behind it.
	put("box", 0, 0)
	var c := put("vase", 1, 0)
	var s: Dictionary = shift([Defs.DIR_LEFT])[0]
	eq(
		hits_of(s, c.id),
		[],
		"a cargo with a distance of 0 away from the front wall makes no hit (SPEC Section 10.3)"
	)
	eq(c.kind, Defs.KIND_FREIGHT, "the vase is intact (SPEC Section 10.3)")


func test_cushion() -> void:
	var foam := put("foam", 0, 0)
	var heavy := put("heavy", 4, 0)
	var s: Dictionary = shift([Defs.DIR_LEFT])[0]
	var hits := hits_of(s, heavy.id)
	eq(hits[0]["other"], foam.id, "the heavy cargo hits the foam (SPEC Section 10.3)")
	eq(hits[0]["force"], 0, "a Cushion makes the force 0 for both (SPEC Section 10.3)")
	var tr := RuleTest.new()
	var pad := tr.put("foam", 5, 0)
	var s2: Dictionary = tr.shift([Defs.DIR_LEFT])[0]
	eq(
		hits_of(s2, pad.id)[0]["force"],
		0,
		"a Cushion that hits a wall takes force 0 (SPEC Section 10.3)"
	)
	failures.append_array(tr.failures)


func test_thruster_stops_by_itself() -> void:
	put("drone", 3, 3)
	var s: Dictionary = shift([Defs.DIR_LEFT])[0]
	check(s["hits"].is_empty(), "a Thruster that stops by itself makes no hit (SPEC Section 10.2)")
	eq(s["slides"].size(), 1, "the Thruster slid (SPEC Section 10.2)")


func test_hits_do_not_add() -> void:
	# The vase slides 1 cell into the wall (force 1). The light cargo slides 1 cell into it (force 1).
	var vase := put("vase", 1, 0)
	put("light", 2, 0)
	shift([Defs.DIR_LEFT])
	eq(
		vase.kind,
		Defs.KIND_FREIGHT,
		"hits do not add: two hits of force 1 do not break it (SPEC Section 10.3)"
	)


func test_one_hit_for_each_blocker() -> void:
	var a := put("box", 0, 0)
	var b := put("box", 0, 1)
	var bar := put("bar", 3, 0, 1)  # cells (3,0) (3,1)
	var s: Dictionary = shift([Defs.DIR_LEFT])[0]
	var hits := hits_of(s, bar.id)
	eq(hits.size(), 2, "a cargo with two blockers takes one hit from each (SPEC Section 10.3)")
	eq([hits[0]["other"], hits[1]["other"]], [a.id, b.id], "the hits are in the order of the IDs")
	eq(hits[0]["force"], 4, "force 2 x 2 (SPEC Section 10.3)")


func test_wall_jolt() -> void:
	# The glass (standard, Fragile) is at the right wall and cannot slide right.
	var glass := put("glass", 5, 2)
	var s: Dictionary = shift([Defs.DIR_RIGHT])[0]
	var hits := hits_of(s, glass.id)
	eq(
		hits.size(),
		1,
		"a cargo at the front wall that does not slide takes a wall jolt (SPEC Section 10.4)"
	)
	if hits.size() == 1:
		check(
			hits[0]["wall"] and hits[0]["jolt"], "the jolt is a hit of the wall (SPEC Section 10.4)"
		)
		eq(hits[0]["force"], 2, "its force is the weight value (SPEC Section 10.4)")
	eq(
		glass.kind,
		Defs.KIND_SCRAP,
		"a standard Fragile cargo breaks from the jolt (SPEC Section 10.4)"
	)


func test_wall_jolt_limits() -> void:
	# Light Fragile at the wall: force 1, no break. A box behind it: no jolt.
	var vase := put("vase", 5, 0)
	var box := put("box", 4, 0)
	var s: Dictionary = shift([Defs.DIR_RIGHT])[0]
	eq(vase.kind, Defs.KIND_FREIGHT, "a light Fragile cargo holds at force 1 (SPEC Section 10.4)")
	eq(hits_of(s, box.id), [], "the jolt does not go to the cargo behind (SPEC Section 10.4)")


func test_wall_jolt_clamp_and_cushion() -> void:
	var glass := put("glass", 2, 5)
	run.clamp_cargo(glass.id)
	var foam := put("foam", 0, 5)
	var s: Dictionary = shift([Defs.DIR_DOWN])[0]
	eq(glass.kind, Defs.KIND_SCRAP, "a clamped cargo takes the wall jolt too (SPEC Section 10.4)")
	eq(
		hits_of(s, foam.id)[0]["force"] if hits_of(s, foam.id).size() > 0 else -1,
		0,
		"a Cushion takes the jolt with force 0 (SPEC Section 10.4)"
	)


func test_no_jolt_after_a_slide() -> void:
	var c := put("glass", 4, 0)
	var s: Dictionary = shift([Defs.DIR_RIGHT])[0]
	var hits := hits_of(s, c.id)
	eq(hits.size(), 1, "a cargo that slid into the wall takes one hit (SPEC Section 10.4)")
	check(
		hits.size() == 1 and not hits[0].get("jolt", false),
		"that hit is not a jolt (SPEC Section 10.4)"
	)
