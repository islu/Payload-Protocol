extends Node
## Plays a full run through the screens of the main scene, headless. It fails
## on a SCRIPT ERROR (Taskfile) or a failed check. It is a scene, so that the
## autoloads exist as in the game.
## Run: godot --headless --path project res://tests/ui_check.tscn

const MAIN_SCENE := preload("res://scenes/main/main.tscn")

## The number of mods that the run selected. The UI check of SPEC Section 20.9 needs one.
var mods_seen := 0
var _failures := 0
var _language_checked := false
var _undo_checked := false
var _shop_checked := false
var _contracts_checked := false
var _snap_checked := false
## The number of warps with a loss or a chain. The checks of SPEC Section 21.5 need one.
var _losses_seen := 0
## The number of stations with an environment or an incident.
var _route_seen := 0


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
	_check_cargo_art()
	for face in PilotFace.SHEETS:
		_check(
			not FxSheets.sheet(face).is_empty(),
			"the portrait %s has a sheet (SPEC Section 22)" % face
		)
	for fx in FxLayer.NAMES:
		var sheet := FxSheets.sheet(fx)
		_check(
			not sheet.is_empty() and sheet["frames"] > 0 and sheet["texture"] != null,
			"the effect %s has a sprite sheet (SPEC Sections 4.2 and 21)" % fx
		)
		_check(
			not sheet.is_empty() and is_equal_approx(sheet["scale"], 3.0),
			"the effect %s plays at 3 times its pixel size (SPEC Section 4.2)" % fx
		)
	# Play in each language, so that a translation with a bad placeholder fails here.
	for locale in Settings.LOCALES:
		TranslationServer.set_locale(locale)
		var main: Control = MAIN_SCENE.instantiate()
		add_child(main)
		# Main applies the saved language. Use the language of this pass.
		TranslationServer.set_locale(locale)
		await get_tree().process_frame
		var music: AudioStreamPlayer = main.music()
		_check(
			music.stream != null and music.stream.loop and music.bus == &"Music",
			"one music loop plays on the Music bus (SPEC Section 4.3)"
		)
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
	# The title, the tagline, and the buttons are in the center (SPEC Section 20.1).
	var mid := new_run.get_global_rect().get_center()
	var view := get_viewport().get_visible_rect().size
	_check(
		absf(mid.x - view.x / 2.0) < 2.0,
		"the menu is in the center: %s of %s (SPEC Section 20.1)" % [mid, view]
	)
	_check(
		main.screen().find_child("TitleHold", true, false) == null,
		"the title has no moving hold (SPEC Section 20.1)"
	)
	var tagline: Label = main.screen().find_child("Tagline", true, false)
	_check(tagline != null and tagline.text != "", "the title has a tagline (SPEC Section 20.1)")
	var version: Label = main.screen().find_child("Version", true, false)
	var screen := get_viewport().get_visible_rect().size
	_check(
		(
			version != null
			and version.text.begins_with("v")
			and version.get_global_rect().get_center().x > screen.x * 0.8
			and version.get_global_rect().get_center().y > screen.y * 0.8
		),
		"the version is at the bottom right (SPEC Section 20.1)"
	)
	state.new_run(11)
	await get_tree().process_frame
	await UiCheckLoop.gear(self, main)
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
				_route_seen += UiCheckLoop.route_station(self, station)
				await _play_station(state, station)
			Defs.PHASE_ARRIVAL:
				await _play_warp(main)
				state.continue_run()
			Defs.PHASE_PAYMENT:
				state.make_payment()
			Defs.PHASE_EVENT, Defs.PHASE_MOD:
				await UiCheckLoop.choose(self, main)
		await get_tree().process_frame
	_check(
		state.view()["run"]["phase"] == Defs.PHASE_END,
		"the run reaches its end (SPEC Section 19.2)"
	)
	_check(_route_seen > 0, "the run has a leg with an environment, for SPEC Sections 28 and 29")
	_check(mods_seen > 0, "the run has a mod choice, for the checks of SPEC Section 20.9")
	_check(_losses_seen > 0, "the run has a warp with a loss, for the checks of SPEC Section 21.5")
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
	_check(station._pilot_label.visible_ratio < 1.0, "a new line types out (SPEC Section 22)")
	_check(
		not (
			station
			. find_children("*", "", true, false)
			. filter(func(n: Node) -> bool: return n is PilotFace)
			. is_empty()
		),
		"the pilot box shows the portrait (SPEC Section 22)"
	)
	await get_tree().create_timer(3.0).timeout
	_check(
		is_equal_approx(station._pilot_label.visible_ratio, 1.0),
		"the line ends typed out (SPEC Section 22)"
	)
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
		text.call().begins_with("MAGELLAN: "),
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
	_check(main.gear.is_visible_in_tree(), "the warp has the gear button (SPEC Section 20.7)")
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
	var hits := 0
	for step: Dictionary in GameState.view()["run"]["warp"]["steps"]:
		hits += step["hits"].size()
	_check(
		hits == 0 or warp._fx.played.has("hit"), "a hit plays the spark sheet (SPEC Section 21.2)"
	)
	UiCheckLoop.route_warp(self, warp)
	if UiCheckLoop.losses(self, warp):
		_losses_seen += 1
	_check_report(warp)
	await get_tree().process_frame
	if GameState.view()["run"]["arrival"]["total"] != 0:
		var report := warp._report.get_global_rect()
		var inside := false
		for fx: Dictionary in warp._top_fx._fx:
			if fx["kind"] == "sheet" and fx["sheet"] == FxSheets.sheet("coin"):
				inside = report.has_point(warp._top_fx.get_global_transform() * fx["at"])
		_check(
			inside and warp._top_fx.get_index() > warp._report.get_index(),
			"the gold sparkle is on the arrival report, in front of it (SPEC Section 21.4)"
		)
	# The hold moves in 0.4 seconds.
	await get_tree().create_timer(0.7).timeout
	# The fade of delivered freight ends at half alpha, not at 0.
	for k: Dictionary in GameState.view()["run"]["arrival"]["contracts"]:
		for p: Dictionary in k["pieces"]:
			if p["state"] == Defs.PIECE_DELIVERED:
				_check(
					warp._hold.fades.get(p["id"], 1.0) > 0.2,
					"delivered freight stays in the hold at half alpha (SPEC Section 20.4)"
				)
	var hold := warp._hold
	var grid_right := hold.global_position.x + hold.grid_origin().x + hold.columns * hold.cell
	_check(
		grid_right <= warp._report.global_position.x,
		"the report does not cover the hold (SPEC Section 20.4)"
	)
	await _check_report_marks(warp)
	await _check_replay(warp)


