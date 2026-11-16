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
	GameState.abandon_run()
	DirAccess.remove_absolute(Settings.PATH)
	if saved != "":
		var f := FileAccess.open(Settings.PATH, FileAccess.WRITE)
		f.store_string(saved)
		f.close()
	Settings._config = null
	print("shots: wrote %s" % _out)
	get_tree().quit()


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
	GameState.load_all()
	await _wait(0.5)
	var station: StationScreen = _main.screen()
	run = GameState.view()["run"]
	if not run["dock"].is_empty():
		station._drag.begin_cargo(run["dock"][0], Vector2.ZERO)
		var release := InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT
		station._input(release)
	for c: Dictionary in run["cargo"]:
		if c["in_hold"]:
			station._show_tip(c)
			break
	await _wait(0.4)
	await _shot("05_station_loaded")
	station._drag.end()
	await _drag_blocked(station)
	station._hide_tip()
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
		GameState.choose_event(run["event"]["choices"].size() - 1)
	StationEvents.offer_mods(GameState._record.run)
	GameState.state_changed.emit()
	await _wait(0.6)
	await _shot("10_mod_choice")
	GameState.choose_mod(0)
	await _wait(0.6)
	await _shot("11_station_mod")
	# The route: an environment, an incident, and special contracts (SPEC Sections 28 to 30).
	var r: Run = GameState._record.run
	r.environment = Defs.ENV_HEAT_ZONE
	r.incident = {"kind": Defs.INCIDENT_METEOR, "x": 2}
	r.contracts[0] = Contract.new(900, r.cat.contract("vip_embassy"))
	r.contracts[1] = Contract.new(901, r.cat.contract("long_mine"))
	r.contracts[2] = Contract.new(902, r.cat.contract("statue_loan"))
	GameState.state_changed.emit()
	await _wait(0.6)
	await _shot("12_station_route")
	# The shock bay above the hold, with a cargo in it (SPEC Section 31.2).
	r.credits += 50
	r.bay_size = r.cat.bay_sizes[-1]
	var c := r.new_cargo(r.cat.cargo["energy_crystal"])
	r.place_cargo(c.id, Vector2i(1, 0), 0, true)
	GameState.state_changed.emit()
	await _wait(0.6)
	await _shot("13_station_bay")


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
	var hold := station._hold
	var s: Dictionary = a["rotations"][a["rot"]][0]
	var at := Vector2(a["x"] + s["x"], a["y"] + s["y"]) + Vector2(0.5, 0.5)
	station._drag.begin_cargo(b["id"], UiCheckDrag._grab(station, b["id"]))
	station._drag.update(hold.global_position + hold.grid_origin() + at * hold.cell)
	await _wait(0.3)
	await _shot("05b_drag_blocked")
	station._drag.end()
