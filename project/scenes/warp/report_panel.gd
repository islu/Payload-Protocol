class_name ReportPanel
extends PanelContainer
## The arrival report: a card for each contract, the ledger, the credits before and
## after, the pilot, Replay, and Continue (SPEC Section 20.4).

signal pieces_hovered(ids: Array)

const ARRIVAL_TEXT := "Arrival"
const CONTINUE_TEXT := "Continue"
const REPLAY_TEXT := "Replay (slow)"
const BONUS_TEXT := "Bonus +{bonus}"
const BONUS_MISSED_TEXT := "Bonus missed"
const BREACH_TEXT := "Breach -{breach}"
const PENALTY_TEXT := "Penalty -{penalty}"
const COUNT_TEXT := "×{count}"
const PIECE_STATE_TEXT := {
	Defs.PIECE_DELIVERED: "delivered",
	Defs.PIECE_SCRAP: "scrap",
	Defs.PIECE_SPOILED: "spoiled",
	Defs.PIECE_LOST: "lost",
	Defs.PIECE_BREACHED: "breached",
}
const LEDGER_TEXT := {
	"deliveries": "Deliveries",
	"bonuses": "Bonuses",
	"insurance": "Insurance",
	"breaches": "Breach fees",
	"penalties": "Penalties",
	"sold": "Kit sold from the dock",
	"scrap_cleared": "Scrap cleared from the dock",
	"fuel_fee": "Fuel fee",
	"net": "Net",
}
## The lines of the ledger that take credits away.
const LEDGER_COSTS: PackedStringArray = ["breaches", "penalties", "scrap_cleared", "fuel_fee"]
const CREDITS_TEXT := "Credits {before} → {after}"
const CELL := 40.0

var head: Label
var replay: Button
var continue_button: Button
## Each group of pieces on the cards, for the marks: {ids: Array, control: Control, text}.
var items: Array = []
## The text of the ledger and the credits, for the checks.
var ledger_text := ""
var pilot_face: PilotFace
var _cards: VBoxContainer
var _ledger: GridContainer
var _credits: Label
var _pilot: Label


func _init() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.PANEL, 0.95)
	style.border_color = Palette.ACCENT
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(22)
	add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	head = _label(box, "", 40, Palette.ACCENT)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_cards = VBoxContainer.new()
	_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards.add_theme_constant_override("separation", 8)
	scroll.add_child(_cards)
	var ledger_panel := _panel(box, Palette.PANEL_LINE, 1)
	var ledger_box := VBoxContainer.new()
	ledger_panel.add_child(ledger_box)
	_ledger = GridContainer.new()
	_ledger.columns = 2
	_ledger.add_theme_constant_override("h_separation", 24)
	ledger_box.add_child(_ledger)
	_credits = _label(ledger_box, "", TextSize.BODY, Palette.WARN)
	var pilot := HBoxContainer.new()
	pilot.add_theme_constant_override("separation", 12)
	box.add_child(pilot)
	pilot_face = PilotFace.new()
	pilot.add_child(pilot_face)
	_pilot = _label(pilot, "", TextSize.BODY, Palette.WARN)
	_pilot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pilot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pilot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	replay = Button.new()
	replay.add_theme_font_size_override("font_size", TextSize.BUTTON)
	box.add_child(replay)
	continue_button = Button.new()
	continue_button.custom_minimum_size = Vector2(0, 70)
	continue_button.add_theme_font_size_override("font_size", 28)
	continue_button.pressed.connect(func() -> void: GameState.continue_run())
	box.add_child(continue_button)
	retranslate()


func retranslate() -> void:
	head.text = tr(ARRIVAL_TEXT)
	replay.text = tr(REPLAY_TEXT)
	continue_button.text = tr(CONTINUE_TEXT)


## Shows the report of the arrival of a run view (SPEC Section 20.4).
func show_report(run: Dictionary) -> void:
	retranslate()
	var a: Dictionary = run["arrival"]
	StationScreen._clear(_cards)
	items.clear()
	for k: Dictionary in a.get("contracts", []):
		_card(k)
	StationScreen._clear(_ledger)
	var lines := PackedStringArray()
	var ledger: Dictionary = a.get("ledger", {})
	for key: String in LEDGER_TEXT:
		var amount: int = ledger.get(key, 0)
		var cost := key in LEDGER_COSTS
		var value := -amount if cost else amount
		var color := Palette.TEXT if key == "net" else Palette.TEXT_DIM
		if key == "net":
			color = Palette.GOOD if value >= 0 else Palette.BAD
		var name := _label(_ledger, "", TextSize.BODY, color)
		name.text = tr(LEDGER_TEXT[key])
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var amount_label := _label(_ledger, "", TextSize.BODY, color)
		amount_label.text = amount(value)
		amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lines.append("%s %s" % [name.text, amount_label.text])
	_credits.text = tr(CREDITS_TEXT).format(
		{"before": a.get("credits_before", 0), "after": a.get("credits_after", 0)}
	)
	lines.append(_credits.text)
	ledger_text = "\n".join(lines)
	_pilot.text = "%s: %s" % [GameText.PILOT_NAME, tr(run["line"])]


