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
const SELL_IDLE_TEXT := "Sell kit or clear scrap: drop it here"
const SELL_KIT_TEXT := "Sell {name}: +{price} cr"
const CLEAR_SCRAP_TEXT := "Clear the scrap: -{price} cr"
const NO_SELL_TEXT := "Freight cannot be sold"
const WARP_TEXT := "LAUNCH"
# gdlint:ignore = max-line-length
const FREE_CLAMPS_TEXT := "{free} of {total} free"
const CLAMP_HELP_TEXT := "Drag a clamp onto a cargo. Click a clamp to take it off."
const EMPTY_DOCK_TEXT := "Empty. Accept a contract or buy kit."
const CONFIRM_TITLE_TEXT := "Cargo on the dock"
# gdlint:ignore = max-line-length
const CONFIRM_TEXT := "Cargo on the dock stays at the station.\nEach freight on the dock pays a breach fee of {fee} credits.\nEach kit on the dock is sold at half price.\nWarp now?"
# gdlint:ignore = max-line-length
const HINT_TEXT := "Drag cargo, or click to pick it up and click to drop it. Right click or R rotates it."
const OR_TEXT := "or"
const UNDO_TEXT := "Undo (Ctrl+Z)"
## The mark of a fork step that a Sensor shows (SPEC Section 20.2).
## The warning when the last Sensor leaves the hold (SPEC Section 18.1).
const SENSOR_LOST_TEXT := "No Sensor: the fork step is hidden again."
## The characters of a pilot line that type out in each second (SPEC Section 22).
const TYPE_SPEED := 40.0
const ARROWS := {Defs.DIR_LEFT: "←", Defs.DIR_RIGHT: "→", Defs.DIR_UP: "↑", Defs.DIR_DOWN: "↓"}
const LOAD_ALL_TEXT := "Load all"
const SIDE_WIDTH := 486.0
const SELL_HEIGHT := 48.0
## The cell of the cargo on the dock (SPEC Section 20.2).
const DOCK_CELL := 48.0

## The sell area with no drag (SPEC Section 20.2).
const SELL_IDLE := "idle"
## The view of the state now, and its run part (GameState.view()).
var view_data: Dictionary = {}
var run_data: Dictionary = {}
var hold_view: HoldView
## The shock bay above the hold (SPEC Section 31.2).
var bay_view: HoldView
var dock_panel: PanelContainer
var sell_area: PanelContainer
## The cargo or the clamp of the drag, at the mouse (SPEC Section 8.2).
var drag_layer: DragLayer

