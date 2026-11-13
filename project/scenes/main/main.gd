extends Control
## The main scene. It shows the screen of the phase of the run (SPEC Section 20):
## the title, the station, the warp with the arrival report, and PhasePanel for
## the toll gate and the run end. Esc opens the pause menu (SPEC Section 20.7).

const TITLE_TEXT := "PAYLOAD PROTOCOL"
const NEW_RUN_TEXT := "New Run"
const HOW_TO_PLAY_TEXT := "How to Play"
const SETTINGS_TEXT := "Settings"
const QUIT_TEXT := "Quit"
## The music loop (SPEC Section 4.3). docs/assets.md has its source.
const MUSIC_PATH := "res://audio/music/vintage_menu.ogg"

var _screen: Control
var _screen_kind := ""
var _overlays: CanvasLayer
var _crt: ColorRect
var _music: AudioStreamPlayer
## The language of the text on the screen.
var _locale := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_locale = TranslationServer.get_locale()
	_overlays = CanvasLayer.new()
	_overlays.layer = 10
	add_child(_overlays)
	_add_crt()
	_add_music()
	GameState.state_changed.connect(_update)
	_update()
	# Change the window last. On macOS, a change of the window mode runs frames
	# (and _process) before it returns, so each node must exist first.
	Settings.apply()
	_fit_window_to_screen()


func _update() -> void:
	var run: Dictionary = GameState.view()["run"]
	var kind := "title" if run.is_empty() else str(run["phase"])
	if kind == Defs.PHASE_END and run["end"]["won"]:
		Hints.run_won()
	if kind == Defs.PHASE_TOLL or kind == Defs.PHASE_END:
		kind = "gate"
	if kind == _screen_kind:
		return
	_screen_kind = kind
	if _screen != null:
		_screen.queue_free()
	match kind:
		"title":
			_screen = _title()
		Defs.PHASE_STATION:
			_screen = StationScreen.new()
		Defs.PHASE_ARRIVAL:
			_screen = WarpScreen.new()
		_:
			_screen = PhasePanel.new()
	_screen.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_screen)
	move_child(_screen, 0)


func _notification(what: int) -> void:
	if what != NOTIFICATION_TRANSLATION_CHANGED or _locale == "":
		return
	if TranslationServer.get_locale() == _locale:
		return
	_locale = TranslationServer.get_locale()
	_retranslate.call_deferred()


## Shows the screen in the new language (SPEC Section 23.1). The warp plays on:
## it changes its text in place, because a new warp screen plays the warp again.
func _retranslate() -> void:
	if _screen is WarpScreen:
		_screen.retranslate()
		return
	_screen_kind = ""
	_update()


## Plays the music loop on all screens (SPEC Section 4.3). Main runs during the
## pause, so the music does too. A browser starts the sound at the first click.
func _add_music() -> void:
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	var stream: AudioStreamOggVorbis = load(MUSIC_PATH)
	stream.loop = true
	_music.stream = stream
	add_child(_music)
	# Headless runs (the tests) have no audio device.
	if DisplayServer.get_name() != "headless":
		_music.play()


## Returns the music player. The UI check uses it.
func music() -> AudioStreamPlayer:
	return _music


## Adds the CRT filter above all screens and overlays (SPEC Section 4.2).
func _add_crt() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_crt = ColorRect.new()
	_crt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_crt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = load("res://scenes/common/crt.gdshader")
	_crt.material = material
	layer.add_child(_crt)


func _process(_delta: float) -> void:
	_crt.visible = Settings.get_value("crt")


## Starts a new run, and counts it for the hints (SPEC Section 23.3).
static func start_run() -> void:
	Hints.run_started()
	GameState.new_run()


## Returns the screen now. The UI check uses it.
func screen() -> Control:
	return _screen


## Opens an overlay: the pause menu, the settings, or How to Play.
func open_overlay(overlay: Overlay) -> Overlay:
	_overlays.add_child(overlay)
	return overlay


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		return
	if _overlays.get_child_count() > 0:
		return
	if _screen_kind == Defs.PHASE_STATION or _screen_kind == Defs.PHASE_ARRIVAL:
		open_overlay(PauseMenu.new())
		get_viewport().set_input_as_handled()


## Maximizes the window at startup, as Regalia does. The screen scales with the
## window (SPEC Section 4.1). The web build fills the page by itself.
func _fit_window_to_screen() -> void:
	# In the editor's Game tab, the editor sets the size of the embedded window.
	if (
		DisplayServer.get_name() == "headless"
		or Engine.is_embedded_in_editor()
		or OS.has_feature("web")
	):
		return
	if not Settings.get_value("fullscreen"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)


## The title screen (SPEC Section 20.1).
func _title() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(Starfield.new())
	# The small hold behind the title shows the idea of the game (SPEC Section 20.1).
	var title_hold := TitleHold.new()
	title_hold.name = "TitleHold"
	title_hold.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(title_hold)
	# A CenterContainer keeps the box in the center at each window size.
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	center.add_child(box)
	var title := Label.new()
	title.text = tr(TITLE_TEXT)
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Palette.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var new_run := _title_button(box, NEW_RUN_TEXT, start_run)
	new_run.name = "NewRunButton"
	_title_button(box, HOW_TO_PLAY_TEXT, func() -> void: open_overlay(HowToPlay.new()))
	_title_button(box, SETTINGS_TEXT, func() -> void: open_overlay(SettingsPanel.new()))
	if not OS.has_feature("web"):
		_title_button(box, QUIT_TEXT, func() -> void: get_tree().quit())
	new_run.grab_focus.call_deferred()
	return root


func _title_button(box: VBoxContainer, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = tr(text)
	b.custom_minimum_size = Vector2(320, 64)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(action)
	box.add_child(b)
	return b
