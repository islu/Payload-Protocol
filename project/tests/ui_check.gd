extends Node
## Plays a full run through the screens of the main scene, headless. It fails
## on a SCRIPT ERROR (Taskfile) or a failed check. It is a scene, so that the
## autoloads exist as in the game.
## Run: godot --headless --path project res://tests/ui_check.tscn

const MAIN_SCENE := preload("res://scenes/main/main.tscn")

var _failures := 0


func _ready() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAIL ui: " + what)


func _run() -> void:
	get_tree().create_timer(120.0).timeout.connect(func() -> void: get_tree().quit(2))
	# Keep the settings of the player: the check writes the hint progress.
	var saved := FileAccess.get_file_as_string(Settings.PATH)
	DirAccess.remove_absolute(Settings.PATH)
	Settings._config = null
	await _check_hints()
	for sound in Sound.NAMES:
		_check(Sound.exists(sound), "the sound %s has a file (SPEC Section 4.3)" % sound)
	# Play in each language, so that a translation with a bad placeholder fails here.
	for locale in Settings.LOCALES:
		TranslationServer.set_locale(locale)
		var main: Control = MAIN_SCENE.instantiate()
		add_child(main)
		# Main applies the saved language. Use the language of this pass.
		TranslationServer.set_locale(locale)
		await get_tree().process_frame
		await _play_run(main)
		main.queue_free()
		await get_tree().process_frame
	DirAccess.remove_absolute(Settings.PATH)
	if saved != "":
		var f := FileAccess.open(Settings.PATH, FileAccess.WRITE)
		f.store_string(saved)
		f.close()
	Settings._config = null
	print("ui_check: %s" % ("passed" if _failures == 0 else "%d failed" % _failures))
	get_tree().quit(1 if _failures > 0 else 0)


func _play_run(main: Control) -> void:
	var state: Node = GameState
	var new_run: Button = main.screen().find_child("NewRunButton", true, false)
	_check(new_run != null, "the title shows first (SPEC Section 20.1)")
	await get_tree().process_frame
	var mid := new_run.get_global_rect().get_center()
	var screen := get_viewport().get_visible_rect().size
	_check(
		absf(mid.x - screen.x / 2.0) < 2.0 and absf(mid.y - screen.y / 2.0) < 120.0,
		"the title is in the center: %s of %s (SPEC Section 20.1)" % [mid, screen]
	)
	state.new_run(11)
	await get_tree().process_frame
	await _check_overlays(main)
	_check(main.screen() is StationScreen, "a new run opens the station (SPEC Section 20.2)")
	var station: StationScreen = main.screen()
	var jumps := 0
	while state.view()["run"]["phase"] != Defs.PHASE_END and jumps < 40:
		jumps += 1
		var run: Dictionary = state.view()["run"]
		match run["phase"]:
			Defs.PHASE_STATION:
				station = main.screen()
				await _play_station(state, station)
			Defs.PHASE_ARRIVAL:
				await _play_warp(main)
				state.continue_run()
			Defs.PHASE_TOLL:
				state.pay_toll()
		await get_tree().process_frame
	_check(
		state.view()["run"]["phase"] == Defs.PHASE_END,
		"the run reaches its end (SPEC Section 19.2)"
	)
	state.abandon_run()
	await get_tree().process_frame


## The hints of the first run come in order, and each ends when the player does
## its thing (SPEC Section 23.3).
func _check_hints() -> void:
	TranslationServer.set_locale("en")
	var main: Control = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame
	main.start_run()
	await get_tree().process_frame
	var station: StationScreen = main.screen()
	var text := func() -> String: return station._pilot_label.text
	_check(
		text.call().contains(Hints.text(Hints.ACCEPT)),
		"the first hint is: accept a contract (SPEC Section 23.3)"
	)
	GameState.accept_contract(0)
	await get_tree().process_frame
	_check(text.call().contains(Hints.text(Hints.DRAG)), "then: drag a cargo (SPEC Section 23.3)")
	var run: Dictionary = GameState.view()["run"]
	var placed := false
	for y in run["hold"]["rows"]:
		for x in run["hold"]["columns"]:
			if not placed and GameState.can_place(run["dock"][0], x, y, 0):
				placed = GameState.place_cargo(run["dock"][0], x, y, 0) == ""
	await get_tree().process_frame
	_check(
		text.call().contains(Hints.text(Hints.ROTATE)), "then: rotate a cargo (SPEC Section 23.3)"
	)
	Hints.done(Hints.ROTATE)
	station.refresh()
	_check(
		text.call().contains(Hints.text(Hints.HAZARD)), "then: read the hazard (SPEC Section 23.3)"
	)
	Hints.done(Hints.HAZARD)
	station.refresh()
	_check(text.call().contains(Hints.text(Hints.WARP)), "then: warp (SPEC Section 23.3)")
	Hints.done(Hints.WARP)
	station.refresh()
	_check(
		text.call().begins_with("PIP: "),
		"after the last hint, the pilot speaks its line (SPEC Section 22)"
	)
	for i in Hints.RUNS_WITH_HINTS:
		Hints.run_started()
	_check(
		not Settings.get_value("hints"),
		"the hints turn off after the first runs (SPEC Section 23.3)"
	)
	GameState.abandon_run()
	main.queue_free()
	await get_tree().process_frame