## The route bar above the hold (SPEC Section 20.2).
var route_bar: RouteBar
## The view part of each list when it was built, by the name of the list (_changed).
var _built := {}
## The station of the last refresh and whether its fork step was known: [leg, jump, known].
var _fork_seen := []
## The drag of a cargo or a clamp (SPEC Sections 8.2, 8.3, and 13).
var _drag := StationDrag.new(self)
var _hover_contract := -1
## The credits that the top bar shows now. They count to the view (SPEC Section 21.4).
var _shown_credits := -1
## The tween that counts the credits, while it runs.
var _credits_tween: Tween
## The top bar: the leg, the credits, the mass, and the environment (SPEC Section 20.2).
var _top_bar: TopBar
## The warp checklist above the Warp button (SPEC Section 20.2).
var _checklist: WarpChecklist
## The credits of the top bar: the gold sparkle of a coin goes there (SPEC Section 21.4).
var _credits_label: Label
## The mod bar below the hold (SPEC Section 20.2).
var _mod_bar: ModBar
var _dock_title: Label
var _dock_flow: HFlowContainer
var _contracts_box: VBoxContainer
var _contract_cards: Array[ContractCard] = []
## The shop: the kit offers and Reroll, then the services (SPEC Section 20.2).
var _shop: ShopPanel
var _services: ShopPanel
var _clamp_box: HBoxContainer
var _clamp_label: Label
var _sell_label: Label
## What the sell area shows now: SELL_IDLE with no drag, or the sell_action of the
## dragged cargo ("" when it cannot go there) (SPEC Section 20.2).
var _sell_mode := SELL_IDLE
var _warp_button: Button
var _undo_button: Button
var _pilot_label: Label
var _pilot_face: PilotFace
## The pilot panel and the row under the hold. The tutorial hides them: its guide has the pilot.
var _pilot_panel: PanelContainer
var _bottom_row: HBoxContainer
var _type_tween: Tween
var _tip: CargoTip
var _toast: Label
var _confirm: ConfirmationDialog
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
	_env_tip_on(_top_bar.env_badge)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	root.add_child(body)

	var left := VBoxContainer.new()
	left.custom_minimum_size.x = SIDE_WIDTH
	left.add_theme_constant_override("separation", 10)
	body.add_child(left)
	var dock_head := HBoxContainer.new()
	left.add_child(dock_head)
	_dock_title = Ui.label(dock_head, DOCK_TEXT, TextSize.HEADING, Palette.ACCENT)
	_dock_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_button(dock_head, tr(LOAD_ALL_TEXT), func() -> void: act(GameState.load_all(), "clack"))
	# The dock fits its cargo. An empty dock is one line (SPEC Section 20.2).
	dock_panel = Ui.panel(left)
	_dock_flow = HFlowContainer.new()
	_dock_flow.add_theme_constant_override("h_separation", 10)
	_dock_flow.add_theme_constant_override("v_separation", 10)
	dock_panel.add_child(_dock_flow)
	Ui.label(left, CONTRACTS_TEXT, TextSize.HEADING, Palette.ACCENT)
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
	_pilot_panel = Ui.panel(left)
	_pilot_panel.add_child(pilot)
	_pilot_face = PilotFace.new()
	pilot.add_child(_pilot_face)
	_pilot_label = Ui.label(pilot, "", TextSize.BODY, Palette.ACCENT)
	_pilot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pilot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pilot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 8)
	body.add_child(center)
	# The route bar: the next jump as a route, above the hold (SPEC Section 20.2).
	route_bar = RouteBar.new()
	route_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	route_bar.step_hovered.connect(_set_hover_step)
	center.add_child(route_bar)
	# The shock bay is at the left of the hold (SPEC Section 31.2).
	var ship := HBoxContainer.new()
	ship.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ship.alignment = BoxContainer.ALIGNMENT_CENTER
	# The coupling of the shock bay goes into the free margin of the hold.
	ship.add_theme_constant_override("separation", -int(HoldView.MARGIN * HoldView.CELL / 2.0))
	center.add_child(ship)
	bay_view = HoldView.new()
	bay_view.bay = true
	bay_view.visible = false
	# The hold and the shock bay are right below the route bar, so that the guide of
	# the tutorial does not cover the hold (SPEC Section 23.4).
	bay_view.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bay_view.cargo_pressed.connect(_on_hold_pressed)
	bay_view.cargo_hovered.connect(_on_hold_hovered)
	ship.add_child(bay_view)
	hold_view = HoldView.new()
	hold_view.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hold_view.cargo_pressed.connect(_on_hold_pressed)
	hold_view.clamp_pressed.connect(func(id: int) -> void: act(GameState.unclamp_cargo(id)))
	hold_view.cargo_hovered.connect(_on_hold_hovered)
	ship.add_child(hold_view)
	# Below the hold: the mod bar, and the hint of the controls (SPEC Section 20.2).
	var bottom := HBoxContainer.new()
	_bottom_row = bottom
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 16)
	center.add_child(bottom)
	_mod_bar = ModBar.new()
	bottom.add_child(_mod_bar)
	var hint := Ui.label(bottom, HINT_TEXT, TextSize.SMALL, Palette.TEXT_DIM)
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var right := VBoxContainer.new()
	right.custom_minimum_size.x = SIDE_WIDTH
	right.add_theme_constant_override("separation", 10)
	body.add_child(right)
	Ui.label(right, SHOP_TEXT, TextSize.HEADING, Palette.ACCENT)
	_shop = ShopPanel.new()
	_shop.screen = self
	right.add_child(_shop)
	_services = ShopPanel.new()
	_services.screen = self
	_services.show_services = true
	right.add_child(_services)
	Ui.label(right, CLAMPS_TEXT, TextSize.HEADING, Palette.ACCENT)
	# The free clamps and their count are on one row. The mouse on them shows how to
	# use a clamp in the tip (SPEC Sections 4.2 and 13).
	var clamp_row := HBoxContainer.new()
	clamp_row.add_theme_constant_override("separation", 12)
	clamp_row.mouse_filter = Control.MOUSE_FILTER_PASS
	clamp_row.mouse_entered.connect(
		func() -> void: show_text_tip(tr(CLAMPS_TEXT), PackedStringArray([tr(CLAMP_HELP_TEXT)]))
	)
	clamp_row.mouse_exited.connect(hide_tip)
	right.add_child(clamp_row)
	_clamp_box = HBoxContainer.new()
	_clamp_box.add_theme_constant_override("separation", 8)
	clamp_row.add_child(_clamp_box)
	_clamp_label = Ui.label(clamp_row, "", TextSize.SMALL, Palette.TEXT_DIM)
	_clamp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# The sell area is a small bar. A drag colors it (SPEC Section 20.2).
	sell_area = Ui.panel(right)
	sell_area.custom_minimum_size.y = SELL_HEIGHT
	_sell_label = Ui.label(sell_area, "", TextSize.SMALL, Palette.TEXT_DIM)
	_sell_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sell_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	show_sell({})
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(spacer)
	_checklist = WarpChecklist.new()
	right.add_child(_checklist)
	# Undo takes back the last action at this station (SPEC Section 20.2).
	_undo_button = add_button(right, tr(UNDO_TEXT), _undo, false)
	_warp_button = Button.new()
	_warp_button.text = tr(WARP_TEXT)
	_warp_button.custom_minimum_size = Vector2(0, 72)
	TextSize.display(_warp_button, 40)
	_warp_button.pressed.connect(_on_warp_pressed)
	right.add_child(_warp_button)

	_confirm = ConfirmationDialog.new()
	TextSize.apply_to_dialog(_confirm)
	_confirm.title = tr(CONFIRM_TITLE_TEXT)
	_confirm.confirmed.connect(func() -> void: act(GameState.warp()))
	add_child(_confirm)

	drag_layer = DragLayer.new()
	drag_layer.hold = hold_view
	add_child(drag_layer)
	_fx = FxLayer.new()
	_fx.hold = hold_view
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