## The mouse on a line of pieces marks those pieces in the hold (SPEC Section 20.4).
func _check_report_marks(warp: WarpScreen) -> void:
	if warp._report.items.is_empty():
		return
	var item: Dictionary = warp._report.items[0]
	var control: Control = item["control"]
	control.mouse_entered.emit()
	_check(
		warp._hold.marked == item["ids"],
		"the mouse on a group marks its pieces in the hold: %s (SPEC Section 20.4)" % [item["ids"]]
	)
	control.mouse_exited.emit()
	_check(warp._hold.marked.is_empty(), "the marks go when the mouse leaves the group")


## The cards, the ledger, the credits, the pilot, and the delivered freight (SPEC Section 20.4).
func _check_report(warp: WarpScreen) -> void:
	var a: Dictionary = GameState.view()["run"]["arrival"]
	var report := warp._report
	var groups := 0
	for k: Dictionary in a["contracts"]:
		groups += k["groups"].size()
	_check(
		report._cards.get_child_count() == a["contracts"].size(),
		"the report shows a card for each contract (SPEC Section 20.4)"
	)
	_check(
		report.items.size() == groups,
		"each group of the same freight and state shows one time (SPEC Section 20.4)"
	)
	var ledger: Dictionary = a["ledger"]
	for key: String in ["deliveries", "bonuses", "sold", "net"]:
		_check(
			ReportPanel.amount(ledger[key]) in report.ledger_text,
			"the ledger shows %s: %d (SPEC Section 20.4)" % [key, ledger[key]]
		)
	for key: String in ["breaches", "fuel_fee"]:
		_check(
			ReportPanel.amount(-ledger[key]) in report.ledger_text,
			"the ledger shows %s as a cost (SPEC Section 20.4)" % key
		)
	_check(
		(
			str(a["credits_before"]) in report._credits.text
			and str(a["credits_after"]) in report._credits.text
		),
		"the report shows the credits before and after (SPEC Section 20.4)"
	)
	_check(
		report.pilot_face != null and report.pilot_face.is_visible_in_tree(),
		"the pilot speaks with the portrait (SPEC Section 20.4)"
	)
	for k: Dictionary in a["contracts"]:
		for p: Dictionary in k["pieces"]:
			if p["state"] != Defs.PIECE_DELIVERED:
				continue
			_check(
				warp._hold.checks.has(p["id"]),
				"delivered freight has a check mark (SPEC Section 20.4)"
			)


