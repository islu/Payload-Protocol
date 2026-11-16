class_name StationScreen
extends Control
## The station screen (SPEC Section 20.2): the top bar, the hazard, the dock,
## the contracts, the hold, the shop, the clamps, the sell area, the pilot, and
## the Warp button. It reads GameState.view() and calls the actions of GameState.

const DOCK_TEXT := "Dock"
## The phases that show the station (SPEC Sections 20.2, 20.8, and 20.9).
const STATION_PHASES: PackedStringArray = [Defs.PHASE_STATION, Defs.PHASE_EVENT, Defs.PHASE_MOD]
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
# gdlint:ignore = max-line-length
const FREE_CLAMPS_TEXT := "{free} of {total} free. Drag a clamp onto a cargo. Click a clamp to take it off."
const EMPTY_DOCK_TEXT := "Empty. Accept a contract or buy kit."
const CONFIRM_TITLE_TEXT := "Cargo on the dock"
# gdlint:ignore = max-line-length
const CONFIRM_TEXT := "Cargo on the dock stays at the station.\nEach freight on the dock pays a breach fee of {fee} credits.\nEach kit on the dock is sold at half price.\nWarp now?"
# gdlint:ignore = max-line-length
const HINT_TEXT := "Drag cargo, or click to pick it up and click to drop it. Right click or R rotates it."
const OR_TEXT := "or"
const UNDO_TEXT := "Undo (Ctrl+Z)"
## The mark of a fork step that a Sensor shows (SPEC Section 20.2).
const SENSOR_TEXT := "Sensor"
## The characters of a pilot line that type out in each second (SPEC Section 22).
const TYPE_SPEED := 40.0
const ARROWS := {Defs.DIR_LEFT: "←", Defs.DIR_RIGHT: "→", Defs.DIR_UP: "↑", Defs.DIR_DOWN: "↓"}
const LOAD_ALL_TEXT := "Load all"
const SIDE_WIDTH := 470.0
const SELL_HEIGHT := 48.0
## The cell of the cargo on the dock (SPEC Section 20.2).
const DOCK_CELL := 48.0

var _view: Dictionary = {}
var _run: Dictionary = {}
## The drag of a cargo or a clamp (SPEC Sections 8.2, 8.3, and 13).
var _drag := StationDrag.new(self)
var _hover_contract := -1
## The credits that the top bar shows now. They count to the view (SPEC Section 21.4).
var _shown_credits := -1

var _hold: HoldView
## The shock bay above the hold (SPEC Section 31.2).
var _bay: HoldView
## The top bar: the leg, the credits, the mass, and the environment (SPEC Section 20.2).
var _top_bar: TopBar
## The warp checklist above the Warp button (SPEC Section 20.2).
var _checklist: WarpChecklist
## The credits of the top bar: the gold sparkle of a coin goes there (SPEC Section 21.4).
var _credits_label: Label
## The mod bar below the hold (SPEC Section 20.2).
var _mod_bar: ModBar
var _hazard_box: VBoxContainer
var _dock_title: Label
var _dock_panel: PanelContainer
var _dock_flow: HFlowContainer
var _contracts_box: VBoxContainer
var _contract_cards: Array[ContractCard] = []
## The shop: the kit offers and Reroll, then the services (SPEC Section 20.2).
var _shop: ShopPanel
var _services: ShopPanel
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
var _tip: CargoTip
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
	top.add_theme_constant_override("separation", 14)
	root.add_child(top)
	_top_bar = TopBar.new()
	top.add_child(_top_bar)
	_credits_label = _top_bar.credits_label

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
	var ship := VBoxContainer.new()
	ship.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ship.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ship.add_theme_constant_override("separation", 0)
	row.add_child(ship)
	# The shock bay hangs above the hold (SPEC Section 31.2).
	_bay = HoldView.new()
	_bay.bay = true
	_bay.visible = false
	_bay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bay.cargo_pressed.connect(_on_hold_pressed)
	_bay.cargo_hovered.connect(_on_hold_hovered)
	ship.add_child(_bay)
	_hold = HoldView.new()
	_hold.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hold.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hold.cargo_pressed.connect(_on_hold_pressed)
	_hold.clamp_pressed.connect(func(id: int) -> void: _act(GameState.unclamp_cargo(id)))
	_hold.cargo_hovered.connect(_on_hold_hovered)
	ship.add_child(_hold)
	# Below the hold: the mod bar, and the hint of the controls (SPEC Section 20.2).
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 16)
	center.add_child(bottom)
	_mod_bar = ModBar.new()
	bottom.add_child(_mod_bar)
	var hint := _label(bottom, HINT_TEXT, TextSize.SMALL, Palette.TEXT_DIM)
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var right := VBoxContainer.new()
	right.custom_minimum_size.x = SIDE_WIDTH
	right.add_theme_constant_override("separation", 10)
	body.add_child(right)
	_label(right, SHOP_TEXT, TextSize.HEADING, Palette.ACCENT)
	_shop = ShopPanel.new()
	_shop.screen = self
	right.add_child(_shop)
	_services = ShopPanel.new()
	_services.screen = self
	_services.show_services = true
	right.add_child(_services)
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
	_checklist = WarpChecklist.new()
	right.add_child(_checklist)
	# Undo takes back the last action at this station (SPEC Section 20.2).
	_undo_button = _button(right, tr(UNDO_TEXT), _undo, false)
	_warp_button = Button.new()
	_warp_button.text = tr(WARP_TEXT)
	_warp_button.custom_minimum_size = Vector2(0, 72)
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

	_tip = CargoTip.new()
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
	# The station shows behind an event and a mod choice (SPEC Sections 20.8 and 20.9).
	if _run.is_empty() or not _run["phase"] in STATION_PHASES:
		return
	_top_bar.set_view(_run)
	_checklist.set_view(_run)
	_count_credits(_run["credits"])
	# The Warp button does not work over the maximum mass (SPEC Section 25).
	_warp_button.disabled = _run["mass"]["hold"] > _run["mass"]["max"]
	_show_mods()
	_show_pilot()
	_undo_button.disabled = not GameState.can_undo()
	_hold.set_view(_run)
	_bay.set_view(_run)
	_refresh_hazard()
	_refresh_dock()
	_refresh_contracts()
	_shop.refresh()
	_services.refresh()
	_refresh_clamps()
	_update_marks()


