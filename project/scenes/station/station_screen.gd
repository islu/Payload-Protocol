class_name StationScreen
extends Control
## The station screen (SPEC Section 20.2): the top bar, the hazard, the dock,
## the contracts, the hold, the shop, the clamps, the sell area, the pilot, and
## the Warp button. It reads GameState.view() and calls the actions of GameState.

const DOCK_TEXT := "Dock"
const DOCK_COUNT_TEXT := "Dock ({count})"
const CONTRACTS_TEXT := "Contracts"
const SHOP_TEXT := "Shop"
const CLAMPS_TEXT := "Clamps"
const NEXT_JUMP_TEXT := "Next jump:"
const SELL_IDLE_TEXT := "Sell kit or clear scrap: drop it here"
const SELL_KIT_TEXT := "Sell {name}: +{price} cr"
const CLEAR_SCRAP_TEXT := "Clear the scrap: -{price} cr"
const NO_SELL_TEXT := "Freight cannot be sold"
const WARP_TEXT := "WARP"
const TOP_BAR_TEXT := "Sector {sector}/{sectors} · Jump {jump}/{jumps}"
const CREDITS_TEXT := "Credits: {credits}"
const TOLL_TEXT := "Toll {toll} after {jumps} jump(s)"
# gdlint:ignore = max-line-length
const FREE_CLAMPS_TEXT := "{free} of {total} free. Drag a clamp onto a cargo. Click a clamp to take it off."
const EMPTY_DOCK_TEXT := "Empty. Accept a contract or buy kit."
const CONFIRM_TITLE_TEXT := "Cargo on the dock"
# gdlint:ignore = max-line-length
const CONFIRM_TEXT := "Cargo on the dock stays at the station.\nEach freight on the dock pays a breach fee of {fee} credits.\nEach kit on the dock is sold at half price.\nWarp now?"
# gdlint:ignore = max-line-length
const HINT_TEXT := "Drag cargo, or click to pick it up and click to drop it. Right click or R rotates it."
const TIP_WEIGHT_TEXT := "{kind} · {weight} (weight {value})"
const TIP_PAY_TEXT := "Pays {pay} at the arrival"
const TIP_SELL_TEXT := "Sells for {price}"
const TIP_CLEAR_TEXT := "Clear for {price}"
const NO_COOLER_TEXT := "No Cooler next to it: it spoils at the arrival."
const NO_POWER_TEXT := "No Battery next to it: no power."
const MASS_TEXT := "Mass {hold}/{limit}"
const FUEL_TEXT := "Fuel fee {fee}"
const OVER_MAX_TEXT := "Too heavy: {max} at most"
const OR_TEXT := "or"
const UNDO_TEXT := "Undo (Ctrl+Z)"
## The mark of a fork step that a Sensor shows (SPEC Section 20.2).
const SENSOR_TEXT := "Sensor"
## The characters of a pilot line that type out in each second (SPEC Section 22).
const TYPE_SPEED := 40.0
const ARROWS := {Defs.DIR_LEFT: "←", Defs.DIR_RIGHT: "→", Defs.DIR_UP: "↑", Defs.DIR_DOWN: "↓"}
const TIP_MASS_TEXT := "Mass {mass}"
const LOAD_ALL_TEXT := "Load all"
const SIDE_WIDTH := 470.0
const SELL_HEIGHT := 48.0
## The cell of the cargo on the dock (SPEC Section 20.2).
const DOCK_CELL := 48.0
## A press and a release closer than this are a click: a pick up (SPEC Section 8.2).
const CLICK_DISTANCE := 8.0

var _view: Dictionary = {}
var _run: Dictionary = {}
## The drag now: {kind: "cargo" or "clamp", id, rot, grab: Vector2, press: Vector2,
## held: bool}, or empty. held is true after a click: a pick up (SPEC Section 8.2).
var _drag: Dictionary = {}
## True after the click that drops a picked-up cargo, so that its release does nothing.
var _ignore_release := false
var _hover_contract := -1
## The credits that the top bar shows now. They count to the view (SPEC Section 21.4).
var _shown_credits := -1

