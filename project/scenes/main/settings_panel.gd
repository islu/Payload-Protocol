class_name SettingsPanel
extends Overlay
## The settings (SPEC Section 23.1).

const SETTINGS_TEXT := "Settings"
const MUSIC_TEXT := "Music volume"
const SOUND_TEXT := "Sound volume"
const CRT_TEXT := "CRT filter"
const SHAKE_TEXT := "Screen shake"
const WARP_SPEED_TEXT := "Warp speed 2×"
const FULLSCREEN_TEXT := "Fullscreen"
const HINTS_TEXT := "Hints"
const PICK_NEXT_TEXT := "Pick up the next cargo"
const LANGUAGE_TEXT := "Language"
const BACK_TEXT := "Back"
const LANGUAGE_NAMES := {"en": "English", "zh_TW": "繁體中文"}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	super()


## A slider saves at the end of its drag. The close of the panel saves too, for a
## change with the mouse wheel.
func _exit_tree() -> void:
	Settings.save()


func _build() -> void:
	heading(SETTINGS_TEXT)
	_slider(MUSIC_TEXT, "music_volume")
	_slider(SOUND_TEXT, "sound_volume")
	_toggle(CRT_TEXT, "crt")
	_toggle(SHAKE_TEXT, "shake")
	var fast := CheckButton.new()
	fast.text = tr(WARP_SPEED_TEXT)
	fast.button_pressed = int(Settings.get_value("warp_speed")) == 2
	fast.toggled.connect(func(on: bool) -> void: Settings.set_value("warp_speed", 2 if on else 1))
	box.add_child(fast)
	if not OS.has_feature("web"):
		_toggle(FULLSCREEN_TEXT, "fullscreen")
	_toggle(HINTS_TEXT, "hints")
	_toggle(PICK_NEXT_TEXT, "pick_next")
	var row := HBoxContainer.new()
	box.add_child(row)
	var label := Label.new()
	label.text = tr(LANGUAGE_TEXT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var options := OptionButton.new()
	for locale in Settings.LOCALES:
		options.add_item(LANGUAGE_NAMES.get(locale, locale))
	options.selected = maxi(0, Settings.LOCALES.find(Settings.get_value("locale")))
	options.item_selected.connect(
		func(i: int) -> void: Settings.set_value("locale", Settings.LOCALES[i])
	)
	row.add_child(options)
	button(BACK_TEXT, close).grab_focus()


func _toggle(text: String, key: String) -> void:
	var b := CheckButton.new()
	b.text = tr(text)
	b.button_pressed = Settings.get_value(key)
	b.toggled.connect(func(on: bool) -> void: Settings.set_value(key, on))
	box.add_child(b)


func _slider(text: String, key: String) -> void:
	var row := HBoxContainer.new()
	box.add_child(row)
	var label := Label.new()
	label.text = tr(text)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var s := HSlider.new()
	s.min_value = 0
	s.max_value = 100
	s.step = 5
	s.custom_minimum_size.x = 240
	s.value = Settings.get_value(key)
	# A drag changes the volume at each step, and saves the file at its end. A key
	# changes it too: the file saves when the slider loses the focus.
	s.value_changed.connect(func(v: float) -> void: Settings.set_value(key, int(v), false))
	s.drag_ended.connect(func(_changed: bool) -> void: Settings.save())
	s.focus_exited.connect(Settings.save)
	row.add_child(s)
