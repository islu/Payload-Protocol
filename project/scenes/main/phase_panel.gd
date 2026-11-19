class_name PhasePanel
extends Control
## The payment screen and the run end (SPEC Sections 19.2, 20.5, and 20.6). The
## payment screen has a receipt in large numbers, a row for each jump of the leg, and
## the next leg. The run end has the score, a tile for each value, a row for each leg,
## and the ship. It reads the view only.

const CONTINUE_TEXT := "Continue"
const PAYMENT_TITLE_TEXT := "Payment"
const PAY_TEXT := "Pay"
const CREDITS_TEXT := "Credits"
const PAYMENT_TEXT := "Payment"
const AFTER_TEXT := "After"
const PAID_TEXT := "PAID"
const MISSED_TEXT := "MISSED"
const JUMP_TEXT := "Jump {jump}"
const DELIVERED_TEXT := "{count} delivered"
const SCRAP_TEXT := "{count} scrap"
const EXPLOSIONS_TEXT := "{count} explosions"
const NEXT_TEXT := "Next: Leg {leg} · {jumps} jumps · payment {payment}"
const WIN_TEXT := "Route complete!"
const LOSS_TEXT := "Run over."
const SCORE_TEXT := "Score"
const BEST_JUMP_TEXT := "Best jump"
const BEST_JUMP_AT_TEXT := "Leg {leg} · Jump {jump}"
const LEG_TEXT := "Leg {leg}"
const LEG_PAYMENT_TEXT := "Payment {payment}"
const LEG_NET_TEXT := "Net {net}"
const MODS_TEXT := "Mods: {mods}"
const NO_MODS_TEXT := "No mods"
const SHIP_TEXT := "Clamps {clamps} · Shock bay {bay} · Mass limit {mass}"
const NO_BAY_TEXT := "none"
const SEED_TEXT := "Seed {seed}"
const COPY_TEXT := "Copy"
const COPIED_TEXT := "Copied"
const NEW_RUN_TEXT := "New Run"
const TITLE_BUTTON_TEXT := "Title"
## The sizes of the large numbers: display text (SPEC Section 4.2).
const RECEIPT_SIZE := 56
const STAMP_SIZE := 64
const SCORE_SIZE := 96
## The time of the count of the credits, and the wait after the stamp (SPEC Section 20.5).
const COUNT_TIME := 0.6
const STAMP_WAIT := 1.0
const WIDTH := 900.0

## The parts, for the checks and the tutorial.
var receipt: Array[Label] = []
var stamp: Label
var pay_button: Button
var jump_rows: Array[Control] = []
var next_label: Label
var score_label: Label
var tiles: Array[Control] = []
var leg_rows: Array[Control] = []
var ship_card: Control
var copy_button: Button

var _box: VBoxContainer
var _paying := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Palette.BACKGROUND
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_box = VBoxContainer.new()
	_box.custom_minimum_size.x = WIDTH
	_box.add_theme_constant_override("separation", 20)
	center.add_child(_box)
	GameState.state_changed.connect(refresh)
	refresh()


func refresh() -> void:
	var run: Dictionary = GameState.view()["run"]
	if run.is_empty() or _paying:
		return
	Ui.clear(_box)
	receipt.clear()
	jump_rows.clear()
	tiles.clear()
	leg_rows.clear()
	next_label = null
	score_label = null
	match run["phase"]:
		Defs.PHASE_PAYMENT:
			_build_payment(run)
		Defs.PHASE_END:
			_build_end(run)
	var line := Ui.label(_box, "", TextSize.BODY, Palette.WARN)
	line.text = GameText.PILOT_NAME + ": " + tr(run["line"])
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


# --- The payment screen (SPEC Section 20.5) ---


func _build_payment(run: Dictionary) -> void:
	var t: Dictionary = run["payment_screen"]
	_heading(PAYMENT_TITLE_TEXT)
	# The receipt, and the stamp over it.
	var stack := MarginContainer.new()
	_box.add_child(stack)
	var paper := Ui.panel(stack, Palette.PANEL_LINE, 2)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	paper.add_child(grid)
	_receipt_row(grid, CREDITS_TEXT, str(t["credits"]), Palette.TEXT)
	_receipt_row(grid, PAYMENT_TEXT, "-%d" % t["payment"], Palette.BAD)
	_receipt_row(grid, AFTER_TEXT, str(t["after"]), Palette.GOOD if t["can_pay"] else Palette.BAD)
	var mid := CenterContainer.new()
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(mid)
	stamp = Label.new()
	TextSize.display(stamp, STAMP_SIZE)
	stamp.rotation_degrees = -12.0
	mid.add_child(stamp)
	_set_stamp(not t["can_pay"])
	stamp.visible = not t["can_pay"]
	# A row for each jump of the leg.
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 4)
	_box.add_child(rows)
	for j: Dictionary in t["jumps"]:
		jump_rows.append(_jump_row(rows, j))
	if not t["next"].is_empty():
		next_label = Ui.label(_box, "", TextSize.BODY, Palette.ACCENT)
		next_label.text = tr(NEXT_TEXT).format(t["next"])
	var buttons := _buttons()
	pay_button = _add_button(buttons, PAY_TEXT if t["can_pay"] else CONTINUE_TEXT, _pay)


