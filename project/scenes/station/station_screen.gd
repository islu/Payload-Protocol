class_name StationScreen
extends Control
## The station screen (SPEC Section 20.2): the top bar, the hazard, the dock,
## the contracts, the hold, the shop, the clamps, the sell area, the pilot, and
## the Warp button. It reads GameState.view() and calls the actions of GameState.

const DOCK_TEXT := "Dock"
const CONTRACTS_TEXT := "Contracts"
const SHOP_TEXT := "Shop"
const CLAMPS_TEXT := "Clamps"
const NEXT_JUMP_TEXT := "Next jump:"
const ACCEPT_TEXT := "Accept"
const CANCEL_TEXT := "Cancel"
const BUY_TEXT := "Buy"
const SOLD_TEXT := "Sold"
const REROLL_TEXT := "Reroll ({price} cr)"
const BUY_CLAMP_TEXT := "Buy a clamp ({price} cr)"
const ADD_COLUMN_TEXT := "Add a column ({price} cr)"
const ADD_ROW_TEXT := "Add a row ({price} cr)"
# gdlint:ignore = max-line-length
const SELL_AREA_TEXT := "Drop kit here to sell it.\nDrop scrap here to clear it ({price} cr for each cell)."
const WARP_TEXT := "WARP"
const TOP_BAR_TEXT := "Sector {sector}/{sectors} · Jump {jump}/{jumps}"
const CREDITS_TEXT := "Credits: {credits}"
const TOLL_TEXT := "Toll {toll} after {jumps} jump(s)"
# gdlint:ignore = max-line-length
const FREE_CLAMPS_TEXT := "{free} of {total} free. Drag a clamp onto a cargo. Click a clamp to take it off."
const PAY_TEXT := "Pay {pay} each"
const BONUS_TEXT := "Bonus +{pay}: {text}"
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
const SIDE_WIDTH := 470.0
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
var _hazard_box: HBoxContainer
var _dock_panel: PanelContainer
var _dock_flow: HFlowContainer
var _contracts_box: VBoxContainer
var _shop_box: VBoxContainer
var _clamp_box: HBoxContainer
var _clamp_label: Label
var _sell_area: PanelContainer
var _sell_label: Label
var _warp_button: Button
var _pilot_label: Label
var _tip: PanelContainer
var _tip_label: RichTextLabel
var _toast: Label
var _confirm: ConfirmationDialog
var _drag_layer: DragLayer


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
	_top_label = _label(top, "", 26)
	_credits_label = _label(top, "", 26, Palette.GOOD)
	_toll_label = _label(top, "", 22, Palette.TEXT_DIM)

	_hazard_box = HBoxContainer.new()
	_hazard_box.add_theme_constant_override("separation", 16)
	root.add_child(_hazard_box)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 20)
	root.add_child(body)

	var left := VBoxContainer.new()
	left.custom_minimum_size.x = SIDE_WIDTH
	left.add_theme_constant_override("separation", 10)
	body.add_child(left)
	_label(left, DOCK_TEXT, 22, Palette.ACCENT)
	_dock_panel = _panel(left)
	_dock_panel.custom_minimum_size.y = 200
	_dock_flow = HFlowContainer.new()
	_dock_flow.add_theme_constant_override("h_separation", 10)
	_dock_flow.add_theme_constant_override("v_separation", 10)
	_dock_panel.add_child(_dock_flow)
	_label(left, CONTRACTS_TEXT, 22, Palette.ACCENT)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	_contracts_box = VBoxContainer.new()
	_contracts_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contracts_box.add_theme_constant_override("separation", 10)
	scroll.add_child(_contracts_box)
	var pilot := _panel(left)
	_pilot_label = _label(pilot, "", 19, Palette.ACCENT)
	_pilot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(center)
	_hold = HoldView.new()
	_hold.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hold.cargo_pressed.connect(_on_hold_pressed)
	_hold.clamp_pressed.connect(func(id: int) -> void: _act(GameState.unclamp_cargo(id)))
	_hold.cargo_hovered.connect(_on_hold_hovered)
	center.add_child(_hold)
	var hint := _label(center, HINT_TEXT, 16, Palette.TEXT_DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var right := VBoxContainer.new()
	right.custom_minimum_size.x = SIDE_WIDTH
	right.add_theme_constant_override("separation", 10)
	body.add_child(right)
	_label(right, SHOP_TEXT, 22, Palette.ACCENT)
	_shop_box = VBoxContainer.new()
	_shop_box.add_theme_constant_override("separation", 8)
	right.add_child(_shop_box)
	_label(right, CLAMPS_TEXT, 22, Palette.ACCENT)
	_clamp_box = HBoxContainer.new()
	_clamp_box.add_theme_constant_override("separation", 8)
	right.add_child(_clamp_box)
	_clamp_label = _label(right, "", 15, Palette.TEXT_DIM)
	_clamp_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sell_area = _panel(right)
	_sell_area.custom_minimum_size.y = 110
	_sell_label = _label(_sell_area, "", 16, Palette.TEXT_DIM)
	_sell_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sell_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sell_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(spacer)
	_warp_button = Button.new()
	_warp_button.text = tr(WARP_TEXT)
	_warp_button.custom_minimum_size = Vector2(0, 90)
	_warp_button.add_theme_font_size_override("font_size", 40)
	_warp_button.pressed.connect(_on_warp_pressed)
	right.add_child(_warp_button)

	_confirm = ConfirmationDialog.new()
	_confirm.title = tr(CONFIRM_TITLE_TEXT)
	_confirm.confirmed.connect(func() -> void: _act(GameState.warp()))
	add_child(_confirm)

	_drag_layer = DragLayer.new()
	add_child(_drag_layer)

	_tip = PanelContainer.new()
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.visible = false
	_tip.z_index = 10
	_tip_label = RichTextLabel.new()
	_tip_label.bbcode_enabled = true
	_tip_label.fit_content = true
	_tip_label.custom_minimum_size.x = 360
	_tip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.add_child(_tip_label)
	add_child(_tip)

	_toast = Label.new()
	_toast.add_theme_color_override("font_color", Palette.BAD)
	_toast.add_theme_font_size_override("font_size", 22)
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
	_pilot_label.text = "PIP: " + tr(_run["line"])
	_hold.set_view(_run)
	_refresh_hazard()
	_refresh_dock()
	_refresh_contracts()
	_refresh_shop()
	_refresh_clamps()
	_update_marks()


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


func _refresh_hazard() -> void:
	_clear(_hazard_box)
	_label(_hazard_box, NEXT_JUMP_TEXT, 24, Palette.WARN)
	var arrows := {Defs.DIR_LEFT: "←", Defs.DIR_RIGHT: "→", Defs.DIR_UP: "↑", Defs.DIR_DOWN: "↓"}
	var i := 0
	for d: String in _run["hazard"]:
		if i > 0:
			_label(_hazard_box, "›", 24, Palette.TEXT_DIM)
		var name: String = _view["names"]["directions"].get(d, d)
		_label(_hazard_box, "%d. %s %s" % [i + 1, arrows.get(d, "?"), tr(name)], 28, Palette.WARN)
		i += 1


func _refresh_dock() -> void:
	_clear(_dock_flow)
	if _run["dock"].is_empty():
		_label(_dock_flow, EMPTY_DOCK_TEXT, 16, Palette.TEXT_DIM)
	for c: Dictionary in _run["cargo"]:
		if c["in_hold"]:
			continue
		var chip := CargoChip.new().setup(c, 34.0)
		chip.pressed.connect(
			func(_chip: CargoChip) -> void: _begin_cargo_drag(c["id"], Vector2.ZERO)
		)
		chip.mouse_entered.connect(func() -> void: _show_tip(c))
		chip.mouse_exited.connect(_hide_tip)
		_dock_flow.add_child(chip)


func _refresh_contracts() -> void:
	_clear(_contracts_box)
	for k: Dictionary in _run["contracts"]:
		var card := _panel(_contracts_box)
		var box := VBoxContainer.new()
		card.add_child(box)
		var head := HBoxContainer.new()
		box.add_child(head)
		var client := _label(head, "", 19, Palette.ACCENT if k["accepted"] else Palette.TEXT)
		client.text = tr(k["client_name"])
		client.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var index: int = k["index"]
		if k["accepted"]:
			_button(head, tr(CANCEL_TEXT), func() -> void: _act(GameState.cancel_contract(index)))
		else:
			_button(head, tr(ACCEPT_TEXT), func() -> void: _act(GameState.accept_contract(index)))
		var row := HFlowContainer.new()
		row.add_theme_constant_override("h_separation", 8)
		box.add_child(row)
		for f: Dictionary in k["freight"]:
			var chip := CargoChip.new().setup(f, 20.0)
			chip.mouse_filter = Control.MOUSE_FILTER_PASS
			chip.mouse_entered.connect(func() -> void: _show_tip(f))
			chip.mouse_exited.connect(_hide_tip)
			row.add_child(chip)
		_label(box, tr(PAY_TEXT).format({"pay": k["pay"]}), 16)
		if not k["bonus"].is_empty():
			var b: Dictionary = k["bonus"]
			var bonus := _label(box, "", 15, Palette.WARN)
			bonus.text = tr(BONUS_TEXT).format(
				{"pay": b["pay"], "text": GameText.format(b["text"])}
			)
			bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.mouse_entered.connect(func() -> void: _set_hover_contract(index))
		card.mouse_exited.connect(func() -> void: _set_hover_contract(-1))


func _refresh_shop() -> void:
	_clear(_shop_box)
	var s: Dictionary = _run["shop"]
	for o: Dictionary in s["offers"]:
		var card := _panel(_shop_box)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var chip := CargoChip.new().setup(o, 26.0)
		chip.mouse_entered.connect(func() -> void: _show_tip(o))
		chip.mouse_exited.connect(_hide_tip)
		row.add_child(chip)
		var name := _label(row, "", 18)
		name.text = "%s\n%d cr" % [tr(o["name"]), o["price"]]
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var index: int = o["index"]
		if o["bought"]:
			_button(row, tr(SOLD_TEXT), func() -> void: pass, false)
		else:
			_button(row, tr(BUY_TEXT), func() -> void: _act(GameState.buy_kit(index), "coin"))
	_button(
		_shop_box,
		tr(REROLL_TEXT).format({"price": s["reroll_price"]}),
		func() -> void: _act(GameState.reroll(), "coin")
	)
	_button(
		_shop_box,
		tr(BUY_CLAMP_TEXT).format({"price": s["clamp_price"]}),
		func() -> void: _act(GameState.buy_clamp(), "coin"),
		_run["clamps"] < s["clamp_max"]
	)
	var grow := HBoxContainer.new()
	_shop_box.add_child(grow)
	_button(
		grow,
		tr(ADD_COLUMN_TEXT).format({"price": s["upgrade_price"]}),
		func() -> void: _act(GameState.upgrade_hold(Defs.AXIS_COLUMN), "coin"),
		s["can_column"]
	)
	_button(
		grow,
		tr(ADD_ROW_TEXT).format({"price": s["upgrade_price"]}),
		func() -> void: _act(GameState.upgrade_hold(Defs.AXIS_ROW), "coin"),
		s["can_row"]
	)
	_sell_label.text = tr(SELL_AREA_TEXT).format({"price": s["scrap_cell"]})


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


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(1.6)
	t.tween_property(_toast, "modulate:a", 0.0, 0.4)


func _on_warp_pressed() -> void:
	if not _run["dock"].is_empty():
		_confirm.dialog_text = tr(CONFIRM_TEXT).format({"fee": _run["shop"]["breach_fee"]})
		_confirm.popup_centered()
		return
	_act(GameState.warp())


func _on_hold_pressed(id: int, grab: Vector2i, button: int) -> void:
	if not _drag.is_empty():
		return
	if button == MOUSE_BUTTON_RIGHT:
		_act(GameState.rotate_cargo(id), "clack")
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
	}
	_hold.dragging = id
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
	var mouse := get_global_mouse_position()
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
		_act(GameState.place_cargo(id, origin.x, origin.y, drag["rot"]), "clack")
	# A drop anywhere else leaves the cargo in its last place (SPEC Section 8.3).


func _end_drag() -> void:
	_drag = {}
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