var _hold: HoldView
var _top_label: Label
var _credits_label: Label
var _toll_label: Label
var _mass_label: Label
var _hazard_box: VBoxContainer
var _dock_title: Label
var _dock_panel: PanelContainer
var _dock_flow: HFlowContainer
var _contracts_box: VBoxContainer
var _contract_cards: Array[ContractCard] = []
var _shop: ShopPanel
var _clamp_box: HBoxContainer
var _clamp_label: Label
var _sell_area: PanelContainer
var _sell_label: Label
## What the sell area shows now: "idle", "sell", "clear", or "none" (SPEC Section 20.2).
var _sell_mode := "idle"
var _warp_button: Button
var _undo_button: Button
var _pilot_label: Label
var _pilot_face: PilotFace
var _type_tween: Tween
var _tip: PanelContainer
var _tip_label: RichTextLabel
var _toast: Label
var _confirm: ConfirmationDialog
var _drag_layer: DragLayer
## The gold sparkle of a coin sound (SPEC Section 21.4).
var _fx: FxLayer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	GameState.state_changed.connect(refresh)
	refresh()


# --- Layout ---


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.BACKGROUND
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 40)
	root.add_child(top)
	_top_label = _label(top, "", TextSize.HEADING)
	_credits_label = _label(top, "", TextSize.HEADING, Palette.GOOD)
	_toll_label = _label(top, "", TextSize.BODY, Palette.TEXT_DIM)
	_mass_label = _label(top, "", TextSize.HEADING, Palette.TEXT)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 20)
	root.add_child(body)

	var left := VBoxContainer.new()
	left.custom_minimum_size.x = SIDE_WIDTH
	left.add_theme_constant_override("separation", 10)
	body.add_child(left)
	var dock_head := HBoxContainer.new()
	left.add_child(dock_head)
	_dock_title = _label(dock_head, DOCK_TEXT, TextSize.HEADING, Palette.ACCENT)
	_dock_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(dock_head, tr(LOAD_ALL_TEXT), func() -> void: _act(GameState.load_all(), "clack"))
	# The dock fits its cargo. An empty dock is one line (SPEC Section 20.2).
	_dock_panel = _panel(left)
	_dock_flow = HFlowContainer.new()
	_dock_flow.add_theme_constant_override("h_separation", 10)
	_dock_flow.add_theme_constant_override("v_separation", 10)
	_dock_panel.add_child(_dock_flow)
	_label(left, CONTRACTS_TEXT, TextSize.HEADING, Palette.ACCENT)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	_contracts_box = VBoxContainer.new()
	_contracts_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contracts_box.add_theme_constant_override("separation", 10)
	scroll.add_child(_contracts_box)
	var pilot := HBoxContainer.new()
	pilot.add_theme_constant_override("separation", 12)
	_panel(left).add_child(pilot)
	_pilot_face = PilotFace.new()
	pilot.add_child(_pilot_face)
	_pilot_label = _label(pilot, "", TextSize.BODY, Palette.ACCENT)
	_pilot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pilot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pilot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 8)
	body.add_child(center)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	center.add_child(row)
	# The hazard panel: one card for each shift step, from top to bottom, at the
	# left of the hold (SPEC Section 20.2).
	var hazard := VBoxContainer.new()
	hazard.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hazard.add_theme_constant_override("separation", 10)
	row.add_child(hazard)
	var next_jump := _label(hazard, NEXT_JUMP_TEXT, TextSize.BODY, Palette.WARN)
	next_jump.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hazard_box = VBoxContainer.new()
	_hazard_box.add_theme_constant_override("separation", 10)
	hazard.add_child(_hazard_box)
	_hold = HoldView.new()
	_hold.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hold.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hold.cargo_pressed.connect(_on_hold_pressed)
	_hold.clamp_pressed.connect(func(id: int) -> void: _act(GameState.unclamp_cargo(id)))
	_hold.cargo_hovered.connect(_on_hold_hovered)
	row.add_child(_hold)
	var hint := _label(center, HINT_TEXT, TextSize.SMALL, Palette.TEXT_DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var right := VBoxContainer.new()
	right.custom_minimum_size.x = SIDE_WIDTH
	right.add_theme_constant_override("separation", 10)
	body.add_child(right)
	_label(right, SHOP_TEXT, TextSize.HEADING, Palette.ACCENT)
	_shop = ShopPanel.new()
	_shop.screen = self
	right.add_child(_shop)
	_label(right, CLAMPS_TEXT, TextSize.HEADING, Palette.ACCENT)
	_clamp_box = HBoxContainer.new()
	_clamp_box.add_theme_constant_override("separation", 8)
	right.add_child(_clamp_box)
	_clamp_label = _label(right, "", TextSize.SMALL, Palette.TEXT_DIM)
	_clamp_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# The sell area is a small bar. A drag colors it (SPEC Section 20.2).
	_sell_area = _panel(right)
	_sell_area.custom_minimum_size.y = SELL_HEIGHT
	_sell_label = _label(_sell_area, "", TextSize.SMALL, Palette.TEXT_DIM)
	_sell_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sell_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_show_sell({})
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(spacer)
	# Undo takes back the last action at this station (SPEC Section 20.2).
	_undo_button = _button(right, tr(UNDO_TEXT), _undo, false)
	_warp_button = Button.new()
	_warp_button.text = tr(WARP_TEXT)
	_warp_button.custom_minimum_size = Vector2(0, 90)
	_warp_button.add_theme_font_size_override("font_size", 40)
	_warp_button.pressed.connect(_on_warp_pressed)
	right.add_child(_warp_button)

	_confirm = ConfirmationDialog.new()
	TextSize.apply_to_dialog(_confirm)
	_confirm.title = tr(CONFIRM_TITLE_TEXT)
	_confirm.confirmed.connect(func() -> void: _act(GameState.warp()))
	add_child(_confirm)

	_drag_layer = DragLayer.new()
	_drag_layer.hold = _hold
	add_child(_drag_layer)
	_fx = FxLayer.new()
	_fx.hold = _hold
	add_child(_fx)

	_tip = PanelContainer.new()
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.visible = false
	_tip.z_index = 10
	_tip_label = RichTextLabel.new()
	_tip_label.bbcode_enabled = true
	_tip_label.fit_content = true
	_tip_label.custom_minimum_size.x = 360
	_tip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for key in ["normal_font_size", "bold_font_size"]:
		_tip_label.add_theme_font_size_override(key, TextSize.BODY)
	_tip.add_child(_tip_label)
	add_child(_tip)

	_toast = Label.new()
	_toast.add_theme_color_override("font_color", Palette.BAD)
	_toast.add_theme_font_size_override("font_size", TextSize.HEADING)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.position.y -= 60
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast)


