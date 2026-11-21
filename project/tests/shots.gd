extends Node
## Takes screenshots of each screen for a UI review: the title, How to Play, the
## station, the settings, the warp, the arrival report, and the station in zh-TW.
## It needs a window: a headless run draws nothing.
## Run: task shots. The images go to shots/ at the repository root (not in git).
## Delete them after the review.

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
## The seed of the run in the screenshots.
const SEED := 7
## The size of the window and the images.
const SIZE := Vector2i(1920, 1080)
## The images of the warp: one each WARP_GAP seconds.
const WARP_SHOTS := 18
const WARP_GAP := 0.33

var _out := ""
var _main: Control


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_out = ProjectSettings.globalize_path("res://").path_join("../shots").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	# Keep the settings of the player: the run writes the hint progress.
	var saved := FileAccess.get_file_as_string(Settings.PATH)
	DirAccess.remove_absolute(Settings.PATH)
	Settings._config = null
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	await _wait(0.5)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(SIZE)
	await _wait(1.0)
	await _shot("01_title")
	# The title ship at the stop, where the cargo flies in, and as it flies out.
	var ship: TitleShip = _main.screen().find_child("TitleShip", true, false)
	ship.time = TitleShip.ENTER_TIME + 1.0
	await _shot("01b_title_dock")
	ship.time = TitleShip.ENTER_TIME + TitleShip.DOCK_TIME + 1.5
	await _shot("01c_title_leave")
	await _how_to_play()
	await _station()
	await _warp()
	GameState.continue_run()
	await _wait(0.8)
	TranslationServer.set_locale("zh_TW")
	await _wait(0.8)
	await _shot("09_station_zh")
	TranslationServer.set_locale("en")
	await _mod_choice()
	await _incidents()
	GameState.abandon_run()
	DirAccess.remove_absolute(Settings.PATH)
	if saved != "":
		var f := FileAccess.open(Settings.PATH, FileAccess.WRITE)
		f.store_string(saved)
		f.close()
	Settings._config = null
	print("shots: wrote %s" % _out)
	await _free_all()
	get_tree().quit()


## Frees the screens and the caches before the quit, so that no resource is in use
## at the exit: the static caches keep their textures until they are cleared.
func _free_all() -> void:
	_main.music().stop()
	_main.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	CargoArt.clear()
	FxSheets.clear()


func _shot(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out.path_join(file_name + ".png"))


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout


func _how_to_play() -> void:
	var help := HowToPlay.new()
	_main.open_overlay(help)
	help._show(1)
	await _wait(0.4)
	await _shot("02_how_to_play")
	help.close()


## The station: the start, the contracts accepted, the hold loaded with a cargo
## in the hand and a tooltip, and the settings over it.
func _station() -> void:
	GameState.new_run(SEED)
	await _wait(0.8)
	await _shot("03_station_start")
	var run: Dictionary = GameState.view()["run"]
	var mass: int = run["mass"]["hold"]
	for k: Dictionary in run["contracts"]:
		var add := 0
		for f: Dictionary in k["freight"]:
			add += f["mass"]
		if mass + add <= run["mass"]["limit"]:
			GameState.accept_contract(k["index"])
			mass += add
	await _wait(0.5)
	await _shot("04_station_accepted")
	# The mouse on a contract card: its details in the tip (SPEC Section 20.2).
	var board: StationScreen = _main.screen()
	if not board._contract_cards.is_empty():
		board._contract_cards[0].mouse_entered.emit()
		await _wait(0.2)
		await _shot("04b_contract_tip")
		board._contract_cards[0].mouse_exited.emit()
	GameState.load_all()
	await _wait(0.5)
	var station: StationScreen = _main.screen()
	run = GameState.view()["run"]
	if not run["dock"].is_empty():
		station._drag.begin_cargo(run["dock"][0], Vector2.ZERO)
		var release := InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT
		station._input(release)
	# The loaded hold with no tip: docs/screenshots/2_station.png of the README.
	await _wait(0.4)
	await _shot("05a_station_hold")
	for c: Dictionary in run["cargo"]:
		if c["in_hold"]:
			station.show_tip(c)
			break
	await _wait(0.4)
	await _shot("05_station_loaded")
	station._drag.end()
	await _drag_blocked(station)
	station.hide_tip()
	var pause: Overlay = _main.open_overlay(PauseMenu.new())
	pause.add_child(SettingsPanel.new())
	await _wait(0.4)
	await _shot("06_settings")
	pause.close()
	await _wait(0.3)