## The Replay button plays the warp again at half speed (SPEC Section 20.4).
func _check_replay(warp: WarpScreen) -> void:
	_check(
		warp._report.replay != null and warp._report.replay.visible,
		"the arrival report has a Replay button (SPEC Section 20.4)"
	)
	if warp._report.replay == null:
		return
	warp._report.replay.pressed.emit()
	await get_tree().process_frame
	_check(
		not warp.finished and not warp._report.visible,
		"Replay hides the report and plays the warp again (SPEC Section 20.4)"
	)
	_check(
		is_equal_approx(warp.speed, float(Settings.get_value("warp_speed")) * 0.5),
		"the replay plays at half speed (SPEC Section 20.4)"
	)
	warp.speed_up()
	warp.speed = 200.0
	var frames := 0
	while not warp.finished and frames < 2000:
		frames += 1
		await get_tree().process_frame
	_check(
		warp.finished and warp._report.visible,
		"the report shows after the replay (SPEC Section 20.4)"
	)


## Opens and closes the pause menu, the settings, and How to Play (SPEC Sections 20.7 and 23).
func _check_overlays(main: Control) -> void:
	var pause: Overlay = main.open_overlay(PauseMenu.new())
	await get_tree().process_frame
	_check(get_tree().paused, "the pause menu pauses the game (SPEC Section 20.7)")
	pause.add_child(SettingsPanel.new())
	var help := HowToPlay.new()
	pause.add_child(help)
	for page in HowToPlay.PAGES:
		var points := Array(tr(page).split("\n")).filter(
			func(line: String) -> bool: return line.begins_with("•")
		)
		_check(points.size() == 3, "a page of How to Play has 3 points (SPEC Section 23.2)")
	await get_tree().process_frame
	for i in 4:
		help._show(i)
	for page: Array in TutorialPicture.PAGE_CARGO:
		for id: String in page:
			_check(
				CargoArt.texture(id) != null,
				"a How to Play picture shows the image of %s (SPEC Section 23.2)" % id
			)
	pause.close()
	await get_tree().process_frame
	_check(not get_tree().paused, "Resume ends the pause (SPEC Section 20.7)")


## Returns the number of cards of the hazard panel: the environment, the incident,
## and each step (SPEC Sections 20.2, 28.1, and 29.3).
static func _route_cards(run: Dictionary) -> int:
	var n: int = run["hazard"].size()
	n += 0 if run["environment"].is_empty() else 1
	return n + (0 if run["incident"].is_empty() else 1)


