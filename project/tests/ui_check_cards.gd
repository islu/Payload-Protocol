class_name UiCheckCards
## The contract cards and the dock part of the UI check (ui_check.gd). It is in its own
## file, so that ui_check.gd stays under the line limit of gdlint.


## The contract cards and the dock (SPEC Section 20.2).
static func check(ui: Node, station: StationScreen) -> void:
	var run: Dictionary = GameState.view()["run"]
	ui._check(
		station._contract_cards.size() == run["contracts"].size(),
		"the board shows a card for each contract (SPEC Section 20.2)"
	)
	var seen_open := false
	var seen_accepted := false
	for i in mini(station._contract_cards.size(), run["contracts"].size()):
		var k: Dictionary = run["contracts"][i]
		var card: ContractCard = station._contract_cards[i]
		for g: Dictionary in k["groups"]:
			ui._check(
				"×%d" % g["count"] in card.text,
				"a card shows each freight one time with ×N (SPEC Section 20.2)"
			)
		ui._check(
			str(k["total_pay"]) in card.first_line and str(k["mass"]) in card.first_line,
			"the first line shows the total pay and the mass (SPEC Section 20.2)"
		)
		card.mouse_entered.emit()
		var tip: String = station._tip.text() if station._tip.visible else ""
		ui._check(
			"%d" % k["pieces"] in tip and str(k["pay"]) in tip,
			"the mouse on a card shows the pieces and the pay for each piece (SPEC Section 20.2)"
		)
		var border: Color = card.get_theme_stylebox("panel").border_color
		if k["accepted"]:
			seen_accepted = true
			ui._check(
				border == Palette.ACCENT, "an accepted card has a bright border (SPEC Section 20.2)"
			)
			ui._check(
				"%d/%d" % [k["loaded"], k["pieces"]] in card.text,
				"an accepted card shows Loaded N/M (SPEC Section 20.2)"
			)
		else:
			seen_open = true
			ui._check(
				border != Palette.ACCENT,
				"a card that is not accepted has no bright border (SPEC Section 20.2)"
			)
			ui._check(
				str(k["mass_after"]) in tip,
				"the details show the mass after it is accepted (SPEC Section 20.2)"
			)
			var colors := {"ok": Palette.TEXT_DIM, "fee": Palette.WARN, "over": Palette.BAD}
			var want: Color = colors[k["mass_state"]]
			(
				ui
				. _check(
					card.mass_color == want,
					"the mass after is yellow above the limit and red above the maximum (SPEC Section 20.2)"
				)
			)
		card.mouse_exited.emit()
	ui._check(seen_open and seen_accepted, "the check sees an open card and an accepted card")
	ui._check(
		str(run["dock"].size()) in station._dock_title.text,
		"the dock title shows the number of cargo on the dock (SPEC Section 20.2)"
	)
	var chips := station._dock_flow.get_children().filter(
		func(n: Node) -> bool: return n is CargoChip
	)
	ui._check(
		chips.size() == run["dock"].size(),
		"the dock shows each cargo on the dock (SPEC Section 20.2)"
	)
	if not chips.is_empty():
		ui._check(
			is_equal_approx(chips[0].cell, StationScreen.DOCK_CELL),
			"the dock shows its cargo at 48 pixels for each cell (SPEC Section 20.2)"
		)
	# An empty dock is one line of text.
	var saved: Array = station._run["dock"]
	station._run["dock"] = []
	var cargo: Array = station._run["cargo"]
	station._run["cargo"] = cargo.filter(func(c: Dictionary) -> bool: return c["in_hold"])
	station._refresh_dock()
	await ui.get_tree().process_frame
	ui._check(
		station._dock_panel.size.y < 70.0,
		"an empty dock is one line: %d (SPEC Section 20.2)" % station._dock_panel.size.y
	)
	station._run["dock"] = saved
	station._run["cargo"] = cargo
	station._refresh_dock()