## Plays the warp fast, and checks that the report shows at the end (SPEC Sections 20.3 and 20.4).
func _play_warp(main: Control) -> void:
	await get_tree().process_frame
	var warp: WarpScreen = main.screen()
	_check(warp is WarpScreen, "the warp plays after the Warp button (SPEC Section 20.3)")
	warp.speed_up()
	warp.speed = 200.0
	var frames := 0
	while not warp.finished and frames < 2000:
		frames += 1
		await get_tree().process_frame
	_check(
		warp.finished and warp._report.visible,
		"the arrival report shows after the warp (SPEC Section 20.4)"
	)


## Opens and closes the pause menu, the settings, and How to Play (SPEC Sections 20.7 and 23).
func _check_overlays(main: Control) -> void:
	var pause: Overlay = main.open_overlay(PauseMenu.new())
	await get_tree().process_frame
	_check(get_tree().paused, "the pause menu pauses the game (SPEC Section 20.7)")
	pause.add_child(SettingsPanel.new())
	var help := HowToPlay.new()
	pause.add_child(help)
	await get_tree().process_frame
	for i in 4:
		help._show(i)
	pause.close()
	await get_tree().process_frame
	_check(not get_tree().paused, "Resume ends the pause (SPEC Section 20.7)")


## Picks up a cargo with a click, rotates it with R, and drops it with a click (SPEC Section 8.2).
func _check_pick_up(station: StationScreen, id: int) -> void:
	station._begin_cargo_drag(id, Vector2.ZERO)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	station._input(release)
	_check(
		not station._drag.is_empty() and station._drag["held"],
		"a click picks up a cargo (SPEC Section 8.2)"
	)
	var rot: int = station._drag["rot"]
	var r := InputEventKey.new()
	r.keycode = KEY_R
	r.pressed = true
	station._input(r)
	_check(station._drag["rot"] == (rot + 1) % 4, "R rotates a picked-up cargo (SPEC Section 8.2)")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	station._input(press)
	_check(station._drag.is_empty(), "the next click drops it (SPEC Section 8.2)")
	station._input(release)
	_check(
		not station._ignore_release,
		"the release of the drop click does nothing more (SPEC Section 8.2)"
	)


## Accepts the contracts, packs the freight, uses the tooltip and the marks, and warps.
func _play_station(state: Node, station: StationScreen) -> void:
	var run: Dictionary = state.view()["run"]
	# Take contracts while the mass stays under the limit (SPEC Section 25).
	var mass: int = run["mass"]["hold"]
	for k: Dictionary in run["contracts"]:
		var add := 0
		for f: Dictionary in k["freight"]:
			add += f["mass"]
		if mass + add <= run["mass"]["limit"]:
			state.accept_contract(k["index"])
			mass += add
	await get_tree().process_frame
	run = state.view()["run"]
	for c: Dictionary in run["cargo"]:
		station._show_tip(c)
		if c["in_hold"]:
			continue
		var placed := false
		for y in run["hold"]["rows"]:
			for x in run["hold"]["columns"]:
				if not placed and state.can_place(c["id"], x, y, 0):
					placed = state.place_cargo(c["id"], x, y, 0) == ""
	for i in run["contracts"].size():
		station._set_hover_contract(i)
	station._set_hover_contract(-1)
	station._hide_tip()
	run = state.view()["run"]
	if not run["cargo"].is_empty():
		_check_pick_up(station, run["cargo"][0]["id"])
		var c: Dictionary = run["cargo"][0]
		station._begin_cargo_drag(c["id"], Vector2.ZERO)
		station._rotate_drag()
		station._end_drag()
	station._begin_clamp_drag()
	station._end_drag()
	_check(
		station._hold.columns == run["hold"]["columns"],
		"the hold view has the size of the hold (SPEC Section 5)"
	)
	await get_tree().process_frame
	station._on_warp_pressed()
	if station._confirm.visible:
		station._confirm.hide()
		state.warp()
