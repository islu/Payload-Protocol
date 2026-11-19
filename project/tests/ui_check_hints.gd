class_name UiCheckHints
## The hints part of the UI check (ui_check.gd): the pilot gives one hint for each new
## thing that the tutorial does not teach, in order, and a hint ends at the warp or at
## the pick (SPEC Section 23.3). It is in its own file, so that ui_check.gd stays under
## the line limit of gdlint.


static func check(ui: Node, main_scene: PackedScene) -> void:
	TranslationServer.set_locale("en")
	var main: Control = main_scene.instantiate()
	ui.add_child(main)
	await ui.get_tree().process_frame
	# The hints are for the normal runs after the tutorial (UiCheckTutorial checks it).
	Settings.set_value("tutorial_done", true)
	main.start_run()
	await ui.get_tree().process_frame
	var station: StationScreen = main.screen()
	# The screen changes at each station: read the one now.
	var text := func() -> String: return (main.screen() as StationScreen)._pilot_label.text
	ui._check(
		text.call().begins_with("MAGELLAN: "),
		"leg 1 has nothing new: the pilot speaks its line, not a hint (SPEC Section 23.3)"
	)
	ui._check(station._pilot_label.visible_ratio < 1.0, "a new line types out (SPEC Section 22)")
	ui._check(
		not (
			station
			. find_children("*", "", true, false)
			. filter(func(n: Node) -> bool: return n is PilotFace)
			. is_empty()
		),
		"the pilot box shows the portrait (SPEC Section 22)"
	)
	ui._finish_tweens()
	ui._check(
		is_equal_approx(station._pilot_label.visible_ratio, 1.0),
		"the line ends typed out (SPEC Section 22)"
	)
	# An environment, an incident, and a fork step: the environment comes first.
	GameState.set_up(_set_new)
	await ui.get_tree().process_frame
	ui._check(
		text.call().contains(Hints.text(Hints.ENVIRONMENT)),
		"a new environment gives the first hint (SPEC Section 23.3)"
	)
	station._on_warp_pressed()
	await ui.get_tree().process_frame
	ui._check(
		Hints.ENVIRONMENT in Settings.get_value("hints_seen"),
		"the hint of a station ends at the warp (SPEC Section 23.3)"
	)
	GameState.continue_run()
	await ui.get_tree().process_frame
	var run: Dictionary = GameState.view()["run"]
	if run["phase"] == Defs.PHASE_EVENT:
		var panel: EventPanel = main.choice
		ui._check(
			panel.hint != null and panel.hint.text.contains(Hints.text(Hints.EVENT)),
			"the first event has a pilot hint (SPEC Section 23.3)"
		)
		await ui.get_tree().process_frame
		if panel.hint != null:
			var box := panel.dialogue.get_global_rect()
			ui._check(
				box.encloses(panel.hint.get_global_rect()),
				(
					"the hint of an event is in the dialogue box: %s in %s (SPEC Section 23.3)"
					% [panel.hint.get_global_rect(), box]
				)
			)
		panel.choices[-1].pressed.emit()
		await ui.get_tree().process_frame
		ui._check(
			Hints.EVENT in Settings.get_value("hints_seen"),
			"the hint of an event ends at the pick (SPEC Section 23.3)"
		)
	GameState.set_up(_set_new)
	await ui.get_tree().process_frame
	ui._check(
		text.call().contains(Hints.text(Hints.INCIDENT)),
		"the environment hint does not show again; the incident is next (SPEC Section 23.3)"
	)
	GameState.set_up(StationEvents.offer_mods)
	await ui.get_tree().process_frame
	var choice: ChoicePanel = main.choice
	ui._check(
		choice.hint != null and choice.hint.text.contains(Hints.text(Hints.MOD)),
		"the first mod choice has a pilot hint (SPEC Section 23.3)"
	)
	choice.choices[0].pressed.emit()
	await ui.get_tree().process_frame
	ui._check(
		Hints.MOD in Settings.get_value("hints_seen"),
		"the hint of a mod choice ends at the pick (SPEC Section 23.3)"
	)
	for i in Hints.RUNS_WITH_HINTS:
		Hints.run_started()
	ui._check(
		not Settings.get_value("hints"),
		"the hints turn off after the first runs (SPEC Section 23.3)"
	)
	(main.screen() as StationScreen).refresh()
	ui._check(
		text.call().begins_with("MAGELLAN: "),
		"with the hints off, the pilot gives no hint (SPEC Section 23.3)"
	)
	GameState.abandon_run()
	main.queue_free()
	await ui.get_tree().process_frame


## Gives the station an environment, an incident, and a fork step.
static func _set_new(r: Run) -> void:
	r.environment = Defs.ENV_HEAT_ZONE
	r.incident = {"kind": Defs.INCIDENT_METEOR, "x": 2}
	r.hazard = PackedStringArray([Defs.DIR_LEFT, Defs.DIR_UP])
	r.fork_options = PackedStringArray([Defs.DIR_UP, Defs.DIR_RIGHT])