## Shows the mod bar (SPEC Section 20.2).
func _show_mods() -> void:
	_mod_bar.set_mods(_run.get("mods", []), _set_hover_mod)


## Marks the area of the mod under the mouse on the hold, or none for "".
func _set_hover_mod(id: String) -> void:
	_hold.hover_mod = id
	_hold.queue_redraw()


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
	_top_bar.set_credits(value)


## Shows each step of the hazard. A fork step shows its two directions, or the one
## that happens when a Sensor is in the hold (SPEC Section 18).
func _refresh_hazard() -> void:
	_clear(_hazard_box)
	# The environment and the incident come before the shift steps (SPEC Sections 28.1 and 29.3).
	if not _run.get("environment", {}).is_empty():
		RouteCards.env_tag(_hazard_box, _run["environment"])
	if not _run.get("incident", {}).is_empty():
		RouteCards.incident_card(_hazard_box, _run["incident"])
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
		if c["in_hold"] or c["in_bay"]:
			continue
		var chip := CargoChip.new().setup(c, DOCK_CELL)
		chip.pressed.connect(
			func(chip: CargoChip) -> void: _drag.begin_cargo(c["id"], Vector2(chip.press_cell))
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
		chip.pressed.connect(func() -> void: _drag.begin_clamp())
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
	if _drag.is_active() and _drag.state["kind"] == "cargo":
		var c := _cargo(_drag.state["id"])
		if c.get("contract", -1) >= 0:
			var b: Dictionary = _run["contracts"][c["contract"]]["bonus"]
			if not b.is_empty():
				zone = b["zone"]
	_hold.marked = marked
	_hold.zone = zone
	_hold.queue_redraw()
	_bay.marked = marked
	_bay.queue_redraw()


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
	if _drag.is_active():
		return
	if button == MOUSE_BUTTON_RIGHT:
		var err := GameState.rotate_cargo(id)
		_act(err, "clack")
		if err == "":
			Hints.done(Hints.ROTATE)
	elif button == MOUSE_BUTTON_LEFT:
		_drag.begin_cargo(id, Vector2(grab))


# --- Input ---


## The input of the station. Esc puts back a held cargo first (StationDrag). Only
## then main opens the pause menu (SPEC Section 20.7).
func _input(event: InputEvent) -> void:
	if _drag.handle_input(event):
		get_viewport().set_input_as_handled()
	elif _drag.is_active():
		return
	elif event.is_action_pressed(&"ui_undo"):
		_undo()
		get_viewport().set_input_as_handled()


# --- Tooltip (SPEC Section 8.4) ---


func _on_hold_hovered(id: int) -> void:
	if id < 0 or _drag.is_active():
		_hide_tip()
	else:
		_show_tip(_cargo(id))


## Shows the tooltip of a cargo view, unless a drag is on (SPEC Section 8.4). The
## contract cards and the shop call it too.
func _show_tip(c: Dictionary) -> void:
	if not _drag.is_active():
		_tip.show_cargo(c, _view)


func _hide_tip() -> void:
	_tip.visible = false