func _receipt_row(grid: GridContainer, caption: String, value: String, color: Color) -> void:
	var l := Ui.label(grid, caption, TextSize.HEADING, Palette.TEXT_DIM)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var n := Ui.label(grid, "", RECEIPT_SIZE, color)
	TextSize.display(n)
	n.text = value
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	receipt.append(n)


func _set_stamp(missed: bool) -> void:
	stamp.text = tr(MISSED_TEXT if missed else PAID_TEXT)
	stamp.add_theme_color_override("font_color", Palette.BAD if missed else Palette.GOOD)
	stamp.add_theme_color_override("font_outline_color", Palette.BACKGROUND)
	stamp.add_theme_constant_override("outline_size", 10)
	stamp.pivot_offset = stamp.get_combined_minimum_size() / 2.0


func _jump_row(parent: Control, j: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	parent.add_child(row)
	var title := Ui.label(row, "", TextSize.BODY, Palette.TEXT)
	title.text = tr(JUMP_TEXT).format(j)
	title.custom_minimum_size.x = 140
	var net := Ui.label(row, "", TextSize.BODY, Palette.GOOD if j["net"] >= 0 else Palette.BAD)
	net.text = ReportPanel.amount(j["net"])
	net.custom_minimum_size.x = 90
	for pair: Array in [
		[DELIVERED_TEXT, j["delivered"]],
		[SCRAP_TEXT, j["scrapped"]],
		[EXPLOSIONS_TEXT, j["explosions"]]
	]:
		var l := Ui.label(row, "", TextSize.BODY, Palette.TEXT_DIM)
		l.text = tr(pair[0]).format({"count": pair[1]})
	return row


## Pay: the credits count down, the Paid stamp shows, and the next screen opens after
## STAMP_WAIT. A missed payment goes to the run end at once (SPEC Section 20.5).
func _pay() -> void:
	var t: Dictionary = GameState.view()["run"]["payment_screen"]
	if not t["can_pay"]:
		GameState.make_payment()
		return
	if _paying:
		return
	_paying = true
	pay_button.disabled = true
	Sound.play(self, "coin")
	var tween := create_tween()
	var credits := receipt[0]
	tween.tween_method(
		func(v: float) -> void: credits.text = str(roundi(v)), t["credits"], t["after"], COUNT_TIME
	)
	tween.tween_callback(func() -> void: stamp.visible = true)
	tween.tween_property(stamp, "scale", Vector2.ONE, 0.15).from(Vector2(1.6, 1.6))
	tween.tween_interval(STAMP_WAIT)
	tween.tween_callback(_paid)
	# The stamp shows at once for the checks; the tween makes its pop.
	_set_stamp(false)
	stamp.visible = true


func _paid() -> void:
	_paying = false
	GameState.make_payment()


# --- The run end (SPEC Sections 19.2 and 20.6) ---


func _build_end(run: Dictionary) -> void:
	var e: Dictionary = run["end"]
	_heading(WIN_TEXT if e["won"] else LOSS_TEXT)
	var score_box := VBoxContainer.new()
	score_box.add_theme_constant_override("separation", 0)
	_box.add_child(score_box)
	var caption := Ui.label(score_box, SCORE_TEXT, TextSize.BODY, Palette.TEXT_DIM)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label = Ui.label(score_box, "", SCORE_SIZE, Palette.GOOD if e["won"] else Palette.TEXT)
	TextSize.display(score_label)
	score_label.text = str(e["score"])
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# A tile for each value of the run.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_box.add_child(row)
	var s: Dictionary = e["stats"]
	_tile(row, str(s["delivered"]), tr(DELIVERED_TEXT).format({"count": ""}).strip_edges())
	_tile(row, str(s["scrapped"]), tr(SCRAP_TEXT).format({"count": ""}).strip_edges())
	_tile(row, str(s["explosions"]), tr(EXPLOSIONS_TEXT).format({"count": ""}).strip_edges())
	var best: Dictionary = e["best_jump"]
	if best.is_empty():
		_tile(row, "-", tr(BEST_JUMP_TEXT))
	else:
		_tile(
			row,
			ReportPanel.amount(best["net"]),
			tr(BEST_JUMP_TEXT) + "\n" + tr(BEST_JUMP_AT_TEXT).format(best)
		)
	# A row for each leg that started.
	var legs := VBoxContainer.new()
	legs.add_theme_constant_override("separation", 4)
	_box.add_child(legs)
	for l: Dictionary in e["legs"]:
		leg_rows.append(_leg_row(legs, l))
	_ship(e)
	var buttons := _buttons()
	_add_button(buttons, NEW_RUN_TEXT, _new_run)
	_add_button(buttons, TITLE_BUTTON_TEXT, func() -> void: GameState.abandon_run())


func _tile(parent: Control, value: String, caption: String) -> void:
	var tile := Ui.panel(parent, Palette.PANEL_LINE, 1)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	tile.add_child(col)
	var v := Ui.label(col, "", TextSize.HEADING, Palette.ACCENT)
	v.text = value
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var c := Ui.label(col, "", TextSize.SMALL, Palette.TEXT_DIM)
	c.text = caption
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tiles.append(tile)


func _leg_row(parent: Control, l: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	parent.add_child(row)
	var title := Ui.label(row, "", TextSize.BODY, Palette.TEXT)
	title.text = tr(LEG_TEXT).format(l)
	title.custom_minimum_size.x = 120
	var pay := Ui.label(row, "", TextSize.BODY, Palette.TEXT_DIM)
	pay.text = tr(LEG_PAYMENT_TEXT).format(l)
	pay.custom_minimum_size.x = 200
	var state := Ui.label(row, "", TextSize.BODY, Palette.GOOD if l["paid"] else Palette.BAD)
	state.text = tr(PAID_TEXT if l["paid"] else MISSED_TEXT)
	state.custom_minimum_size.x = 140
	var net := Ui.label(row, "", TextSize.BODY, Palette.GOOD if l["net"] >= 0 else Palette.BAD)
	net.text = tr(LEG_NET_TEXT).format({"net": ReportPanel.amount(l["net"])})
	return row


## The ship: the mods, the clamps, the shock bay, the mass limit, and the seed with
## a Copy button (SPEC Section 19.2).
func _ship(e: Dictionary) -> void:
	var ship: Dictionary = e["ship"]
	ship_card = Ui.panel(_box, Palette.PANEL_LINE, 1)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	ship_card.add_child(col)
	var names := PackedStringArray()
	for m: Dictionary in ship["mods"]:
		names.append(tr(m["name"]))
	var mods := Ui.label(col, "", TextSize.BODY, Palette.TEXT)
	mods.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if names.is_empty():
		mods.text = tr(NO_MODS_TEXT)
	else:
		mods.text = tr(MODS_TEXT).format({"mods": ", ".join(names)})
	var bay: Dictionary = ship["shock_bay"]
	var values := {
		"clamps": ship["clamps"],
		"bay": tr(NO_BAY_TEXT) if bay.is_empty() else "%d×%d" % [bay["columns"], bay["rows"]],
		"mass": ship["mass_limit"],
	}
	Ui.label(col, "", TextSize.BODY, Palette.TEXT_DIM).text = tr(SHIP_TEXT).format(values)
	var seed_row := HBoxContainer.new()
	seed_row.add_theme_constant_override("separation", 16)
	col.add_child(seed_row)
	var seed_label := Ui.label(seed_row, "", TextSize.BODY, Palette.TEXT_DIM)
	seed_label.text = tr(SEED_TEXT).format({"seed": e["seed"]})
	seed_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	copy_button = Button.new()
	copy_button.text = tr(COPY_TEXT)
	copy_button.add_theme_font_size_override("font_size", TextSize.BUTTON)
	var seed_text: String = e["seed"]
	copy_button.pressed.connect(
		func() -> void:
			DisplayServer.clipboard_set(seed_text)
			copy_button.text = tr(COPIED_TEXT)
	)
	seed_row.add_child(copy_button)


# --- Shared ---


func _heading(text: String) -> void:
	var h := Ui.label(_box, text, 48, Palette.ACCENT)
	TextSize.display(h)


func _buttons() -> HBoxContainer:
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 20)
	_box.add_child(buttons)
	return buttons


func _add_button(parent: Control, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = tr(text)
	b.custom_minimum_size = Vector2(240, 60)
	b.add_theme_font_size_override("font_size", TextSize.BUTTON)
	b.pressed.connect(action)
	parent.add_child(b)
	return b


func _new_run() -> void:
	TutorialGuide.start_run()


## Returns the areas that a tutorial step opens on the payment screen: the Pay button
## (SPEC Section 23.4).
func tutorial_rects(step: Dictionary) -> Array[Rect2]:
	var out: Array[Rect2] = []
	if step.get("target", {}).get("button", "") == Defs.ACT_PAY and pay_button != null:
		if is_instance_valid(pay_button) and pay_button.is_inside_tree():
			out.append(pay_button.get_global_rect())
	return out