func add_button(parent: Control, text: String, action: Callable, enabled := true) -> Button:
	var b := Button.new()
	b.text = text
	b.disabled = not enabled
	b.add_theme_font_size_override("font_size", TextSize.BUTTON)
	b.pressed.connect(action)
	parent.add_child(b)
	return b


# --- Refresh from the view ---


func refresh() -> void:
	view_data = GameState.view()
	run_data = view_data["run"]
	# The station shows behind an event and a mod choice (SPEC Sections 20.8 and 20.9).
	if run_data.is_empty() or not run_data["phase"] in STATION_PHASES:
		return
	_top_bar.set_view(run_data)
	_checklist.set_view(run_data)
	# The guide of the tutorial has the pilot and covers the row under the hold (SPEC Section 23.4).
	var tutorial: bool = not view_data.get("tutorial", {}).is_empty()
	_pilot_panel.visible = not tutorial
	_bottom_row.visible = not tutorial
	_check_sensor_lost()
	_count_credits(run_data["credits"])
	# The Warp button does not work over the maximum mass (SPEC Section 25).
	_warp_button.disabled = not run_data["can_warp"]
	show_pilot()
	_undo_button.disabled = not GameState.can_undo()
	hold_view.set_view(run_data)
	bay_view.set_view(run_data)
	# Each list is built again only when its part of the view changed: a cargo move
	# changes only some of them.
	if _changed("mods", run_data.get("mods", [])):
		_show_mods()
	var incident: Dictionary = run_data.get("incident", {})
	if _changed("hazard", [run_data.get("environment", {}), incident, run_data["hazard"]]):
		_refresh_hazard()
	if _changed("dock", run_data["cargo"].filter(_on_dock)):
		_refresh_dock()
	if _changed("contracts", [run_data["contracts"], run_data["mass"]]):
		_refresh_contracts()
	if _changed("shop", [run_data["shop"], view_data["terms"]]):
		_shop.refresh()
		_services.refresh()
	if _changed("clamps", [run_data["free_clamps"], run_data["clamps"]]):
		_refresh_clamps()
	update_marks()


