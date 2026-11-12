extends Control
## The main scene. It shows the screen of the phase of the run (SPEC Section 20):
## the title, the station, the warp with the arrival report, and PhasePanel for
## the toll gate and the run end. Esc opens the pause menu (SPEC Section 20.7).

const TITLE_TEXT := "PAYLOAD PROTOCOL"
const NEW_RUN_TEXT := "New Run"
const HOW_TO_PLAY_TEXT := "How to Play"
const SETTINGS_TEXT := "Settings"
const QUIT_TEXT := "Quit"

var _screen: Control
var _screen_kind := ""
var _overlays: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Settings.apply()
	_fit_window_to_screen()
	_overlays = CanvasLayer.new()
	_overlays.layer = 10
	add_child(_overlays)
	GameState.state_changed.connect(_update)
	_update()


func _update() -> void:
	var run: Dictionary = GameState.view()["run"]
	var kind := "title" if run.is_empty() else str(run["phase"])
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
	var new_run := _title_button(box, NEW_RUN_TEXT, func() -> void: GameState.new_run())
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