## The hold fills the center, and the hazard panel is above it (SPEC Section 20.2).
## The text has four sizes (SPEC Section 4.2).
func _check_layout(station: StationScreen) -> void:
	var sizes := [24, 18, 15, 20]
	var wrong := PackedStringArray()
	for n in station.find_children("*", "", true, false):
		# Display text: the Warp button and the arrows of the hazard cards.
		if n == station._warp_button or station._hazard_box.is_ancestor_of(n):
			continue
		var font_size := -1
		if n is Label or n is Button:
			font_size = n.get_theme_font_size("font_size")
		elif n is RichTextLabel:
			font_size = n.get_theme_font_size("normal_font_size")
		if font_size != -1 and not font_size in sizes:
			wrong.append("%s %d %s" % [n.get_class(), font_size, station.get_path_to(n)])
	_check(wrong.is_empty(), "the station text has the four sizes: %s (SPEC Section 4.2)" % [wrong])
	var hold := station._hold
	_check(hold.cell == 100.0, "each cell is 100 pixels: %s px (SPEC Section 20.2)" % hold.cell)
	var grid := Rect2(hold.grid_origin(), Vector2(hold.columns, hold.rows) * hold.cell)
	_check(
		Rect2(Vector2.ZERO, hold.size).encloses(grid),
		"the grid fits in the hold (SPEC Section 20.2)"
	)
	var panel := station._hazard_box.get_global_rect()
	var top := hold.global_position.y + grid.position.y
	_check(
		station._hazard_box.get_child_count() == _route_cards(GameState.view()["run"]),
		"the hazard panel has one card for each step (SPEC Sections 20.2 and 29.3)"
	)
	var left := hold.global_position.x + grid.position.x
	var cards := station._hazard_box.get_children()
	_check(
		(
			panel.end.x <= left
			and panel.position.y >= top
			and panel.end.y <= top + grid.size.y
			and (cards.size() < 2 or cards[1].global_position.y > cards[0].global_position.y)
		),
		(
			"the hazard panel is at the left of the hold: %s, grid %s (SPEC Section 20.2)"
			% [panel, Rect2(Vector2(left, top), grid.size)]
		)
	)
	# The mouse on a cargo shows a bright frame on its cells (SPEC Section 4.2).
	var run: Dictionary = GameState.view()["run"]
	for c: Dictionary in run["cargo"]:
		if c["in_hold"]:
			hold.set_hover(c["id"])
			_check(
				hold.frame_cells().size() == c["shape"].size(),
				"the mouse on a cargo frames its cells (SPEC Section 4.2)"
			)
			hold.set_hover(-1)
			_check(hold.frame_cells().is_empty(), "no frame when the mouse leaves the cargo")
			break


## Changes the language in the settings of the pause menu, and checks that the
## open menus and the station change at once (SPEC Section 23.1).
func _check_language(station: StationScreen) -> void:
	var main: Control = station.get_parent()
	var start := TranslationServer.get_locale()
	var other: String = Settings.LOCALES[1 - Settings.LOCALES.find(start)]
	var pause: Overlay = main.open_overlay(PauseMenu.new())
	var panel := SettingsPanel.new()
	pause.add_child(panel)
	await get_tree().process_frame
	var options: OptionButton = panel.find_children("*", "OptionButton", true, false)[0]
	var toggle: CheckButton = panel.find_children("*", "CheckButton", true, false)[0]
	_check(
		toggle.get_theme_icon("unchecked").resource_path.ends_with("toggle_off.svg"),
		"a switch that is off shows an outlined capsule (SPEC Section 23.1)"
	)
	var slider: HSlider = panel.find_children("*", "HSlider", true, false)[0]
	var heading: Label = panel.box.get_child(0)
	slider.value = slider.value - 5
	await get_tree().process_frame
	_check(
		is_instance_valid(heading) and heading.is_inside_tree(),
		"a volume change does not build the settings again (SPEC Section 23.1)"
	)
	options.item_selected.emit(Settings.LOCALES.find(other))
	await get_tree().process_frame
	await get_tree().process_frame
	# The locale is the new language now, so tr() gives the text that must show.
	var want := func(text: String) -> String: return tr(text)
	var texts := func(node: Node) -> PackedStringArray:
		var out := PackedStringArray()
		for n in node.find_children("*", "", true, false):
			if n is Label or n is Button:
				out.append(n.text)
		return out
	_check(
		texts.call(panel).has(want.call(SettingsPanel.SETTINGS_TEXT)),
		"the open settings show the new language (SPEC Section 23.1)"
	)
	_check(
		texts.call(pause).has(want.call(PauseMenu.RESUME_TEXT)),
		"the pause menu shows the new language (SPEC Section 23.1)"
	)
	_check(
		texts.call(main.screen()).has(want.call(StationScreen.WARP_TEXT)),
		"the station shows the new language (SPEC Section 23.1)"
	)
	Settings.set_value("locale", start)
	pause.close()
	await get_tree().process_frame
	await get_tree().process_frame