## Reports whether the view part of a list changed since the list was built. The
## language is a part too: a list has translated text.
func _changed(list: String, part: Variant) -> bool:
	var key := [TranslationServer.get_locale(), part]
	if _built.get(list) == key:
		return false
	_built[list] = key
	return true


static func _on_dock(c: Dictionary) -> bool:
	return not c["in_hold"] and not c["in_bay"]


## Shows the mod bar (SPEC Section 20.2).
func _show_mods() -> void:
	_mod_bar.set_mods(run_data.get("mods", []), _set_hover_mod)


## Marks the area of the mod under the mouse on the hold, and shows its name and its
## rule in the tip. {} marks none (SPEC Section 20.2).
func _set_hover_mod(m: Dictionary) -> void:
	hold_view.hover_mod = m.get("id", "")
	hold_view.queue_redraw()
	if m.is_empty():
		hide_tip()
	else:
		show_text_tip(tr(m["name"]), PackedStringArray([GameText.format(m["text"])]))


## Shows the hint of the first runs in the pilot box, or the line of the pilot (SPEC Section 23.3).
func show_pilot() -> void:
	# The tutorial has its own guide: no hints in it (SPEC Section 23.4).
	var hint := Hints.current(run_data) if view_data.get("tutorial", {}).is_empty() else ""
	var text := ""
	if hint == "":
		text = GameText.pilot_name() + ": " + tr(run_data["line"])
		_pilot_label.add_theme_color_override("font_color", Palette.ACCENT)
	else:
		# The font has "→" (tools/i18n/glyphs.py checks each character).
		text = GameText.pilot_name() + " → " + tr(Hints.text(hint))
		_pilot_label.add_theme_color_override("font_color", Palette.WARN)
	if text != _pilot_label.text:
		_pilot_label.text = text
		_type_line()


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
	if target == _shown_credits and _credits_tween == null:
		return
	if _credits_tween != null:
		_credits_tween.kill()
	_credits_tween = create_tween()
	_credits_tween.finished.connect(func() -> void: _credits_tween = null)
	var t := _credits_tween
	t.tween_method(
		func(v: float) -> void: _set_credits(roundi(v)), float(_shown_credits), float(target), 0.4
	)


func _set_credits(value: int) -> void:
	_shown_credits = value
	_top_bar.set_credits(value)


## Shows the route of the next jump on the route bar. A fork step shows its two
## directions, or the one that a Sensor shows (SPEC Sections 18 and 20.2).
func _refresh_hazard() -> void:
	route_bar.set_route(
		run_data.get("environment", {}), run_data.get("incident", {}), run_data["hazard"], view_data
	)
	if route_bar.env_band != null:
		_env_tip_on(route_bar.env_band)


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
		return {"arrow": arrow + "?", "names": or_join(names), "sensor": false}
	return {
		"arrow": ARROWS.get(step["known"], "?"),
		"names": direction_name(step["known"], view),
		"sensor": step["fork"],
	}


## Marks the front wall of a step in the hold, or of the first step for -1. The
## wall jolt warnings are for the first step only (SPEC Sections 12.3 and 20.2).
func _set_hover_step(index: int) -> void:
	var hazard: Array = run_data.get("hazard", [])
	if index < 0 or index >= hazard.size():
		hold_view.show_front_walls(PackedStringArray([run_data.get("front_wall", "")]), true)
		return
	var step: Dictionary = hazard[index]
	var walls := PackedStringArray(step["directions"] if step["known"] == "" else [step["known"]])
	hold_view.show_front_walls(walls, index == 0)


## Returns the arrow and the name of a direction.
## Joins the names of the directions of a fork step with "or".
static func or_join(names: PackedStringArray) -> String:
	return (" %s " % TranslationServer.translate(OR_TEXT)).join(names)


static func direction_text(d: String, view: Dictionary) -> String:
	return "%s %s" % [ARROWS.get(d, "?"), direction_name(d, view)]


## Returns the translated name of a direction.
static func direction_name(d: String, view: Dictionary) -> String:
	return TranslationServer.translate(view["names"]["directions"].get(d, d))


