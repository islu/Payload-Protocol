class_name RouteCards
## The look of the route: the tag of the environment of the leg (SPEC Section 28.1)
## and the card of the incident of the next jump (SPEC Section 29.3).

const INCIDENT_TEXT := {
	Defs.INCIDENT_METEOR: "Meteor · Column {x}",
	Defs.INCIDENT_ION_PULSE: "Ion Pulse · Row {y}",
	Defs.INCIDENT_HULL_BREACH: "Hull Breach · Column {x}, Row {y}",
}
## The color of an incident and its place in the hold.
const INCIDENT_COLOR := Color(1.0, 0.35, 0.3)


## Returns the text of an incident: its name and its place. The columns and the rows
## count from 1 for the player.
static func incident_text(inc: Dictionary) -> String:
	var key: String = INCIDENT_TEXT.get(inc.get("kind", ""), "")
	return TranslationServer.translate(key).format(
		{"x": inc.get("x", 0) + 1, "y": inc.get("y", 0) + 1}
	)


## Adds a tag with the name of the environment. The station shows its rule in its tip
## when the mouse is on it.
static func env_tag(parent: Control, env: Dictionary) -> PanelContainer:
	var tag := _tag(Palette.WARN)
	tag.name = "Environment"
	var l := Label.new()
	l.text = TranslationServer.translate(env["name"])
	l.add_theme_font_size_override("font_size", TextSize.SMALL)
	l.add_theme_color_override("font_color", Palette.WARN)
	tag.add_child(l)
	parent.add_child(tag)
	return tag


## Adds the card of an incident: a mark and its text (SPEC Section 29.3).
static func incident_card(parent: Control, inc: Dictionary) -> PanelContainer:
	var card := _tag(INCIDENT_COLOR)
	card.name = "Incident"
	card.custom_minimum_size = Vector2(120, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	card.add_child(box)
	var mark := Label.new()
	mark.text = "!"
	TextSize.display(mark, 44)
	mark.add_theme_color_override("font_color", INCIDENT_COLOR)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(mark)
	var text := Label.new()
	text.text = incident_text(inc)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = 110
	text.add_theme_font_size_override("font_size", TextSize.SMALL)
	text.add_theme_color_override("font_color", INCIDENT_COLOR)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(text)
	parent.add_child(card)
	return card


static func _tag(color: Color) -> PanelContainer:
	var tag := PanelContainer.new()
	tag.mouse_filter = Control.MOUSE_FILTER_STOP
	tag.add_theme_stylebox_override("panel", Ui.panel_style(color, 1, 4, 6))
	return tag
