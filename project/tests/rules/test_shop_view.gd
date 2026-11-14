extends RuleTest
## The view of the shop: how each kit offer helps the freight, and the services
## before and after a purchase (SPEC Section 20.2).


## Sets the shop to offers of fixture kit, and returns the offers of the view.
func _offers(ids: Array) -> Array:
	run.shop.clear()
	for id: String in ids:
		run.shop.append({"def": run.cat.cargo[id], "bought": false})
	return RunView.view(run)["shop"]["offers"]


func _helps(offer: Dictionary) -> int:
	var h: Dictionary = offer["helps"]
	return -1 if h.is_empty() else int(h["args"]["count"])


func test_kit_helps_freight() -> void:
	on_dock("cheese")
	put("cheese", 0, 0)
	put("vase", 2, 0)
	on_dock("bomb")
	put("chip", 4, 0)
	put("box", 0, 2)
	var o := _offers(["cooler", "foam", "shield", "anchor"])
	eq(
		_helps(o[0]),
		2,
		"a Cooler counts the Perishable freight on the dock and in the hold (SPEC Section 20.2)"
	)
	eq(_helps(o[1]), 1, "a Cushion counts the Fragile freight (SPEC Section 20.2)")
	eq(
		_helps(o[2]),
		3,
		"a Shield counts the Fragile, Volatile, Fluid, or Electronic freight (SPEC Section 20.2)"
	)
	eq(_helps(o[3]), -1, "other kit shows nothing (SPEC Section 20.2)")


func test_kit_helps_nothing_at_zero() -> void:
	put("box", 0, 0)
	var o := _offers(["cooler", "battery"])
	eq(_helps(o[0]), -1, "a count of 0 shows nothing (SPEC Section 20.2)")
	eq(_helps(o[1]), -1, "a Battery with no Shield shows nothing (SPEC Section 20.2)")


func test_battery_counts_shields() -> void:
	put("shield", 0, 0)
	on_dock("shield")
	put("cheese", 2, 0)
	var o := _offers(["battery"])
	eq(
		_helps(o[0]),
		2,
		"a Battery counts the Shield kit on the dock and in the hold (SPEC Section 20.2)"
	)


func test_sensor_shows_a_fork() -> void:
	run.fork_options = PackedStringArray()
	var o := _offers(["sensor"])
	eq(
		o[0]["helps"],
		{},
		"a Sensor shows nothing when the next jump has no fork step (SPEC Section 20.2)"
	)
	run.fork_options = PackedStringArray([Defs.DIR_LEFT, Defs.DIR_RIGHT])
	o = _offers(["sensor"])
	eq(
		o[0]["helps"].get("key", ""),
		RunView.FORK_HELP_TEXT,
		"a Sensor shows that the next jump has a fork step (SPEC Section 20.2)"
	)


func test_services_before_and_after() -> void:
	var s: Dictionary = RunView.view(run)["shop"]
	eq(s["clamps"], run.clamps, "the clamps now (SPEC Section 20.2)")
	eq(s["clamps_after"], run.clamps + 1, "the clamps after a purchase (SPEC Section 20.2)")
	eq(s["mass_limit"], run.mass_limit, "the mass limit now (SPEC Section 20.2)")
	eq(
		s["mass_limit_after"],
		run.mass_limit + run.cat.reinforce_amount,
		"the mass limit after Reinforce hull (SPEC Section 20.2)"
	)