## Places a cargo from the dock by clicks, and checks that the next dock cargo is
## picked up at once (SPEC Section 8.2).
func _check_chain(station: StationScreen) -> void:
	var run: Dictionary = GameState.view()["run"]
	if run["dock"].size() < 2:
		return
	var first: int = run["dock"][0]
	station._begin_cargo_drag(first, Vector2.ZERO)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	station._input(release)
	var hold := station._hold
	for y in run["hold"]["rows"]:
		for x in run["hold"]["columns"]:
			if not station._drag.get("id", -1) == first:
				continue
			if GameState.can_place(first, x, y, station._drag["rot"]):
				var at := (
					hold.global_position
					+ hold.grid_origin()
					+ (Vector2(x, y) + Vector2(0.7, 0.7)) * hold.cell
				)
				station._drop_at(at)
	var placed: Array = GameState.view()["run"]["cargo"].filter(
		func(c: Dictionary) -> bool: return c["id"] == first
	)
	_check(placed[0]["in_hold"], "a click drops the cargo in the hold (SPEC Section 8.2)")
	_check(
		(
			not station._drag.is_empty()
			and station._drag["held"]
			and station._drag["id"] == run["dock"][1]
		),
		"the next dock cargo is picked up (SPEC Section 8.2)"
	)
	station._end_drag()


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
	_check(
		station._undo_button.disabled,
		"a new station has nothing to undo: the Undo button is off (SPEC Section 20.2)"
	)
	_check_hazard_hover(station)
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
	if not _undo_checked:
		_undo_checked = true
		await _check_undo(state, station)
	_check_layout(station)
	if not _snap_checked:
		_snap_checked = true
		_check_snap(station)
	if not _contracts_checked:
		_contracts_checked = true
		await _check_contracts(station)
	if not _shop_checked:
		_shop_checked = true
		_check_shop(station)
	if not _language_checked:
		_language_checked = true
		var main: Control = station.get_parent()
		await _check_language(station)
		# A new language builds the station again (SPEC Section 23.1).
		station = main.screen()
	_check_chain(station)
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
	station._act("", "coin")
	_check(station._fx.played.has("coin"), "a coin sound shows a gold sparkle (SPEC Section 21.4)")
	_check(
		station._hold.columns == run["hold"]["columns"],
		"the hold view has the size of the hold (SPEC Section 5)"
	)
	await get_tree().process_frame
	station._on_warp_pressed()
	if station._confirm.visible:
		station._confirm.hide()
		state.warp()


## Ctrl+Z takes back the last action at the station (SPEC Section 20.2).
func _check_undo(state: Node, station: StationScreen) -> void:
	var accepted := func() -> Array:
		var out := []
		for k: Dictionary in state.view()["run"]["contracts"]:
			if k["accepted"]:
				out.append(k["index"])
		return out
	var before: Array = accepted.call()
	if before.is_empty():
		return
	_check(not station._undo_button.disabled, "after an action, Undo is on (SPEC Section 20.2)")
	var key := InputEventKey.new()
	key.keycode = KEY_Z
	key.command_or_control_autoremap = true
	key.pressed = true
	station._input(key)
	await get_tree().process_frame
	var after: Array = accepted.call()
	_check(
		after.size() == before.size() - 1,
		"Ctrl+Z takes back the last contract: %s, then %s (SPEC Section 20.2)" % [before, after]
	)
	for i: int in before:
		if not i in after:
			state.accept_contract(i)
	await get_tree().process_frame


