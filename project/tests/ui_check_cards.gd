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
	# A black market contract: a purple tag and a purple border (SPEC Section 30.4).
	if not run["contracts"].is_empty():
		var k: Dictionary = run["contracts"][0].duplicate(true)
		k["tags"] = [Defs.TAG_BLACK_MARKET]
		var card := ContractCard.new()
		station._contracts_box.add_child(card)
		card.setup(station, k)
		var border: Color = card.get_theme_stylebox("panel").border_color
		ui._check(
			ui.tr(ContractCard.TAG_TEXT[Defs.TAG_BLACK_MARKET]) in card.text,
			"a black market card shows its tag (SPEC Section 30.4)"
		)
		ui._check(
			k["accepted"] or border == Palette.BLACK_MARKET,
			"a black market card has a purple border (SPEC Section 30.4)"
		)
		card.queue_free()
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
	var saved: Array = station.run_data["dock"]
	station.run_data["dock"] = []
	var cargo: Array = station.run_data["cargo"]
	station.run_data["cargo"] = cargo.filter(func(c: Dictionary) -> bool: return c["in_hold"])
	station._refresh_dock()
	await ui.get_tree().process_frame
	ui._check(
		station.dock_panel.size.y < 70.0,
		"an empty dock is one line: %d (SPEC Section 20.2)" % station.dock_panel.size.y
	)
	# The dock is below the contract board and above the pilot box.
	var board := station._contracts_scroll.get_global_rect()
	var dock := station.dock_panel.get_global_rect()
	ui._check(
		(
			dock.position.y >= board.end.y
			and dock.end.y <= station._pilot_panel.get_global_rect().position.y
		),
		(
			"the dock is below the contracts and above the pilot: %s %s (SPEC Section 20.2)"
			% [board, dock]
		)
	)
	# A full dock is 3 rows high at most, and scrolls.
	var offers: Array = station.run_data["shop"]["offers"]
	if not offers.is_empty():
		var many := []
		for i in 12:
			var c: Dictionary = offers[0].duplicate(true)
			c["id"] = 9000 + i
			c["in_hold"] = false
			c["in_bay"] = false
			many.append(c)
		station.run_data["cargo"] = many
		station.run_data["dock"] = many.map(func(c: Dictionary) -> int: return c["id"])
		station._refresh_dock()
		await ui.get_tree().process_frame
		ui._check(
			station._dock_scroll.size.y <= StationScreen.DOCK_MAX_HEIGHT + 1.0,
			(
				"a full dock is 3 rows high at most: %d (SPEC Section 20.2)"
				% station._dock_scroll.size.y
			)
		)
		ui._check(
			station._contracts_scroll.size.y > 200.0,
			(
				"the contracts show beside a full dock: %d (SPEC Section 20.2)"
				% station._contracts_scroll.size.y
			)
		)
	station.run_data["dock"] = saved
	station.run_data["cargo"] = cargo
	station._refresh_dock()