func _refresh_dock() -> void:
	Ui.clear(_dock_flow)
	_dock_title.text = tr(DOCK_COUNT_TEXT).format({"count": run_data["dock"].size()})
	if run_data["dock"].is_empty():
		Ui.label(_dock_flow, EMPTY_DOCK_TEXT, TextSize.SMALL, Palette.TEXT_DIM)
	for c: Dictionary in run_data["cargo"]:
		if c["in_hold"] or c["in_bay"]:
			continue
		var chip := CargoChip.new().setup(c, DOCK_CELL)
		chip.pressed.connect(
			func(chip: CargoChip) -> void: _drag.begin_cargo(c["id"], Vector2(chip.press_cell))
		)
		chip.mouse_entered.connect(func() -> void: show_tip(c))
		chip.mouse_exited.connect(hide_tip)
		_dock_flow.add_child(chip)


func _refresh_contracts() -> void:
	Ui.clear(_contracts_box)
	_contract_cards.clear()
	for k: Dictionary in run_data["contracts"]:
		var card := ContractCard.new()
		_contracts_box.add_child(card)
		card.setup(self, k)
		_contract_cards.append(card)


## Shows the sell area for a dragged cargo view, or idle for {} (SPEC Section 20.2).
func show_sell(c: Dictionary) -> void:
	var color := Palette.PANEL_LINE
	_sell_mode = SELL_IDLE
	_sell_label.text = tr(SELL_IDLE_TEXT)
	_sell_label.add_theme_color_override("font_color", Palette.TEXT_DIM)
	if not c.is_empty():
		_sell_mode = c.get("sell_action", "")
		match _sell_mode:
			Defs.ACT_SELL_KIT:
				color = Palette.GOOD
				_sell_label.text = tr(SELL_KIT_TEXT).format(
					{"name": tr(c["name"]), "price": c.get("sell_price", 0)}
				)
			Defs.ACT_CLEAR_SCRAP:
				color = Palette.BAD
				_sell_label.text = tr(CLEAR_SCRAP_TEXT).format({"price": c.get("clear_price", 0)})
			_:
				_sell_label.text = tr(NO_SELL_TEXT)
		if _sell_mode != "":
			_sell_label.add_theme_color_override("font_color", color)
	var style: StyleBoxFlat = sell_area.get_theme_stylebox("panel").duplicate()
	style.border_color = color
	style.bg_color = Palette.PANEL if _sell_mode in [SELL_IDLE, ""] else Color(color, 0.15)
	sell_area.add_theme_stylebox_override("panel", style)


func _refresh_clamps() -> void:
	Ui.clear(_clamp_box)
	for i in run_data["free_clamps"]:
		var chip := ClampChip.new()
		chip.pressed.connect(func() -> void: _drag.begin_clamp())
		_clamp_box.add_child(chip)
	_clamp_label.text = tr(FREE_CLAMPS_TEXT).format(
		{"free": run_data["free_clamps"], "total": run_data["clamps"]}
	)


func set_hover_contract(index: int) -> void:
	_hover_contract = index
	update_marks()


## Marks the freight of the contract under the mouse, and the zone of its bonus (SPEC Section 20.2).
func update_marks() -> void:
	var marked := []
	var zone := []
	if _hover_contract >= 0 and _hover_contract < run_data["contracts"].size():
		for c: Dictionary in run_data["cargo"]:
			if c["contract"] == _hover_contract:
				marked.append(c["id"])
		var b: Dictionary = run_data["contracts"][_hover_contract]["bonus"]
		if not b.is_empty():
			zone = b["zone"]
	# A drag of the freight of a zone contract shows the zone (SPEC Section 15.3).
	if _drag.is_active() and _drag.state["kind"] == "cargo":
		var c := cargo_view(_drag.state["id"])
		if c.get("contract", -1) >= 0:
			var b: Dictionary = run_data["contracts"][c["contract"]]["bonus"]
			if not b.is_empty():
				zone = b["zone"]
	hold_view.marked = marked
	hold_view.zone = zone
	hold_view.queue_redraw()
	bay_view.marked = marked
	bay_view.queue_redraw()


func cargo_view(id: int) -> Dictionary:
	for c: Dictionary in run_data.get("cargo", []):
		if c["id"] == id:
			return c
	return {}


# --- Actions ---