func _label(parent: Control, text: String, font_size: int, color := Palette.TEXT) -> Label:
	var l := Label.new()
	l.text = tr(text) if text != "" else ""
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func _panel(parent: Control) -> PanelContainer:
	var p := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PANEL
	style.border_color = Palette.PANEL_LINE
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	p.add_theme_stylebox_override("panel", style)
	parent.add_child(p)
	return p


func _button(parent: Control, text: String, action: Callable, enabled := true) -> Button:
	var b := Button.new()
	b.text = text
	b.disabled = not enabled
	b.add_theme_font_size_override("font_size", TextSize.BUTTON)
	b.pressed.connect(action)
	parent.add_child(b)
	return b


static func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


# --- Refresh from the view ---


func refresh() -> void:
	_view = GameState.view()
	_run = _view["run"]
	if _run.is_empty() or _run["phase"] != Defs.PHASE_STATION:
		return
	_top_label.text = tr(TOP_BAR_TEXT).format(_run)
	_count_credits(_run["credits"])
	_toll_label.text = tr(TOLL_TEXT).format({"toll": _run["toll"], "jumps": _run["jumps_to_toll"]})
	_show_mass()
	_show_pilot()
	_undo_button.disabled = not GameState.can_undo()
	_hold.set_view(_run)
	_refresh_hazard()
	_refresh_dock()
	_refresh_contracts()
	_shop.refresh()
	_refresh_clamps()
	_update_marks()


