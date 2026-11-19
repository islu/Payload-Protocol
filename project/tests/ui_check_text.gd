class_name UiCheckText
## The text sizes of the UI check (ui_check.gd): each visible text has one of the
## four sizes, or it is display text (SPEC Section 4.2).

## The four sizes of SPEC Section 4.2: heading, body, small, and button.
const SIZES := [28, 22, 18, 24]


## Checks each visible Label, Button, and RichTextLabel under root. Display text
## has the meta "display_text" (TextSize.display()).
static func check(ui: Node, root: Node, where: String) -> void:
	ui._check(
		[TextSize.HEADING, TextSize.BODY, TextSize.SMALL, TextSize.BUTTON] == SIZES,
		"TextSize has the four sizes of SPEC Section 4.2"
	)
	var wrong := PackedStringArray()
	for n in root.find_children("*", "", true, false):
		if not n is Control or not n.is_visible_in_tree() or _is_display(n):
			continue
		var font_size := -1
		if n is Label or n is Button:
			if n.text == "":
				continue
			font_size = n.get_theme_font_size("font_size")
		elif n is RichTextLabel:
			font_size = n.get_theme_font_size("normal_font_size")
		if font_size != -1 and not font_size in SIZES:
			wrong.append("%s %d %s" % [n.get_class(), font_size, root.get_path_to(n)])
	ui._check(
		wrong.is_empty(),
		"the text of %s has the four sizes: %s (SPEC Section 4.2)" % [where, wrong]
	)


## Display text, or text in a display container (the hazard cards).
static func _is_display(n: Node) -> bool:
	while n != null:
		if n.has_meta(TextSize.DISPLAY_META):
			return true
		n = n.get_parent()
	return false
