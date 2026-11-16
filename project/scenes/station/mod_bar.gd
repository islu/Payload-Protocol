class_name ModBar
extends HBoxContainer
## The mod bar below the hold: a card with the icon of each mod of the ship. The
## mouse on a card shows the name and the rule of the mod, and marks its area on
## the hold (SPEC Section 20.2).

## The card of each mod, in the order of the view. The checks read them.
var cards: Array[PanelContainer] = []


func _init() -> void:
	add_theme_constant_override("separation", 8)
	alignment = BoxContainer.ALIGNMENT_CENTER


## Shows a card for each mod. hover gets the view of the mod under the mouse, or {}.
func set_mods(mods: Array, hover: Callable) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	cards.clear()
	for m: Dictionary in mods:
		var card := PanelContainer.new()
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var style := StyleBoxFlat.new()
		style.bg_color = Palette.PANEL
		style.border_color = Palette.ACCENT
		style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		style.set_content_margin_all(4)
		card.add_theme_stylebox_override("panel", style)
		card.add_child(ModIcon.new(m["id"], 32.0))
		card.mouse_entered.connect(hover.bind(m))
		card.mouse_exited.connect(hover.bind({}))
		add_child(card)
		cards.append(card)
