extends RuleTest
## The press (SPEC Section 10.5). In a step down, a cargo that does not slide presses on
## the cargo under it. The fixture weights: light 1, standard 2, heavy 3. The vase is a
## light Fragile cargo and the glass a standard Fragile cargo: both break at force 2.


## Returns the presses of a step log.
static func presses(log_step: Dictionary) -> Array:
	return log_step["hits"].filter(func(h: Dictionary) -> bool: return h.get("press", false))


func test_heavy_press_breaks() -> void:
	# Column 0: heavy over vase over box. Column 2: box over glass over box.
	put("heavy", 0, 3)
	var vase := put("vase", 0, 4)
	put("box", 0, 5)
	put("box", 2, 3)
	var glass := put("glass", 2, 4)
	put("box", 2, 5)
	shift([Defs.DIR_DOWN])
	eq(
		vase.kind,
		Defs.KIND_SCRAP,
		"a heavy cargo that does not slide presses with force 3 and breaks the vase (SPEC Section 10.5)"
	)
	eq(
		glass.kind,
		Defs.KIND_SCRAP,
		"a standard cargo presses with force 2 and breaks the glass (SPEC Section 10.5)"
	)


func test_light_press_and_no_sum() -> void:
	# Column 0: two light cargo over the vase. The press is 1: the weights do not add.
	put("light", 0, 2)
	put("light", 0, 3)
	var vase := put("vase", 0, 4)
	put("box", 0, 5)
	var logs := shift([Defs.DIR_DOWN])
	eq(vase.kind, Defs.KIND_FREIGHT, "a light cargo presses with force 1 (SPEC Section 10.5)")
	var on_vase: Array = presses(logs[0]).filter(
		func(h: Dictionary) -> bool: return h["other"] == vase.id
	)
	eq(
		on_vase.map(func(h: Dictionary) -> int: return h["force"]),
		[1],
		"the vase takes one press of force 1: the weights further behind do not add (SPEC Section 10.5)"
	)


func test_clamp_and_press() -> void:
	run.clamps = 2
	# Column 0: a clamped heavy over the vase. Column 2: a box over a clamped glass, with a
	# gap under the glass.
	var heavy := put("heavy", 0, 3)
	var vase := put("vase", 0, 4)
	put("box", 0, 5)
	put("box", 2, 2)
	var glass := put("glass", 2, 3)
	eq(run.clamp_cargo(heavy.id), "", "clamp the heavy cargo")
	eq(run.clamp_cargo(glass.id), "", "clamp the glass")
	shift([Defs.DIR_DOWN])
	eq(vase.kind, Defs.KIND_FREIGHT, "a clamped cargo does not press (SPEC Section 10.5)")
	eq(glass.kind, Defs.KIND_SCRAP, "a clamped cargo can take a press (SPEC Section 10.5)")


func test_cushion_press() -> void:
	# Column 0: heavy over the Foam Pad over the glass over a box.
	put("heavy", 0, 2)
	var foam := put("foam", 0, 3)
	var glass := put("glass", 0, 4)
	put("box", 0, 5)
	var logs := shift([Defs.DIR_DOWN])
	var force := {}
	for h: Dictionary in presses(logs[0]):
		force[h["other"]] = h["force"]
	eq(
		[force.get(foam.id, -1), force.get(glass.id, -1)],
		[0, 0],
		"a Cushion cargo takes and makes a press of force 0 (SPEC Section 10.5)"
	)
	eq(glass.kind, Defs.KIND_FREIGHT, "the glass under the Foam Pad stays intact")


func test_padded_walls_no_change() -> void:
	run.mods.append(Defs.MOD_PADDED_WALLS)
	put("heavy", 0, 3)
	var vase := put("vase", 0, 4)
	put("box", 0, 5)
	shift([Defs.DIR_DOWN])
	eq(
		vase.kind,
		Defs.KIND_SCRAP,
		"the Padded Walls mod does not change a press (SPEC Section 10.5)"
	)


func test_press_log() -> void:
	# Column 0: the box at the top slides onto the heavy cargo. Column 2: a box on a box.
	var slid := put("box", 0, 0)
	var heavy := put("heavy", 0, 5)
	var top := put("box", 2, 4)
	var bottom := put("box", 2, 5)
	var logs := shift([Defs.DIR_DOWN])
	var p := presses(logs[0])
	eq(
		p.map(func(h: Dictionary) -> Array: return [h["cargo"], h["other"], h["force"]]),
		[[top.id, bottom.id, 2]],
		"the log has the press of the box on the box, with its force (SPEC Section 10.5)"
	)
	var hit: Array = hits_of(logs[0], slid.id)
	eq(
		hit.map(func(h: Dictionary) -> Array: return [h["other"], h["force"], h["press"]]),
		[[heavy.id, 2 * 4, false]],
		"a cargo that slid makes its hit and does not press (SPEC Section 10.5)"
	)
