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
	Ui.clear(self)
	cards.clear()
	for m: Dictionary in mods:
		var card := PanelContainer.new()
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		# The player can only read a mod card (SPEC Section 20.10).
		card.mouse_default_cursor_shape = Control.CURSOR_HELP
		card.add_theme_stylebox_override("panel", Ui.panel_style(Palette.ACCENT, 1, 6, 4))
		card.add_child(ModIcon.new(m["id"], 32.0))
		card.mouse_entered.connect(hover.bind(m))
		card.mouse_exited.connect(hover.bind({}))
		add_child(card)
		cards.append(card)
