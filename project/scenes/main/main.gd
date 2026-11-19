extends Control
## The main scene. It shows the screen of the phase of the run (SPEC Section 20):
## the title, the station, the warp with the arrival report, and PhasePanel for
## the payment screen and the run end. Esc and the gear button open the pause menu
## (SPEC Section 20.7).

const TITLE_TEXT := "PAYLOAD\nPROTOCOL"
const TAGLINE_TEXT := "Pack the hold. Survive the warp."
const NEW_RUN_TEXT := "New Run"
const HOW_TO_PLAY_TEXT := "How to Play"
const TUTORIAL_TEXT := "Tutorial"
const SETTINGS_TEXT := "Settings"
const QUIT_TEXT := "Quit"
## The music loop (SPEC Section 4.3). docs/assets.md has its source.
const MUSIC_PATH := "res://audio/music/vintage_menu.ogg"

## The gear button of the station and the warp (SPEC Section 20.7).
var gear: GearButton
## The guide of the tutorial (SPEC Section 23.4).
var guide: TutorialGuide
## The event or the mod choice on top of the station (SPEC Sections 20.8 and 20.9):
## an EventPanel or a ChoicePanel.
var choice: Overlay
## The phase and the event or the mods of the choice now, so that a new choice builds
## a new panel.
var _choice_key := ""
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
	# The tutorial guide is over the screen and under the overlays (SPEC Section 23.4).
	var guide_layer := CanvasLayer.new()
	guide_layer.layer = 5
	add_child(guide_layer)
	guide = TutorialGuide.new()
	guide.screen_of = screen
	guide_layer.add_child(guide)
	gear = GearButton.new()
	gear.pressed.connect(open_pause)
	add_child(gear)
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
	if kind == Defs.PHASE_PAYMENT or kind == Defs.PHASE_END:
		kind = "gate"
	_update_choice(run)
	if kind == Defs.PHASE_EVENT or kind == Defs.PHASE_MOD:
		kind = Defs.PHASE_STATION
	gear.visible = choice == null and (kind == Defs.PHASE_STATION or kind == Defs.PHASE_ARRIVAL)
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


## Shows the event or the mod choice of the run, or closes it (SPEC Sections 20.8 and 20.9).
func _update_choice(run: Dictionary) -> void:
	var phase: String = run.get("phase", "")
	var key := ""
	if phase == Defs.PHASE_EVENT:
		key = phase + str(run["event"].get("id", ""))
	elif phase == Defs.PHASE_MOD:
		key = phase + ",".join(run["mod_offer"].map(func(m: Dictionary) -> String: return m["id"]))
	if key == _choice_key:
		return
	_choice_key = key
	if choice != null:
		choice.queue_free()
		choice = null
	if key != "":
		choice = EventPanel.new() if phase == Defs.PHASE_EVENT else ChoicePanel.new()
		open_overlay(choice)


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


## Starts a new run: the tutorial the first time (SPEC Sections 23.3 and 23.4).
static func start_run() -> void:
	TutorialGuide.start_run()


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
		open_pause()
		get_viewport().set_input_as_handled()


## Opens the pause menu, if no overlay is open (SPEC Section 20.7).
func open_pause() -> void:
	if _overlays.get_child_count() == 0:
		open_overlay(PauseMenu.new())


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
	# The title, the tagline, and the buttons are in the center (SPEC Section 20.1).
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var box := VBoxContainer.new()
	box.name = "TitleMenu"
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	center.add_child(box)
	var title := Label.new()
	title.text = tr(TITLE_TEXT)
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", Palette.ACCENT)
	title.add_theme_color_override("font_shadow_color", Color(Palette.ACCENT, 0.35))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 0)
	title.add_theme_constant_override("shadow_outline_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var tagline := Label.new()
	tagline.name = "Tagline"
	tagline.text = tr(TAGLINE_TEXT)
	tagline.add_theme_font_size_override("font_size", 30)
	tagline.add_theme_color_override("font_color", Palette.TEXT_DIM)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tagline)
	var gap := Control.new()
	gap.custom_minimum_size.y = 24
	box.add_child(gap)
	var new_run := _title_button(box, NEW_RUN_TEXT, start_run)
	new_run.name = "NewRunButton"
	var tutorial := _title_button(box, TUTORIAL_TEXT, func() -> void: GameState.start_tutorial())
	tutorial.name = "TutorialButton"
	_title_button(box, HOW_TO_PLAY_TEXT, func() -> void: open_overlay(HowToPlay.new()))
	_title_button(box, SETTINGS_TEXT, func() -> void: open_overlay(SettingsPanel.new()))
	if not OS.has_feature("web"):
		_title_button(box, QUIT_TEXT, func() -> void: get_tree().quit())
	var version := Label.new()
	version.name = "Version"
	version.text = "v" + str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	version.add_theme_font_size_override("font_size", TextSize.SMALL)
	version.add_theme_color_override("font_color", Palette.TEXT_DIM)
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	version.grow_vertical = Control.GROW_DIRECTION_BEGIN
	version.position -= Vector2(24, 16)
	root.add_child(version)
	new_run.grab_focus.call_deferred()
	return root


func _title_button(box: VBoxContainer, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = tr(text)
	b.custom_minimum_size = Vector2(360, 64)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(action)
	box.add_child(b)
	return b