## The mouse on a hazard card marks the front wall of that step (SPEC Section 20.2).
func _check_hazard_hover(station: StationScreen) -> void:
	var run: Dictionary = GameState.view()["run"]
	var hazard: Array = run["hazard"]
	for i in hazard.size():
		var step: Dictionary = hazard[i]
		var want := PackedStringArray(
			step["directions"] if step["known"] == "" else [step["known"]]
		)
		station._set_hover_step(i)
		_check(
			station._hold.front_walls == want,
			(
				"the mouse on hazard card %d marks its front wall: %s, want %s (SPEC Section 20.2)"
				% [i + 1, station._hold.front_walls, want]
			)
		)
		_check(
			station._hold.show_jolts == (i == 0),
			"the wall jolt warnings are for the first step only (SPEC Section 20.2)"
		)
	station._set_hover_step(-1)
	_check(
		station._hold.front_walls == PackedStringArray([run["front_wall"]]),
		"the hold marks the first step again when the mouse leaves (SPEC Section 12.3)"
	)
	var seen := StationScreen.step_card(
		{"directions": [Defs.DIR_LEFT, Defs.DIR_UP], "fork": true, "known": Defs.DIR_UP},
		GameState.view()
	)
	var unknown := StationScreen.step_card(
		{"directions": [Defs.DIR_LEFT, Defs.DIR_UP], "fork": true, "known": ""}, GameState.view()
	)
	_check(
		(
			seen["sensor"]
			and not unknown["sensor"]
			and seen["arrow"] == StationScreen.ARROWS[Defs.DIR_UP]
		),
		"a fork step that a Sensor shows has a Sensor icon and one direction (SPEC Section 20.2)"
	)


## Each cargo has an image and a scrap image, and the image stays upright when the
## cells allow it (SPEC Section 4.2).
func _check_cargo_art() -> void:
	var missing := PackedStringArray()
	for id: String in GameState.catalog.cargo:
		if CargoArt.texture(id) == null or CargoArt.texture(id, true) == null:
			missing.append(id)
	_check(
		missing.is_empty(),
		"each cargo has an image and a scrap image: %s (SPEC Section 4.2)" % [missing]
	)
	var turned := func(id: String, rot: int) -> int:
		var base: Array[Vector2i] = GameState.catalog.cargo[id].shape
		return CargoArt.turns(id, Shapes.to_view(Shapes.rotate(base, rot)))
	_check(
		[turned.call("fuel_drum", 1), turned.call("fuel_drum", 3)] == [0, 0],
		"a cargo of 1 cell does not turn its image (SPEC Section 4.2)"
	)
	_check(
		[turned.call("specimen_tube", 1), turned.call("specimen_tube", 2)] == [1, 0],
		"a line turns its image by 0 or 90 degrees only (SPEC Section 4.2)"
	)
	_check(
		[turned.call("coolant_pipe", 2), turned.call("frozen_octopus", 3)] == [2, 3],
		"an L or a T turns its image with the cargo (SPEC Section 4.2)"
	)


