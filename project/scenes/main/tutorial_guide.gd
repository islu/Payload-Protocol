class_name TutorialGuide
extends Control
## The guide of the tutorial (SPEC Section 23.4): the screen is dark except for the
## areas that the step opens, and a pilot box shows the step. Only the open areas
## take the mouse: _has_point() is false there, so a click goes to the screen below.
## The screen gives the areas with tutorial_rects(step). The guide reads the view only.

const NEXT_TEXT := "Next"
const RETRY_TEXT := "Try Again"
const SKIP_TEXT := "Skip Tutorial"
const SKIP_CONFIRM_TEXT := "Skip the tutorial and start a run?"
const DONE_TEXT := "Tutorial complete. I will tell you about the rest when you see it."
const START_TEXT := "Start a Run"
const DIM := Color(0, 0, 0, 0.62)
const FRAME := 6.0

## Returns the screen now (main.gd). The screen gives the open areas.
var screen_of: Callable
## The step now, from the view: {} with no tutorial.
var step: Dictionary = {}
## The open areas of the step, in the coordinates of the viewport.
var open_rects: Array[Rect2] = []
## The buttons of the pilot box. The UI check presses them.
var next_button: Button
var retry_button: Button
var skip_button: Button
var start_button: Button

var _box: PanelContainer
var _text: Label
var _confirm: ConfirmationDialog
var _locale := ""


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func _ready() -> void:
	_box = PanelContainer.new()
	_box.add_theme_stylebox_override("panel", Ui.panel_style(Palette.ACCENT, 2, 8, 20))
	_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_box.custom_minimum_size.x = 900
	_box.position.y -= 24
	add_child(_box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	_box.add_child(row)
	var face := PilotFace.new()
	face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(face)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 12)
	row.add_child(col)
	_text = Ui.label(col, "", TextSize.BODY)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size.x = 640
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 12)
	col.add_child(buttons)
	skip_button = _button(buttons, SKIP_TEXT, _ask_skip)
	retry_button = _button(buttons, RETRY_TEXT, func() -> void: GameState.tutorial_retry())
	next_button = _button(buttons, NEXT_TEXT, func() -> void: GameState.tutorial_next())
	start_button = _button(buttons, START_TEXT, finish)
	_confirm = ConfirmationDialog.new()
	_confirm.confirmed.connect(finish)
	add_child(_confirm)
	GameState.state_changed.connect(_update)
	_update()


func _button(parent: Control, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.set_meta("text", text)
	b.text = tr(text)
	b.custom_minimum_size = Vector2(200, 56)
	b.pressed.connect(action)
	parent.add_child(b)
	return b


## Reads the step of the view, and shows it.
func _update() -> void:
	step = GameState.view().get("tutorial", {})
	visible = not step.is_empty()
	if not visible:
		return
	var done: bool = step["done"]
	if done:
		_text.text = tr(DONE_TEXT)
	elif step["failed"]:
		_text.text = tr(step["fail"])
	else:
		_text.text = tr(step["text"])
	next_button.visible = not done and step["next"] and not step["failed"]
	retry_button.visible = not done and step["failed"]
	skip_button.visible = not done
	start_button.visible = done


func _process(_delta: float) -> void:
	if not visible:
		return
	if TranslationServer.get_locale() != _locale:
		_locale = TranslationServer.get_locale()
		for b: Button in [next_button, retry_button, skip_button, start_button]:
			b.text = tr(b.get_meta("text"))
		_update()
	var rects: Array[Rect2] = []
	var screen: Control = screen_of.call() if screen_of.is_valid() else null
	var open: bool = not step["done"] and not step["failed"]
	if open and screen != null and screen.has_method("tutorial_rects"):
		rects = screen.tutorial_rects(step)
	if rects != open_rects:
		open_rects = rects
		queue_redraw()


## Starts a run from the title or the run end: the tutorial the first time, else a
## normal run that counts for the hints (SPEC Sections 23.3 and 23.4).
static func start_run() -> void:
	if not Settings.get_value("tutorial_done"):
		GameState.start_tutorial()
		return
	Hints.run_started()
	GameState.new_run()


## Ends the tutorial after Skip or at its end, and starts a normal run (SPEC Section 23.4).
static func finish() -> void:
	Settings.set_value("tutorial_done", true)
	start_run()


## A click in an open area goes to the screen below. A click on the pilot box goes
## to its buttons first.
func _has_point(point: Vector2) -> bool:
	for r in open_rects:
		if r.has_point(point):
			return false
	return true


## Draws the dark screen around the open areas, and a frame around each one.
func _draw() -> void:
	var full := Rect2(Vector2.ZERO, size)
	for r in dark_rects(full, open_rects):
		draw_rect(r, DIM)
	for r in open_rects:
		draw_rect(r.grow(FRAME * 0.5), Palette.ACCENT, false, FRAME)


## Returns rects that cover the full area outside the open areas: the cells of a grid
## made from the edges of the open areas.
static func dark_rects(full: Rect2, holes: Array[Rect2]) -> Array[Rect2]:
	var xs := [full.position.x, full.end.x]
	var ys := [full.position.y, full.end.y]
	for h in holes:
		xs.append_array([h.position.x, h.end.x])
		ys.append_array([h.position.y, h.end.y])
	xs.sort()
	ys.sort()
	var out: Array[Rect2] = []
	for i in xs.size() - 1:
		for j in ys.size() - 1:
			var cell := Rect2(xs[i], ys[j], xs[i + 1] - xs[i], ys[j + 1] - ys[j])
			if cell.size.x <= 0 or cell.size.y <= 0:
				continue
			var center := cell.get_center()
			if not holes.any(func(h: Rect2) -> bool: return h.has_point(center)):
				out.append(cell)
	return out


func _ask_skip() -> void:
	_confirm.dialog_text = tr(SKIP_CONFIRM_TEXT)
	_confirm.popup_centered()
