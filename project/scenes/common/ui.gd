class_name Ui
## Shared helpers that build the UI of the scenes: a label, a panel, the style of a
## panel, and the removal of the children of a node. Each color comes from Palette.


## Adds a label to a parent. It translates the text: give a key of the text, not a
## translated text.
static func label(parent: Control, text: String, font_size: int, color := Palette.TEXT) -> Label:
	var l := Label.new()
	l.text = TranslationServer.translate(text) if text != "" else ""
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


## Returns the style of a panel: the panel color, a border, round corners, and a
## margin. margin_y < 0 uses margin for the top and the bottom too.
static func panel_style(
	border := Palette.PANEL_LINE, width := 2, radius := 6, margin := 10.0, margin_y := -1.0
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PANEL
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin if margin_y < 0.0 else margin_y
	style.content_margin_bottom = style.content_margin_top
	return style


## Adds a panel with the style of panel_style() to a parent.
static func panel(parent: Control, border := Palette.PANEL_LINE, width := 2) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_style(border, width))
	parent.add_child(p)
	return p


## Removes and frees each child of a node.
static func clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