## Shows the hint of the first runs in the pilot box, or the line of the pilot (SPEC Section 23.3).
func _show_pilot() -> void:
	var hint := Hints.current(_run)
	var text := ""
	if hint == "":
		text = GameText.PILOT_NAME + ": " + tr(_run["line"])
		_pilot_label.add_theme_color_override("font_color", Palette.ACCENT)
	else:
		text = GameText.PILOT_NAME + " ▸ " + tr(Hints.text(hint))
		_pilot_label.add_theme_color_override("font_color", Palette.WARN)
	if text != _pilot_label.text:
		_pilot_label.text = text
		_type_line()
	_hazard_box.modulate = Color(1.4, 1.4, 1.4) if hint == Hints.HAZARD else Color.WHITE


## Types out the line of the pilot, and moves the mouth of the portrait (SPEC Section 22).
func _type_line() -> void:
	if _type_tween != null:
		_type_tween.kill()
	_pilot_label.visible_ratio = 0.0
	_pilot_face.talking = true
	var seconds := _pilot_label.get_total_character_count() / TYPE_SPEED
	_type_tween = create_tween()
	_type_tween.tween_property(_pilot_label, "visible_ratio", 1.0, seconds)
	_type_tween.tween_callback(func() -> void: _pilot_face.talking = false)


func _count_credits(target: int) -> void:
	if _shown_credits < 0:
		_set_credits(target)
		return
	var t := create_tween()
	t.tween_method(
		func(v: float) -> void: _set_credits(roundi(v)), float(_shown_credits), float(target), 0.4
	)


func _set_credits(value: int) -> void:
	_shown_credits = value
	_credits_label.text = tr(CREDITS_TEXT).format({"credits": value})


## Shows the hold mass, the limit, and the fuel fee (SPEC Section 25). Over the limit
## the text is yellow, and over the maximum it is red.
func _show_mass() -> void:
	var m: Dictionary = _run["mass"]
	var parts := PackedStringArray([tr(MASS_TEXT).format(m)])
	var color := Palette.TEXT
	if m["hold"] > m["max"]:
		parts.append(tr(OVER_MAX_TEXT).format(m))
		color = Palette.BAD
	elif m["fee"] > 0:
		parts.append(tr(FUEL_TEXT).format(m))
		color = Palette.WARN
	_mass_label.text = " · ".join(parts)
	_mass_label.add_theme_color_override("font_color", color)
	_warp_button.disabled = m["hold"] > m["max"]


## Shows each step of the hazard. A fork step shows its two directions, or the one
## that happens when a Sensor is in the hold (SPEC Section 18).
func _refresh_hazard() -> void:
	_clear(_hazard_box)
	var i := 0
	for step: Dictionary in _run["hazard"]:
		var index := i
		i += 1
		var color: Color = Palette.BAD if step["fork"] else Palette.WARN
		var card := _panel(_hazard_box)
		var style: StyleBoxFlat = card.get_theme_stylebox("panel")
		style.border_color = color
		card.custom_minimum_size = Vector2(120, 0)
		# The mouse on a card marks the front wall of its step (SPEC Section 20.2).
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		card.mouse_entered.connect(func() -> void: _set_hover_step(index))
		card.mouse_exited.connect(func() -> void: _set_hover_step(-1))
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 0)
		card.add_child(box)
		var look := step_card(step, _view)
		var big := _label(box, "", 52, color)
		big.text = look["arrow"]
		big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var name_label := _label(box, "", 17, color)
		name_label.text = "%d · %s" % [i, look["names"]]
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if look["sensor"]:
			var sensor := _label(box, "", TextSize.SMALL, Palette.ACCENT)
			sensor.text = "◉ " + tr(SENSOR_TEXT)
			sensor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


