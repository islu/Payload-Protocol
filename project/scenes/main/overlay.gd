class_name Overlay
extends Control
## The base of a panel on top of a screen: a dark backdrop and a centered box.
## Esc closes it.

signal closed

var box: VBoxContainer
## The language of the text in the box.
var _locale := ""


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PANEL
	style.border_color = Palette.ACCENT
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	box.custom_minimum_size.x = 520
	panel.add_child(box)


func _ready() -> void:
	_locale = TranslationServer.get_locale()
	_build()


## Adds the content to the box. Each overlay overrides it. It runs again when
## the language changes (SPEC Section 23.1).
func _build() -> void:
	pass


func _notification(what: int) -> void:
	# The notification also comes when the node enters the tree, and when a
	# setting that is not the language changes. Build again only for a new language.
	if what != NOTIFICATION_TRANSLATION_CHANGED or _locale == "":
		return
	if TranslationServer.get_locale() == _locale:
		return
	_locale = TranslationServer.get_locale()
	_rebuild.call_deferred()


func _rebuild() -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()
	_build()


func close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


func heading(text: String) -> Label:
	var l := Label.new()
	l.text = tr(text)
	l.add_theme_font_size_override("font_size", 40)
	l.add_theme_color_override("font_color", Palette.ACCENT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(l)
	return l


func button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = tr(text)
	b.custom_minimum_size = Vector2(0, 56)
	b.pressed.connect(action)
	box.add_child(b)
	return b