## The shop: the kit cards, the services, and the sell area (SPEC Section 20.2).
func _check_shop(station: StationScreen) -> void:
	var run: Dictionary = GameState.view()["run"]
	var shop: Dictionary = run["shop"]
	var terms := {}
	for t: Dictionary in GameState.view()["terms"]:
		terms[t["id"]] = t
	_check(
		station._shop.offer_cards.size() == shop["offers"].size(),
		"the shop shows a card for each kit offer (SPEC Section 20.2)"
	)
	for i in mini(station._shop.offer_cards.size(), shop["offers"].size()):
		var o: Dictionary = shop["offers"][i]
		var card: Dictionary = station._shop.offer_cards[i]
		for t: String in o["traits"]:
			_check(
				GameText.format(terms[t]["rule"]) in card["text"],
				"a kit card shows the rule of its trait %s (SPEC Section 20.2)" % t
			)
		_check(
			str(o["price"]) in card["buy"].text,
			"a kit card shows its price on the Buy button (SPEC Section 20.2)"
		)
		if not o["helps"].is_empty():
			_check(
				GameText.format(o["helps"]) in card["text"],
				"a kit card shows how it helps the freight (SPEC Section 20.2)"
			)
	# A price that is more than the credits shows in red.
	var credits: int = station._run["credits"]
	station._run["credits"] = 0
	station._shop.refresh()
	if not station._shop.offer_cards.is_empty():
		var buy: Button = station._shop.offer_cards[0]["buy"]
		_check(
			buy.get_theme_color("font_color") == Palette.BAD,
			"a price that is more than the credits shows in red (SPEC Section 20.2)"
		)
	station._run["credits"] = credits
	station._shop.refresh()
	if not station._shop.offer_cards.is_empty():
		var buy: Button = station._shop.offer_cards[0]["buy"]
		_check(
			(
				shop["offers"][0]["price"] > credits
				or buy.get_theme_color("font_color") != Palette.BAD
			),
			"a price that the player can pay is not red (SPEC Section 20.2)"
		)
	var texts: Dictionary = station._shop.service_texts
	_check(
		(
			"%d/" % shop["clamps"] in texts.get("clamp", "")
			and "→ %d/" % mini(shop["clamps_after"], shop["clamp_max"]) in texts.get("clamp", "")
		),
		"the clamp service shows the clamps now and after (SPEC Section 20.2)"
	)
	_check(
		"%d → %d" % [shop["mass_limit"], shop["mass_limit_after"]] in texts.get("hull", ""),
		"Reinforce hull shows the mass limit now and after (SPEC Section 20.2)"
	)
	_check(
		"%d×%d" % [shop["hold"]["columns"], shop["hold"]["rows"]] in texts.get("hold", ""),
		"the hold service shows the hold now (SPEC Section 20.2)"
	)
	# The sell area is a small bar. A drag colors it.
	_check(
		station._sell_area.size.y <= StationScreen.SELL_HEIGHT + 4.0,
		"the sell area is a small bar: %d (SPEC Section 20.2)" % station._sell_area.size.y
	)
	_check(station._sell_mode == "idle", "the sell area is idle with no drag (SPEC Section 20.2)")
	station._show_sell({"kind": Defs.KIND_KIT, "name": "Cooler Unit", "sell_price": 4})
	_check(
		station._sell_mode == "sell" and "4" in station._sell_label.text,
		"a drag of a kit shows the sell price (SPEC Section 20.2)"
	)
	_check(
		station._sell_area.get_theme_stylebox("panel").border_color == Palette.GOOD,
		"a drag of a kit makes the sell area green (SPEC Section 20.2)"
	)
	station._show_sell({"kind": Defs.KIND_SCRAP, "clear_price": 6})
	_check(
		station._sell_mode == "clear" and "6" in station._sell_label.text,
		"a drag of a scrap shows the clear price (SPEC Section 20.2)"
	)
	_check(
		station._sell_area.get_theme_stylebox("panel").border_color == Palette.BAD,
		"a drag of a scrap makes the sell area red (SPEC Section 20.2)"
	)
	if not run["cargo"].is_empty():
		station._begin_cargo_drag(run["cargo"][0]["id"], Vector2.ZERO)
		_check(station._sell_mode != "idle", "a drag changes the sell area (SPEC Section 20.2)")
		station._end_drag()
	_check(
		station._sell_mode == "idle",
		"the end of a drag makes the sell area idle (SPEC Section 20.2)"
	)


## The contract cards and the dock (SPEC Section 20.2).
func _check_contracts(station: StationScreen) -> void:
	var run: Dictionary = GameState.view()["run"]
	_check(
		station._contract_cards.size() == run["contracts"].size(),
		"the board shows a card for each contract (SPEC Section 20.2)"
	)
	var seen_open := false
	var seen_accepted := false
	for i in mini(station._contract_cards.size(), run["contracts"].size()):
		var k: Dictionary = run["contracts"][i]
		var card: ContractCard = station._contract_cards[i]
		for g: Dictionary in k["groups"]:
			_check(
				"×%d" % g["count"] in card.text,
				"a card shows each freight one time with ×N (SPEC Section 20.2)"
			)
		_check(
			str(k["total_pay"]) in card.text and str(k["pieces"]) in card.text,
			"a card shows the pieces and the total pay (SPEC Section 20.2)"
		)
		var border: Color = card.get_theme_stylebox("panel").border_color
		if k["accepted"]:
			seen_accepted = true
			_check(
				border == Palette.ACCENT, "an accepted card has a bright border (SPEC Section 20.2)"
			)
			_check(
				"%d/%d" % [k["loaded"], k["pieces"]] in card.text,
				"an accepted card shows Loaded N/M (SPEC Section 20.2)"
			)
		else:
			seen_open = true
			_check(
				border != Palette.ACCENT,
				"a card that is not accepted has no bright border (SPEC Section 20.2)"
			)
			_check(
				str(k["mass_after"]) in card.text,
				"a card shows the mass after it is accepted (SPEC Section 20.2)"
			)
			var colors := {"ok": Palette.TEXT_DIM, "fee": Palette.WARN, "over": Palette.BAD}
			var want: Color = colors[k["mass_state"]]
			_check(
				card.mass_color == want,
				"the mass after is yellow above the limit and red above the maximum (SPEC Section 20.2)"
			)
	_check(seen_open and seen_accepted, "the check sees an open card and an accepted card")
	_check(
		str(run["dock"].size()) in station._dock_title.text,
		"the dock title shows the number of cargo on the dock (SPEC Section 20.2)"
	)
	var chips := station._dock_flow.get_children().filter(
		func(n: Node) -> bool: return n is CargoChip
	)
	_check(
		chips.size() == run["dock"].size(),
		"the dock shows each cargo on the dock (SPEC Section 20.2)"
	)
	if not chips.is_empty():
		_check(
			is_equal_approx(chips[0].cell, StationScreen.DOCK_CELL),
			"the dock shows its cargo at 48 pixels for each cell (SPEC Section 20.2)"
		)
	# An empty dock is one line of text.
	var saved: Array = station._run["dock"]
	station._run["dock"] = []
	var cargo: Array = station._run["cargo"]
	station._run["cargo"] = cargo.filter(func(c: Dictionary) -> bool: return c["in_hold"])
	station._refresh_dock()
	await get_tree().process_frame
	_check(
		station._dock_panel.size.y < 70.0,
		"an empty dock is one line: %d (SPEC Section 20.2)" % station._dock_panel.size.y
	)
	station._run["dock"] = saved
	station._run["cargo"] = cargo
	station._refresh_dock()