## Returns how a hazard card looks: {arrow, names, sensor}. A fork step shows its
## two directions and "?". A fork step that a Sensor shows has its one direction
## and the Sensor mark (SPEC Sections 18 and 20.2).
static func step_card(step: Dictionary, view: Dictionary) -> Dictionary:
	if step["fork"] and step["known"] == "":
		var arrow := ""
		var names := PackedStringArray()
		for d: String in step["directions"]:
			arrow += ARROWS.get(d, "?")
			names.append(direction_name(d, view))
		var joined := (" %s " % TranslationServer.translate(OR_TEXT)).join(names)
		return {"arrow": arrow + "?", "names": joined, "sensor": false}
	return {
		"arrow": ARROWS.get(step["known"], "?"),
		"names": direction_name(step["known"], view),
		"sensor": step["fork"],
	}


## Marks the front wall of a step in the hold, or of the first step for -1. The
## wall jolt warnings are for the first step only (SPEC Sections 12.3 and 20.2).
func _set_hover_step(index: int) -> void:
	var hazard: Array = _run.get("hazard", [])
	if index < 0 or index >= hazard.size():
		_hold.show_front_walls(PackedStringArray([_run.get("front_wall", "")]), true)
		return
	var step: Dictionary = hazard[index]
	var walls := PackedStringArray(step["directions"] if step["known"] == "" else [step["known"]])
	_hold.show_front_walls(walls, index == 0)


## Returns the arrow and the name of a direction.
static func direction_text(d: String, view: Dictionary) -> String:
	return "%s %s" % [ARROWS.get(d, "?"), direction_name(d, view)]


## Returns the translated name of a direction.
static func direction_name(d: String, view: Dictionary) -> String:
	return TranslationServer.translate(view["names"]["directions"].get(d, d))


func _refresh_dock() -> void:
	_clear(_dock_flow)
	_dock_title.text = tr(DOCK_COUNT_TEXT).format({"count": _run["dock"].size()})
	if _run["dock"].is_empty():
		_label(_dock_flow, EMPTY_DOCK_TEXT, TextSize.SMALL, Palette.TEXT_DIM)
	for c: Dictionary in _run["cargo"]:
		if c["in_hold"]:
			continue
		var chip := CargoChip.new().setup(c, DOCK_CELL)
		chip.pressed.connect(
			func(_chip: CargoChip) -> void: _begin_cargo_drag(c["id"], Vector2.ZERO)
		)
		chip.mouse_entered.connect(func() -> void: _show_tip(c))
		chip.mouse_exited.connect(_hide_tip)
		_dock_flow.add_child(chip)


func _refresh_contracts() -> void:
	_clear(_contracts_box)
	_contract_cards.clear()
	for k: Dictionary in _run["contracts"]:
		var card := ContractCard.new()
		_contracts_box.add_child(card)
		card.setup(self, k)
		_contract_cards.append(card)


