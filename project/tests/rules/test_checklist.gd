extends RuleTest
## The warp checklist of the station (SPEC Section 20.2).


func test_checklist_values() -> void:
	# The first step is RIGHT: the glass at the right wall breaks in the jolt.
	run.hazard = PackedStringArray([Defs.DIR_RIGHT, Defs.DIR_UP])
	run.fork_options = PackedStringArray()
	put("glass", 5, 0)
	put("glass", 2, 4)
	on_dock("box")
	on_dock("bar")
	var v := RunView.view(run)
	eq(
		v["checklist"],
		{"fee": v["mass"]["fee"], "dock": 2, "jolts": 1, "incident": ""},
		"the checklist has the fee, the dock, the jolt warnings, and no incident (SPEC Section 20.2)"
	)


func test_checklist_fee() -> void:
	run.mass_limit = 1
	put("bar", 0, 0)
	var v := RunView.view(run)
	check(
		v["checklist"]["fee"] > 0,
		"the checklist shows the fuel fee over the mass limit (SPEC Section 20.2)"
	)
	eq(
		v["checklist"]["fee"],
		run.fuel_fee(),
		"the fee is the fuel fee of the warp (SPEC Section 25)"
	)


func test_checklist_incident() -> void:
	run.incident = {"kind": Defs.INCIDENT_METEOR, "x": 2}
	eq(
		RunView.view(run)["checklist"]["incident"],
		Defs.INCIDENT_METEOR,
		"the checklist names the incident of the jump (SPEC Sections 20.2 and 29.3)"
	)