## A card of a contract: the client, the pay, and a group for each freight and state.
func _card(k: Dictionary) -> void:
	var card := _panel(_cards, Palette.PANEL_LINE, 2)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	var top := HBoxContainer.new()
	box.add_child(top)
	var client := _label(top, "", TextSize.BODY)
	client.text = tr(k["client_name"])
	client.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pay := _label(top, "", TextSize.BODY, Palette.GOOD if k["pay"] > 0 else Palette.TEXT_DIM)
	pay.text = "+%d" % k["pay"]
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 16)
	row.add_theme_constant_override("v_separation", 4)
	box.add_child(row)
	for g: Dictionary in k.get("groups", []):
		row.add_child(_group(g))
	var notes := PackedStringArray()
	if k["has_bonus"]:
		notes.append(tr(BONUS_TEXT).format(k) if k["bonus_met"] else tr(BONUS_MISSED_TEXT))
	if k["breach"] > 0:
		notes.append(tr(BREACH_TEXT).format(k))
	if k.get("penalty", 0) > 0:
		notes.append(tr(PENALTY_TEXT).format(k))
	if not notes.is_empty():
		var note := _label(
			box, "", TextSize.SMALL, Palette.WARN if k["bonus_met"] else Palette.TEXT_DIM
		)
		note.text = " · ".join(notes)


## A group of pieces: the image, ×N, and the state. The mouse on it marks the pieces.
func _group(g: Dictionary) -> Control:
	var item := HBoxContainer.new()
	item.add_theme_constant_override("separation", 4)
	item.mouse_filter = Control.MOUSE_FILTER_STOP
	var delivered: bool = g["state"] == Defs.PIECE_DELIVERED
	var look := {
		"def_id": g["def_id"],
		"shape": g["shape"],
		"kind": Defs.KIND_FREIGHT if delivered else Defs.KIND_SCRAP,
		"weight_value": g["weight_value"],
		"traits": [],
	}
	var size := CargoDraw.shape_size(g["shape"])
	var chip := CargoChip.new().setup(look, CELL if maxi(size.x, size.y) <= 1 else CELL * 0.6)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.mouse_default_cursor_shape = Control.CURSOR_ARROW
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	item.add_child(chip)
	var color := Palette.GOOD if delivered else Palette.BAD
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(16, 16)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(func() -> void: draw_state(icon, delivered, color))
	item.add_child(icon)
	var text := _label(item, "", TextSize.SMALL, color)
	text.text = "%s %s" % [tr(COUNT_TEXT).format(g), tr(PIECE_STATE_TEXT[g["state"]])]
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ids: Array = g["ids"]
	item.mouse_entered.connect(func() -> void: pieces_hovered.emit(ids))
	item.mouse_exited.connect(func() -> void: pieces_hovered.emit([]))
	items.append({"ids": ids, "control": item, "text": tr(g["name"]) + " " + text.text})
	return item


## Returns the text of an amount of the ledger: "0", or a sign and the number.
static func amount(value: int) -> String:
	return "0" if value == 0 else "%+d" % value


## Draws the icon of a state in a 16 pixel square: a check for delivered, a cross for the rest.
static func draw_state(canvas: CanvasItem, delivered: bool, color: Color) -> void:
	if delivered:
		canvas.draw_polyline(
			PackedVector2Array([Vector2(2, 8), Vector2(6, 13), Vector2(14, 3)]), color, 3.0
		)
	else:
		canvas.draw_line(Vector2(3, 3), Vector2(13, 13), color, 3.0)
		canvas.draw_line(Vector2(13, 3), Vector2(3, 13), color, 3.0)


func _label(parent: Control, text: String, font_size: int, color := Palette.TEXT) -> Label:
	var l := Label.new()
	l.text = tr(text) if text != "" else ""
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func _panel(parent: Control, border: Color, width: int) -> PanelContainer:
	var p := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PANEL
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	p.add_theme_stylebox_override("panel", style)
	parent.add_child(p)
	return p