## Shows the sell area for a dragged cargo view, or idle for {} (SPEC Section 20.2).
func _show_sell(c: Dictionary) -> void:
	var color := Palette.PANEL_LINE
	_sell_mode = "idle"
	_sell_label.text = tr(SELL_IDLE_TEXT)
	_sell_label.add_theme_color_override("font_color", Palette.TEXT_DIM)
	if not c.is_empty():
		match c.get("kind", Defs.KIND_FREIGHT):
			Defs.KIND_KIT:
				_sell_mode = "sell"
				color = Palette.GOOD
				_sell_label.text = tr(SELL_KIT_TEXT).format(
					{"name": tr(c["name"]), "price": c.get("sell_price", 0)}
				)
			Defs.KIND_SCRAP:
				_sell_mode = "clear"
				color = Palette.BAD
				_sell_label.text = tr(CLEAR_SCRAP_TEXT).format({"price": c.get("clear_price", 0)})
			_:
				_sell_mode = "none"
				_sell_label.text = tr(NO_SELL_TEXT)
		if _sell_mode != "none":
			_sell_label.add_theme_color_override("font_color", color)
	var style: StyleBoxFlat = _sell_area.get_theme_stylebox("panel").duplicate()
	style.border_color = color
	style.bg_color = Palette.PANEL if _sell_mode in ["idle", "none"] else Color(color, 0.15)
	_sell_area.add_theme_stylebox_override("panel", style)


func _refresh_clamps() -> void:
	_clear(_clamp_box)
	for i in _run["free_clamps"]:
		var chip := ClampChip.new()
		chip.pressed.connect(func() -> void: _begin_clamp_drag())
		_clamp_box.add_child(chip)
	_clamp_label.text = tr(FREE_CLAMPS_TEXT).format(
		{"free": _run["free_clamps"], "total": _run["clamps"]}
	)


func _set_hover_contract(index: int) -> void:
	_hover_contract = index
	_update_marks()


## Marks the freight of the contract under the mouse, and the zone of its bonus (SPEC Section 20.2).
func _update_marks() -> void:
	var marked := []
	var zone := []
	if _hover_contract >= 0 and _hover_contract < _run["contracts"].size():
		for c: Dictionary in _run["cargo"]:
			if c["contract"] == _hover_contract:
				marked.append(c["id"])
		var b: Dictionary = _run["contracts"][_hover_contract]["bonus"]
		if not b.is_empty():
			zone = b["zone"]
	# A drag of the freight of a zone contract shows the zone (SPEC Section 15.3).
	if not _drag.is_empty() and _drag["kind"] == "cargo":
		var c := _cargo(_drag["id"])
		if c.get("contract", -1) >= 0:
			var b: Dictionary = _run["contracts"][c["contract"]]["bonus"]
			if not b.is_empty():
				zone = b["zone"]
	_hold.marked = marked
	_hold.zone = zone
	_hold.queue_redraw()


func _cargo(id: int) -> Dictionary:
	for c: Dictionary in _run.get("cargo", []):
		if c["id"] == id:
			return c
	return {}


# --- Actions ---


## Shows the error of an action and plays the deny sound, or plays ok_sound when it works.
func _act(err: String, ok_sound := "") -> void:
	if err != "":
		_show_toast(tr(err))
		Sound.play(self, "deny")
	elif ok_sound != "":
		Sound.play(self, ok_sound)
		if ok_sound == "coin":
			_fx.coin(_credits_label.get_global_rect().get_center())


## Takes back the last action at this station (SPEC Section 20.2).
func _undo() -> void:
	_act(GameState.undo())


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(1.6)
	t.tween_property(_toast, "modulate:a", 0.0, 0.4)


func _on_warp_pressed() -> void:
	Hints.done(Hints.HAZARD)
	Hints.done(Hints.WARP)
	if not _run["dock"].is_empty():
		_confirm.dialog_text = tr(CONFIRM_TEXT).format({"fee": _run["shop"]["breach_fee"]})
		_confirm.popup_centered()
		return
	_act(GameState.warp())


func _on_hold_pressed(id: int, grab: Vector2i, button: int) -> void:
	if not _drag.is_empty():
		return
	if button == MOUSE_BUTTON_RIGHT:
		var err := GameState.rotate_cargo(id)
		_act(err, "clack")
		if err == "":
			Hints.done(Hints.ROTATE)
	elif button == MOUSE_BUTTON_LEFT:
		_begin_cargo_drag(id, Vector2(grab))