## The warp, image by image, and the arrival report.
## The event with its speaker (SPEC Section 20.8), the mod choice (SPEC Section 20.9),
## and the station with the tag of the mod.
func _mod_choice() -> void:
	var run: Dictionary = GameState.view()["run"]
	if run["phase"] == Defs.PHASE_EVENT:
		await _shot("09_event")
		var panel: EventPanel = _main.choice
		panel.choices[-1].pressed.emit()
		await _wait(0.3)
		await _shot("09b_event_reply")
		panel.close()
		await _wait(0.4)
		# A bust portrait stands at the bottom edge of the box (SPEC Section 20.8).
		GameState.set_up(_set_bust_event)
		await _wait(0.6)
		await _shot("09c_event_bust")
		var bust: EventPanel = _main.choice
		bust.choices[-1].pressed.emit()
		await _wait(0.3)
		bust.close()
	GameState.set_up(StationEvents.offer_mods)
	await _wait(0.6)
	await _shot("10_mod_choice")
	GameState.choose_mod(0)
	await _wait(0.6)
	await _shot("11_station_mod")
	# The route: an environment, an incident, and special contracts (SPEC Sections 28 to 30).
	GameState.set_up(_set_route)
	await _wait(0.6)
	await _shot("12_station_route")
	# The stasis bay above the hold, with a cargo in it (SPEC Section 31.2).
	GameState.set_up(_set_bay)
	await _wait(0.6)
	await _shot("13_station_bay")
	# The payment screen, its Paid stamp, and the run end (SPEC Sections 20.5 and 20.6).
	GameState.set_up(_set_payment)
	await _wait(0.6)
	await _shot("16_payment")
	var panel: PhasePanel = _main.screen()
	panel.pay_button.pressed.emit()
	await _wait(0.9)
	await _shot("16b_paid")
	await _wait(0.5)
	await _shot("16c_paid_mark")
	await _wait(0.8)
	GameState.set_up(_set_last_payment)
	await _wait(0.3)
	GameState.make_payment()
	await _wait(0.6)
	await _shot("17_run_end")
	# The tutorial: a step with no action, and the contract step (SPEC Section 23.4).
	GameState.start_tutorial()
	await _wait(0.6)
	await _shot("14_tutorial_next")
	GameState.tutorial_next()
	await _wait(0.6)
	await _shot("15_tutorial_target")


## Opens the event of the alien: a bust portrait.
func _set_bust_event(r: Run) -> void:
	for e in r.cat.events:
		if e.id == "first_contact":
			r.event = e
	r.phase = Defs.PHASE_EVENT


func _set_route(r: Run) -> void:
	r.environment = Defs.ENV_HEAT_ZONE
	r.incident = {"kind": Defs.INCIDENT_METEOR, "x": 2}
	r.contracts[0] = Contract.new(900, r.cat.contract("vip_embassy"))
	r.contracts[1] = Contract.new(901, r.cat.contract("long_mine"))
	r.contracts[2] = Contract.new(902, r.cat.contract("statue_loan"))
	r.contracts[3] = Contract.new(903, r.cat.contract("smokes"))


func _set_payment(r: Run) -> void:
	r.phase = Defs.PHASE_PAYMENT
	r.credits = 152
	r.history.append(
		{"leg": 1, "jump": 2, "net": 41, "delivered": 5, "scrapped": 0, "explosions": 0}
	)
	r.history.append(
		{"leg": 1, "jump": 3, "net": -6, "delivered": 2, "scrapped": 3, "explosions": 1}
	)


