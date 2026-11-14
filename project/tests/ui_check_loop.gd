class_name UiCheckLoop
extends RefCounted
## The checks of the game loop for ui_check.gd: the gear button (SPEC Section 20.7)
## and the losses of a warp (SPEC Section 21.5).


## The gear button at the top right opens the pause menu (SPEC Sections 20.2 and 20.7).
static func gear(ui: Node, main: Control) -> void:
	var button: Button = main.gear
	var screen := ui.get_viewport().get_visible_rect().size
	var center := button.get_global_rect().get_center()
	ui._check(
		button.is_visible_in_tree() and center.x > screen.x * 0.9 and center.y < screen.y * 0.1,
		"the station has a gear button at the top right (SPEC Section 20.2)"
	)
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
	var panel: ChoicePanel = main.choice
	ui._check(panel != null, "the %s shows in a panel (SPEC Sections 20.8 and 20.9)" % run["phase"])
	ui._check(
		main.screen() is StationScreen, "the station shows behind the panel (SPEC Section 20.8)"
	)
	ui._check(
		not main.gear.visible,
		"the gear button hides while the player must select (SPEC Section 20.8)"
	)
	if panel == null:
		return
	var want: Array = (
		run["event"]["choices"] if run["phase"] == Defs.PHASE_EVENT else run["mod_offer"]
	)
	ui._check(
		panel.choices.size() == want.size(),
		"the panel has a button for each choice (SPEC Sections 20.8 and 20.9)"
	)
	if run["phase"] == Defs.PHASE_EVENT:
		for i in want.size():
			ui._check(
				panel.choices[i].disabled != bool(want[i]["can"]),
				"a choice that costs more than the credits is disabled (SPEC Section 20.8)"
			)
	var mods: int = run["mods"].size()
	for b in panel.choices:
		if not b.disabled:
			b.pressed.emit()
			break
	await ui.get_tree().process_frame
	run = GameState.view()["run"]
	if run["phase"] == Defs.PHASE_STATION and main.screen() is StationScreen:
		var station: StationScreen = main.screen()
		station.refresh()
		ui._check(
			station._mods_box.get_child_count() == run["mods"].size(),
			"the top bar has a tag for each mod (SPEC Section 20.2)"
		)
		ui._check(
			station._hold.mod_areas == run["mod_areas"],
			"the hold shows the areas of the mods (SPEC Section 27.2)"
		)
	if run["mods"].size() > mods:
		ui.mods_seen += 1
