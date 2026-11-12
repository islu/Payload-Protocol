extends Control
## The main scene. It shows the screen of the phase of the run (SPEC Section 20).
## The arrival, the toll gate, and the run end use PhasePanel until their own
## screens exist (docs/plan.md, Day 5).

const TITLE_TEXT := "PAYLOAD PROTOCOL"
const NEW_RUN_TEXT := "New Run"
const QUIT_TEXT := "Quit"

var _screen: Control
var _screen_kind := ""


func _ready() -> void:
	_fit_window_to_screen()
	GameState.state_changed.connect(_update)
	_update()


func _update() -> void:
	var run: Dictionary = GameState.view()["run"]
	var kind := "title" if run.is_empty() else str(run["phase"])
	if kind == Defs.PHASE_ARRIVAL or kind == Defs.PHASE_TOLL or kind == Defs.PHASE_END:
		kind = "phase"
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
		_:
			_screen = PhasePanel.new()
	add_child(_screen)


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
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)


## Returns the screen now. The UI check uses it.
func screen() -> Control:
	return _screen


func _title() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Palette.BACKGROUND
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
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
	var new_run := Button.new()
	new_run.name = "NewRunButton"
	new_run.text = tr(NEW_RUN_TEXT)
	new_run.custom_minimum_size = Vector2(320, 64)
	new_run.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	new_run.pressed.connect(func() -> void: GameState.new_run())
	box.add_child(new_run)
	if OS.get_name() != "Web":
		var quit := Button.new()
		quit.text = tr(QUIT_TEXT)
		quit.custom_minimum_size = Vector2(320, 64)
		quit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		quit.pressed.connect(func() -> void: get_tree().quit())
		box.add_child(quit)
	return root