## The shape snaps to the cells under the cursor: the cell under the mouse is the
## grab cell, from the dock too, and after a rotation (SPEC Section 8.3).
func _check_snap(station: StationScreen) -> void:
	var hold := station._hold
	var base := hold.global_position + hold.grid_origin()
	for at: Vector2 in [Vector2(3.5, 2.5), Vector2(3.1, 2.1), Vector2(3.9, 2.9)]:
		var origin := hold.snap_origin(base + at * hold.cell, Vector2(1, 0))
		_check(
			origin == Vector2i(2, 2),
			(
				"the grab cell goes to the cell under the mouse at %s: %s (SPEC Section 8.3)"
				% [at, origin]
			)
		)
	var line := [{"x": 0, "y": 0}, {"x": 1, "y": 0}, {"x": 2, "y": 0}]
	_check(
		HoldView.rotate_grab(line, Vector2(2, 0)) == Vector2(0, 2),
		"a rotation keeps the grab cell under the mouse: a line (SPEC Section 8.2)"
	)
	var ell := [{"x": 0, "y": 0}, {"x": 0, "y": 1}, {"x": 1, "y": 1}]
	_check(
		HoldView.rotate_grab(ell, Vector2(1, 1)) == Vector2(0, 1),
		"a rotation keeps the grab cell under the mouse: an L (SPEC Section 8.2)"
	)
	var chip := CargoChip.new().setup({"shape": ell}, 48.0)
	_check(
		chip.cell_at(Vector2(2, 2) + Vector2(1.5, 1.5) * 48.0) == Vector2i(1, 1),
		"a press on a dock cargo grabs the cell under the press (SPEC Section 8.3)"
	)
	_check(
		chip.cell_at(Vector2(2, 2) + Vector2(1.5, 0.5) * 48.0) in [Vector2i(0, 0), Vector2i(1, 1)],
		"a press on an empty cell of the box grabs the nearest cell of the shape (SPEC Section 8.3)"
	)
	chip.free()
	# The R key during a drag keeps the grab cell under the mouse.
	var run: Dictionary = GameState.view()["run"]
	for c: Dictionary in run["cargo"]:
		var shape: Array = c["rotations"][c["rot"]]
		if shape.size() < 2:
			continue
		var grab := Vector2(shape[-1]["x"], shape[-1]["y"])
		station._begin_cargo_drag(c["id"], grab)
		station._rotate_drag()
		_check(
			station._drag["grab"] == HoldView.rotate_grab(shape, grab),
			"R keeps the grab cell under the mouse (SPEC Section 8.2)"
		)
		station._end_drag()
		break
