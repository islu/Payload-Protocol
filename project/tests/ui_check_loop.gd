class_name UiCheckLoop
extends RefCounted
## The checks of the game loop for ui_check.gd: the gear button (SPEC Section 20.7)
## and the losses of a warp (SPEC Section 21.5).


## The gear button at the top right opens the pause menu (SPEC Sections 20.2 and 20.7).
static func gear(ui: Node, main: Control) -> void:
	var button: GearButton = main.gear
	var screen := ui.get_viewport().get_visible_rect().size
	var center := button.get_global_rect().get_center()
	ui._check(
		button.is_visible_in_tree() and center.x > screen.x * 0.9 and center.y < screen.y * 0.1,
		"the station has a gear button at the top right (SPEC Section 20.2)"
	)
	button.mouse_entered.emit()
	ui._check(
		button.tip.visible and ui.tr(GearButton.MENU_TEXT) in button.tip.text(),
		"the mouse on the gear button shows what it does"
	)
	button.mouse_exited.emit()
	button.pressed.emit()
	await ui.get_tree().process_frame
	var opened: Node = null
	for o in main._overlays.get_children():
		if o is PauseMenu:
			opened = o
	ui._check(
		opened != null and ui.get_tree().paused,
		"the gear button opens the pause menu (SPEC Section 20.7)"
	)
	if opened != null:
		opened.close()
	await ui.get_tree().process_frame


## The warp shows the lost pay, the chain count, and the total loss (SPEC Section 21.5).
## Returns true when the warp had a loss or a chain, so that a check ran.
static func losses(ui: Node, warp: WarpScreen) -> bool:
	var w: Dictionary = GameState.view()["run"]["warp"]
	var lost := false
	var chain := 0
	for step: Dictionary in w["steps"]:
		for r: Dictionary in step["reactions"]:
			lost = lost or r["loss"] > 0
			chain = maxi(chain, r["chain"])
	if lost:
		ui._check(
			warp._fx.played.has("loss"),
			"a freight that becomes scrap shows its lost pay (SPEC Section 21.5)"
		)
		ui._check(
			str(w["loss"]) in warp.loss_text,
			"the warp shows the total lost pay (SPEC Section 21.5)"
		)
	if chain >= 2:
		ui._check(warp.chain_shown == chain, "the warp shows the chain count (SPEC Section 21.5)")
	return lost or chain >= 2


## Checks the event or the mod choice, and selects the first choice that it can
## (SPEC Sections 20.8 and 20.9).
static func choose(ui: Node, main: Control) -> void:
	var run: Dictionary = GameState.view()["run"]
	ui._check(
		not main.gear.visible,
		"the gear button hides while the player must select (SPEC Sections 20.8 and 20.9)"
	)
	ui._check(
		main.screen() is StationScreen,
		"the station shows behind the panel (SPEC Sections 20.8 and 20.9)"
	)
	var buttons: Array[Button] = []
	if run["phase"] == Defs.PHASE_EVENT:
		var event_panel := main.choice as EventPanel
		ui._check(event_panel != null, "the event shows in a panel (SPEC Section 20.8)")
		if event_panel == null:
			return
		buttons = event_panel.choices
		_check_event(ui, event_panel, run["event"])
	else:
		var panel := main.choice as ChoicePanel
		ui._check(panel != null, "the mod choice shows in a panel (SPEC Section 20.9)")
		if panel == null:
			return
		buttons = panel.choices
		var want: Array = run["mod_offer"]
		ui._check(
			buttons.size() == want.size(), "the panel has a card for each mod (SPEC Section 20.9)"
		)
		var icons: Array = panel.mod_icons.map(func(m: ModIcon) -> String: return m.mod)
		var ids: Array = want.map(func(m: Dictionary) -> String: return m["id"])
		ui._check(
			icons == ids, "each mod card has the icon of its mod: %s (SPEC Section 20.9)" % [icons]
		)
	var was_event: bool = run["phase"] == Defs.PHASE_EVENT
	var mods: int = run["mods"].size()
	for b in buttons:
		if not b.disabled:
			b.pressed.emit()
			break
	await ui.get_tree().process_frame
	run = GameState.view()["run"]
	if was_event:
		ui._check(
			run["phase"] == Defs.PHASE_EVENT or not main.choice is EventPanel,
			"after the choice of an event, the panel closes (SPEC Section 20.8)"
		)
	if run["phase"] == Defs.PHASE_STATION and main.screen() is StationScreen:
		var station: StationScreen = main.screen()
		station.refresh()
		var bar: ModBar = station._mod_bar
		ui._check(
			bar.cards.size() == run["mods"].size(),
			"the mod bar has a card for each mod (SPEC Section 20.2)"
		)
		for i in mini(bar.cards.size(), run["mods"].size()):
			var m: Dictionary = run["mods"][i]
			bar.cards[i].mouse_entered.emit()
			ui._check(
				(
					station._tip.visible
					and GameText.format(m["text"]) in station._tip.text()
					and TranslationServer.translate(m["name"]) in station._tip.text()
				),
				"the mouse on a mod card shows its name and its rule at once (SPEC Section 20.2)"
			)
			ui._check(
				station.hold_view.hover_mod == m["id"],
				"the mouse on a mod card marks its area on the hold (SPEC Section 20.2)"
			)
			bar.cards[i].mouse_exited.emit()
			ui._check(not station._tip.visible, "the tip hides when the mouse leaves the card")
		for id in Defs.MODS:
			ui._check(ModIcon.has_icon(id), "the mod %s has an icon (SPEC Section 20.2)" % id)
		ui._check(
			station.hold_view.mod_areas == run["mod_areas"],
			"the hold shows the areas of the mods (SPEC Section 27.2)"
		)
	if run["mods"].size() > mods:
		ui.mods_seen += 1