# --- Drag (SPEC Sections 8.2, 8.3, and 13) ---


func _begin_cargo_drag(id: int, grab: Vector2) -> void:
	var c := _cargo(id)
	if c.is_empty():
		return
	_hide_tip()
	_drag = {
		"kind": "cargo",
		"id": id,
		"rot": c["rot"],
		"grab": grab,
		"press": get_global_mouse_position(),
		"held": false,
		"from_dock": not c["in_hold"],
	}
	_hold.dragging = id
	_show_sell(c)
	_drag_layer.start(c, c["rotations"][c["rot"]], grab)
	_update_drag()
	_update_marks()


func _begin_clamp_drag() -> void:
	_drag = {"kind": "clamp", "press": get_global_mouse_position(), "held": false}
	_drag_layer.start_clamp()


func _input(event: InputEvent) -> void:
	var left_release: bool = (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and not event.pressed
	)
	if _ignore_release and left_release:
		_ignore_release = false
		get_viewport().set_input_as_handled()
		return
	if _drag.is_empty():
		if event.is_action_pressed(&"ui_undo"):
			_undo()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		_update_drag()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_left_button(event.pressed)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_rotate_drag()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_rotate_drag()
		elif event.keycode == KEY_ESCAPE:
			_end_drag()
		get_viewport().set_input_as_handled()


## The left button while the player holds a cargo or a clamp (SPEC Section 8.2):
## a release after a drag drops it, a release after a click picks it up, and the
## next press drops a picked-up cargo.
func _on_left_button(pressed: bool) -> void:
	if pressed:
		if _drag["held"]:
			_ignore_release = true
			_drop()
		return
	if (
		not _drag["held"]
		and get_global_mouse_position().distance_to(_drag["press"]) < CLICK_DISTANCE
	):
		_drag["held"] = true
	else:
		_drop()


func _rotate_drag() -> void:
	if _drag["kind"] != "cargo":
		return
	var c := _cargo(_drag["id"])
	_drag["rot"] = (_drag["rot"] + 1) % 4
	Hints.done(Hints.ROTATE)
	_show_pilot()
	_drag["grab"] = Vector2.ZERO
	_drag_layer.start(c, c["rotations"][_drag["rot"]], Vector2.ZERO)
	_update_drag()


func _update_drag() -> void:
	var mouse := get_global_mouse_position()
	_drag_layer.queue_redraw()
	if _drag["kind"] != "cargo" or not _hold.is_over(mouse):
		_hold.preview = {}
		_hold.queue_redraw()
		return
	var origin := _hold.snap_origin(mouse, _drag["grab"])
	var c := _cargo(_drag["id"])
	var cells: Array[Vector2i] = []
	for s: Dictionary in c["rotations"][_drag["rot"]]:
		cells.append(origin + Vector2i(s["x"], s["y"]))
	_hold.preview = {
		"cells": cells,
		"ok": GameState.can_place(_drag["id"], origin.x, origin.y, _drag["rot"]),
		"links": GameState.preview_links(_drag["id"], origin.x, origin.y, _drag["rot"]),
		"id": _drag["id"],
	}
	_hold.queue_redraw()


func _drop() -> void:
	_drop_at(get_global_mouse_position())