## Shows the error of an action and plays the deny sound, or plays ok_sound when it works.
func act(err: String, ok_sound := "") -> void:
	if err != "":
		_show_toast(tr(err))
		Sound.play(self, "deny")
	elif ok_sound != "":
		Sound.play(self, ok_sound)
		if ok_sound == "coin":
			_fx.coin(_credits_label.get_global_rect().get_center())


## Takes back the last action at this station (SPEC Section 20.2).
func _undo() -> void:
	# Only the target of a tutorial step works (SPEC Section 23.4).
	if not view_data.get("tutorial", {}).is_empty():
		return
	act(GameState.undo())


## Returns the areas that a tutorial step opens on the station (SPEC Section 23.4). A
## try step opens the hold, the dock, the shock bay, the clamps, and the Warp button.
func tutorial_rects(step: Dictionary) -> Array[Rect2]:
	var t: Dictionary = step.get("target", {})
	var parts: Array[Control] = []
	if step.get("try", false):
		parts = [hold_view, bay_view, dock_panel, _clamp_box, _warp_button]
	else:
		match str(t.get("kind", "")):
			"contract":
				var i: int = t.get("index", 0)
				if i < _contract_cards.size():
					parts = [_contract_cards[i]]
			"cargo":
				parts = [hold_view, bay_view, dock_panel]
			"clamps":
				parts = [_clamp_box, hold_view]
			"shop":
				var i: int = t.get("index", 0)
				if i < _shop.offer_cards.size():
					parts = [_shop.offer_cards[i]["buy"]]
			"hazard":
				parts = [route_bar]
			"top_bar":
				parts = [_top_bar]
			"button":
				if t.get("button", "") == Defs.ACT_WARP:
					parts = [_warp_button]
	var out: Array[Rect2] = []
	for c in parts:
		if c != null and c.is_visible_in_tree():
			out.append(c.get_global_rect())
	return out


## Warns when a known fork step is hidden again at the same station: the last Sensor
## left the hold (SPEC Section 18.1). A new station does not warn.
func _check_sensor_lost() -> void:
	var hazard: Array = run_data["hazard"]
	var known: bool = not hazard.is_empty() and hazard[-1]["fork"] and hazard[-1]["known"] != ""
	var at := [run_data["leg"], run_data["jump"]]
	if _fork_seen.size() == 3 and _fork_seen.slice(0, 2) == at and _fork_seen[2] and not known:
		_show_toast(tr(SENSOR_LOST_TEXT))
	_fork_seen = at + [known]


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(1.6)
	t.tween_property(_toast, "modulate:a", 0.0, 0.4)


func _on_warp_pressed() -> void:
	# The hint of this station ends at the warp (SPEC Section 23.3).
	Hints.done(Hints.current(run_data))
	if not run_data["dock"].is_empty():
		_confirm.dialog_text = tr(CONFIRM_TEXT).format({"fee": run_data["shop"]["breach_fee"]})
		_confirm.popup_centered()
		return
	act(GameState.warp())


func _on_hold_pressed(id: int, grab: Vector2i, button: int) -> void:
	if _drag.is_active():
		return
	if button == MOUSE_BUTTON_RIGHT:
		var err := GameState.rotate_cargo(id)
		act(err, "clack")
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
		hide_tip()
	else:
		show_tip(cargo_view(id))


## Shows the tooltip of a cargo view, unless a drag is on (SPEC Section 8.4). The
## contract cards and the shop call it too.
func show_tip(c: Dictionary) -> void:
	if not _drag.is_active():
		_tip.show_cargo(c, view_data)


## Shows the environment of the leg in the tip while the mouse is on a control: its
## name and its rule, from the view at that time (SPEC Section 28.1).
func _env_tip_on(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_STOP
	control.mouse_entered.connect(_show_env_tip)
	control.mouse_exited.connect(hide_tip)


func _show_env_tip() -> void:
	var env: Dictionary = run_data.get("environment", {})
	if not env.is_empty():
		show_text_tip(tr(env["name"]), PackedStringArray([tr(env["text"])]))


## Shows the tip with a title and lines of text, when no drag is active (SPEC Section 20.2).
func show_text_tip(title: String, lines: PackedStringArray) -> void:
	if not _drag.is_active():
		_tip.show_text(title, lines)


func hide_tip() -> void:
	_tip.visible = false