func _set_last_payment(r: Run) -> void:
	r.phase = Defs.PHASE_PAYMENT
	r.leg = 3
	r.credits = 690
	r.history.append(
		{"leg": 2, "jump": 1, "net": 88, "delivered": 6, "scrapped": 1, "explosions": 0}
	)
	r.history.append(
		{"leg": 3, "jump": 1, "net": 120, "delivered": 7, "scrapped": 2, "explosions": 1}
	)


func _set_bay(r: Run) -> void:
	r.credits += 50
	r.bay_size = r.cat.bay_sizes[-1]
	var c := r.new_cargo(r.cat.cargo["sensor_array"])
	r.place_cargo(c.id, Vector2i(1, 0), 0, true)


func _warp() -> void:
	GameState.warp()
	for i in WARP_SHOTS:
		await _wait(WARP_GAP)
		await _shot("07_warp_%02d" % i)
	var warp: WarpScreen = _main.screen()
	while not warp.finished:
		await _wait(0.3)
	await _wait(1.0)
	await _shot("08_report")


## A warp with each kind of incident: the fireball, the wave, and the crack
## (SPEC Section 29.3). A new run has a few cargo in the hold.
func _incidents() -> void:
	GameState.abandon_run()
	GameState.new_run(11)
	await _wait(0.6)
	var kinds := [
		{"kind": Defs.INCIDENT_METEOR, "x": 2},
		{"kind": Defs.INCIDENT_ION_PULSE, "y": 4},
		{"kind": Defs.INCIDENT_HULL_BREACH, "x": 5, "y": 5},
	]
	for i in kinds.size():
		while GameState.view()["run"]["phase"] in [Defs.PHASE_EVENT, Defs.PHASE_MOD]:
			var phase: String = GameState.view()["run"]["phase"]
			if phase == Defs.PHASE_EVENT:
				var e: Dictionary = GameState.view()["run"]["event"]
				GameState.choose_event(e["choices"].size() - 1)
				var panel: EventPanel = _main.choice
				if panel != null:
					panel.close()
			else:
				GameState.choose_mod(0)
			await _wait(0.4)
		var inc: Dictionary = kinds[i]
		GameState.set_up(_set_incident.bind(inc))
		await _wait(0.4)
		GameState.warp()
		for k in 3:
			await _wait(0.35)
			await _shot("18_incident_%s_%d" % [inc["kind"], k])
		var warp: WarpScreen = _main.screen()
		while not warp.finished:
			await _wait(0.3)
		GameState.continue_run()
		await _wait(0.6)


## Puts cargo in the hold for the incident shots, and sets the incident.
func _set_incident(r: Run, inc: Dictionary) -> void:
	var places := {
		"energy_crystal": Vector2i(2, 3),
		"circuit_boards": Vector2i(0, 4),
		"flashlight": Vector2i(4, 4),
		"liquor_bottle": Vector2i(2, 5),
	}
	for id: String in places:
		var c := r.new_cargo(r.cat.cargo[id])
		if r.place_cargo(c.id, places[id], 0, false) != "":
			r.remove_cargo(c.id)
	r.incident = inc


## A cargo of the hold over another one: the red cells, the red frame, and the ghost
## (SPEC Section 8.3).
func _drag_blocked(station: StationScreen) -> void:
	var placed: Array = GameState.view()["run"]["cargo"].filter(
		func(c: Dictionary) -> bool: return c["in_hold"]
	)
	if placed.size() < 2:
		return
	var a: Dictionary = placed[0]
	var b: Dictionary = placed[1]
	var hold := station.hold_view
	var s: Dictionary = a["rotations"][a["rot"]][0]
	var at := Vector2(a["x"] + s["x"], a["y"] + s["y"]) + Vector2(0.5, 0.5)
	station._drag.begin_cargo(b["id"], UiCheckDrag._grab(station, b["id"]))
	station._drag.update(hold.global_position + hold.grid_origin() + at * hold.cell)
	await _wait(0.3)
	await _shot("05b_drag_blocked")
	station._drag.end()
