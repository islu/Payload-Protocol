class_name ContractCard
extends PanelContainer
## A contract card of the station: the client, the freight groups, the totals,
## the mass after it is accepted, the loaded pieces, and the bonus (SPEC Section 20.2).

const ACCEPT_TEXT := "Accept"
const CANCEL_TEXT := "Cancel"
const COUNT_TEXT := "×{count}"
const TOTALS_TEXT := "{pieces} pieces · Pay {pay} each · Total {total}"
const MASS_OK_TEXT := "Mass {mass} · After {after}/{limit}"
const MASS_FEE_TEXT := "Mass {mass} · After {after}/{limit} (fuel fee)"
const MASS_OVER_TEXT := "Mass {mass} · After {after}/{limit} (too heavy)"
const LOADED_TEXT := "Loaded {loaded}/{pieces}"
const BONUS_TEXT := "Bonus +{pay}: {text}"
## The cell of a freight image: a 1 cell freight, and a larger one.
const GROUP_CELL := 36.0
const GROUP_CELL_LARGE := 22.0

## The text of the card, for the checks.
var text := ""
## The color of the mass line: Palette.TEXT_DIM, WARN, or BAD.
var mass_color := Palette.TEXT_DIM
var screen: StationScreen


func setup(station: StationScreen, k: Dictionary) -> void:
	screen = station
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PANEL
	style.border_color = Palette.ACCENT if k["accepted"] else Palette.PANEL_LINE
	style.set_border_width_all(3 if k["accepted"] else 2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)
	var lines := PackedStringArray()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	box.add_child(head)
	var client := screen._label(
		head, "", TextSize.BODY, Palette.ACCENT if k["accepted"] else Palette.TEXT
	)
	client.text = tr(k["client_name"])
	client.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lines.append(client.text)
	var index: int = k["index"]
	if k["accepted"]:
		var loaded := screen._label(head, "", TextSize.SMALL, Palette.ACCENT)
		loaded.text = tr(LOADED_TEXT).format(k)
		lines.append(loaded.text)
		screen._button(
			head, tr(CANCEL_TEXT), func() -> void: screen._act(GameState.cancel_contract(index))
		)
	else:
		screen._button(
			head, tr(ACCEPT_TEXT), func() -> void: screen._act(GameState.accept_contract(index))
		)
	lines.append(_groups(box, k["groups"]))
	var totals := screen._label(box, "", TextSize.SMALL)
	totals.text = tr(TOTALS_TEXT).format(
		{"pieces": k["pieces"], "pay": k["pay"], "total": k["total_pay"]}
	)
	lines.append(totals.text)
	if not k["accepted"]:
		var state: String = k["mass_state"]
		var texts := {"ok": MASS_OK_TEXT, "fee": MASS_FEE_TEXT, "over": MASS_OVER_TEXT}
		var colors := {"ok": Palette.TEXT_DIM, "fee": Palette.WARN, "over": Palette.BAD}
		var mass_text: String = texts[state]
		mass_color = colors[state]
		var mass := screen._label(box, "", TextSize.SMALL, mass_color)
		mass.text = tr(mass_text).format(
			{"mass": k["mass"], "after": k["mass_after"], "limit": screen._run["mass"]["limit"]}
		)
		lines.append(mass.text)
	if not k["bonus"].is_empty():
		var b: Dictionary = k["bonus"]
		var bonus := screen._label(box, "", TextSize.SMALL, Palette.WARN)
		bonus.text = tr(BONUS_TEXT).format({"pay": b["pay"], "text": GameText.format(b["text"])})
		bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lines.append(bonus.text)
	text = "\n".join(lines)
	mouse_entered.connect(func() -> void: screen._set_hover_contract(index))
	mouse_exited.connect(func() -> void: screen._set_hover_contract(-1))


## Shows each freight group: its image, ×N, and its trait icons. It returns the text.
func _groups(parent: Control, groups: Array) -> String:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 14)
	row.add_theme_constant_override("v_separation", 6)
	parent.add_child(row)
	var out := PackedStringArray()
	for g: Dictionary in groups:
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 4)
		row.add_child(item)
		var size := CargoDraw.shape_size(g["shape"])
		var cell := GROUP_CELL if maxi(size.x, size.y) <= 1 else GROUP_CELL_LARGE
		var chip := CargoChip.new().setup(g, cell)
		chip.mouse_filter = Control.MOUSE_FILTER_PASS
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		chip.mouse_entered.connect(func() -> void: screen._show_tip(g))
		chip.mouse_exited.connect(screen._hide_tip)
		item.add_child(chip)
		var count := screen._label(item, "", TextSize.BODY)
		count.text = tr(COUNT_TEXT).format(g)
		count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		out.append(count.text)
		for t: String in g["traits"]:
			var icon := ShopPanel.trait_icon(t)
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			item.add_child(icon)
	return " ".join(out)
