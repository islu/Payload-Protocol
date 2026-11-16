class_name UiCheckTopBar
## The top bar of the station: four groups (SPEC Section 20.2). A part of the UI
## check (ui_check.gd), in its own file for the line limit.


static func check(ui: Node, station: StationScreen) -> void:
	var run: Dictionary = GameState.view()["run"]
	_check_list(ui, station, run)
	var bar: TopBar = station._top_bar
	ui._check(
		[bar.dots.total, bar.dots.current] == [run["jumps"], run["jump"]],
		"group 1 has a dot for each jump of the leg, up to the jump now (SPEC Section 20.2)"
	)
	ui._check(
		[bar.pay_bar.value, bar.pay_bar.maximum] == [run["credits"], run["payment"]],
		"group 2 has a bar of the credits against the payment (SPEC Section 20.2)"
	)
	var m: Dictionary = run["mass"]
	ui._check(
		(
			[bar.mass_bar.value, bar.mass_bar.maximum, bar.mass_bar.marks]
			== [m["hold"], m["max"], [m["limit"]]]
		),
		"group 3: a bar of the mass to the maximum, with a mark at the limit (SPEC Section 20.2)"
	)
	var env: Dictionary = run["environment"]
	ui._check(
		bar.env_badge.visible != env.is_empty(),
		"group 4 shows the environment of the leg, if it has one (SPEC Sections 20.2 and 28.1)"
	)
	if not env.is_empty():
		ui._check(
			tr_text(env["text"]) in bar.env_badge.tooltip_text,
			"the mouse on the badge shows the rule of the environment (SPEC Section 28.1)"
		)
	var xs := []
	for g: Control in bar.groups:
		if g.visible:
			xs.append(g.global_position.x)
	var sorted := xs.duplicate()
	sorted.sort()
	ui._check(
		xs == sorted and xs.size() >= 3, "the groups go from left to right (SPEC Section 20.2)"
	)


static func tr_text(key: String) -> String:
	return TranslationServer.translate(key)


## The warp checklist above the Warp button (SPEC Section 20.2): 4 rows, each with the
## value of view.run.checklist, and a warning when it is not clear.
static func _check_list(ui: Node, station: StationScreen, run: Dictionary) -> void:
	var list: WarpChecklist = station._checklist
	var c: Dictionary = run["checklist"]
	ui._check(
		list.global_position.y < station._warp_button.global_position.y,
		"the warp checklist is above the Warp button (SPEC Section 20.2)"
	)
	ui._check(
		list.warnings == [c["fee"] > 0, c["dock"] > 0, c["jolts"] > 0, c["incident"] != ""],
		"each row of the checklist warns when it is not clear (SPEC Section 20.2)"
	)
	ui._check(
		c["fee"] == 0 or str(c["fee"]) in list.rows[0].text,
		"the checklist shows the fuel fee (SPEC Section 20.2)"
	)
	ui._check(
		c["dock"] == 0 or str(c["dock"]) in list.rows[1].text,
		"the checklist shows the cargo on the dock (SPEC Section 20.2)"
	)
	ui._check(
		c["jolts"] == 0 or str(c["jolts"]) in list.rows[2].text,
		"the checklist shows the cargo with a wall jolt warning (SPEC Section 20.2)"
	)
	ui._check(
		c["incident"] == "" or RouteCards.incident_text(run["incident"]) in list.rows[3].text,
		"the checklist shows the incident of the jump (SPEC Sections 20.2 and 29.3)"
	)