## Drops the held cargo or clamp at a global position (SPEC Sections 8.2 and 13).
func _drop_at(mouse: Vector2) -> void:
	var drag := _drag
	_end_drag()
	if drag["kind"] == "clamp":
		if _hold.is_over(mouse):
			var target := _hold.cargo_at(_hold.cell_at(mouse))
			if target >= 0:
				_act(GameState.clamp_cargo(target), "clack")
		return
	var id: int = drag["id"]
	var c := _cargo(id)
	if _sell_area.get_global_rect().has_point(mouse):
		if c["kind"] == Defs.KIND_SCRAP:
			_act(GameState.clear_scrap(id), "coin")
		else:
			_act(GameState.sell_kit(id), "coin")
	elif _dock_panel.get_global_rect().has_point(mouse):
		if c["in_hold"]:
			_act(GameState.dock_cargo(id))
	elif _hold.is_over(mouse):
		var origin := _hold.snap_origin(mouse, drag["grab"])
		var err := GameState.place_cargo(id, origin.x, origin.y, drag["rot"])
		_act(err, "clack")
		# A picked-up cargo from the dock: pick up the next one (SPEC Section 8.2).
		if err == "" and drag["held"] and drag["from_dock"]:
			_pick_next()
	# A drop anywhere else leaves the cargo in its last place (SPEC Section 8.3).


## Picks up the next cargo on the dock after a placement by clicks (SPEC Section 8.2).
func _pick_next() -> void:
	var dock: Array = GameState.view()["run"]["dock"]
	if dock.is_empty():
		return
	_begin_cargo_drag(dock[0], Vector2.ZERO)
	_drag["held"] = true


func _end_drag() -> void:
	_drag = {}
	_show_sell({})
	_hold.dragging = -1
	_hold.preview = {}
	_drag_layer.stop()
	_update_marks()


# --- Tooltip (SPEC Section 8.4) ---


func _on_hold_hovered(id: int) -> void:
	if id < 0 or not _drag.is_empty():
		_hide_tip()
	else:
		_show_tip(_cargo(id))


func _show_tip(c: Dictionary) -> void:
	if c.is_empty() or not _drag.is_empty():
		return
	var names: Dictionary = _view["names"]
	var lines := PackedStringArray()
	lines.append("[b]%s[/b]" % tr(c["name"]))
	var kind: String = c.get("kind", Defs.KIND_FREIGHT)
	(
		lines
		. append(
			(
				tr(TIP_WEIGHT_TEXT)
				. format(
					{
						"kind": tr(names["kinds"].get(kind, kind)),
						"weight": tr(names["weights"].get(c["weight"], c["weight"])),
						"value": c["weight_value"],
					}
				)
			)
		)
	)
	for t: String in c.get("traits", []):
		for term: Dictionary in _view["terms"]:
			if term["id"] == t:
				var color: Color = Palette.TRAIT_COLORS.get(t, Palette.TEXT)
				lines.append(
					(
						"[color=#%s]%s[/color]: %s"
						% [color.to_html(false), tr(term["name"]), GameText.format(term["rule"])]
					)
				)
	lines.append(tr(TIP_MASS_TEXT).format({"mass": c["mass"]}))
	if c.get("pay", 0) > 0:
		lines.append(tr(TIP_PAY_TEXT).format({"pay": c["pay"]}))
	if c.get("sell_price", 0) > 0:
		lines.append(tr(TIP_SELL_TEXT).format({"price": c["sell_price"]}))
	if c.get("clear_price", 0) > 0:
		lines.append(tr(TIP_CLEAR_TEXT).format({"price": c["clear_price"]}))
	if c.get("no_cooler", false):
		lines.append("[color=#%s]%s[/color]" % [Palette.WARN.to_html(false), tr(NO_COOLER_TEXT)])
	if c.get("no_power", false):
		lines.append("[color=#%s]%s[/color]" % [Palette.WARN.to_html(false), tr(NO_POWER_TEXT)])
	_tip_label.text = "\n".join(lines)
	_tip.visible = true
	_tip.reset_size()
	_place_tip()


func _place_tip() -> void:
	var p := get_global_mouse_position() + Vector2(18, 18)
	var max_p := size - _tip.size - Vector2(8, 8)
	_tip.position = Vector2(minf(p.x, max_p.x), minf(p.y, max_p.y))


func _hide_tip() -> void:
	_tip.visible = false


func _process(_delta: float) -> void:
	if _tip.visible:
		_place_tip()