## The station shows the environment and the incident, and the hold marks the place
## of the incident (SPEC Sections 28.1 and 29.3). Returns 1 when the station had one.
static func route_station(ui: Node, station: StationScreen) -> int:
	var run: Dictionary = GameState.view()["run"]
	var seen := 0
	if not run["environment"].is_empty():
		seen = 1
		ui._check(
			station._top_bar.env_badge.visible,
			"the top bar shows the environment of the leg (SPEC Section 28.1)"
		)
		ui._check(
			station._hazard_box.get_child(0).name == "Environment",
			"the hazard panel shows the environment first (SPEC Section 28.1)"
		)
	if not run["incident"].is_empty():
		seen = 1
		var card := station._hazard_box.get_node_or_null("Incident")
		ui._check(card != null, "the hazard panel shows the incident (SPEC Section 29.3)")
		ui._check(
			station.hold_view.incident_cells == run["incident"]["cells"],
			"the hold marks the place of the incident (SPEC Section 29.3)"
		)
	return seen


## The warp plays the incident before the first step (SPEC Section 29.3).
static func route_warp(ui: Node, warp: WarpScreen) -> void:
	var inc: Dictionary = GameState.view()["run"]["warp"].get("incident", {})
	if not inc.is_empty():
		ui._check(
			warp.incident_shown == RouteCards.incident_text(inc),
			"the warp shows the incident in a banner (SPEC Section 29.3)"
		)


## Checks the event panel: the speaker, the dialogue, and a button for each choice
## (SPEC Section 20.8). Each speaker of the data has a portrait.
static func _check_event(ui: Node, panel: EventPanel, event: Dictionary) -> void:
	var speaker: Dictionary = event["speaker"]
	var portrait := panel.speaker_portrait
	ui._check(
		portrait != null and portrait.texture != null,
		"the event panel shows the portrait of %s (SPEC Section 20.8)" % speaker["id"]
	)
	ui._check(
		panel.speaker_name != null and panel.speaker_name.text == ui.tr(speaker["name"]),
		"the dialogue box shows the name of the speaker (SPEC Section 20.8)"
	)
	# The heads have the same size (task art), and the top of each portrait is the top
	# of the head: the same height shows for each speaker (SPEC Section 20.8).
	if portrait != null and portrait.texture != null:
		ui._check(
			portrait.texture.get_height() == EventPanel.FIGURE_HEIGHT,
			"the head of the speaker is at the same height for each speaker (SPEC Section 20.8)"
		)
	var want: Array = event["choices"]
	ui._check(
		panel.choices.size() == want.size(),
		"the dialogue box has a button for each choice (SPEC Section 20.8)"
	)
	for i in mini(want.size(), panel.choices.size()):
		ui._check(
			panel.choices[i].disabled != bool(want[i]["can"]),
			"a choice that costs more than the credits is disabled (SPEC Section 20.8)"
		)
		if not want[i]["can"]:
			panel.choices[i].mouse_entered.emit()
			ui._check(
				panel.tip.visible and ui.tr(want[i]["why"]) in panel.tip.text(),
				"the mouse on a disabled choice shows why (SPEC Section 26.2)"
			)
			panel.choices[i].mouse_exited.emit()
	for id: String in DataFiles.catalog().speakers:
		var path := EventPanel.PORTRAIT_PATH % id
		ui._check(ResourceLoader.exists(path), "the speaker %s has a portrait (content.md)" % id)
		if ResourceLoader.exists(path):
			ui._check(
				load(path).get_height() >= EventPanel.FIGURE_HEIGHT,
				"the portrait of %s reaches the bottom of the dialogue box (SPEC Section 20.8)" % id
			)
