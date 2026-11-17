class_name ShopPanel
extends VBoxContainer
## The shop of the station: the kit offers, Reroll, and the services (SPEC Sections 17 and 20.2).

const BUY_TEXT := "Buy · {price} cr"
const SOLD_TEXT := "Sold"
const REROLL_TEXT := "Reroll ({price} cr)"
const SERVICES_TEXT := "Services"
const PRICE_TEXT := "{price} cr"
const CLAMP_SERVICE_TEXT := "Clamps {now}/{max} → {after}/{max}"
const BAY_SERVICE_TEXT := "Shock bay {now} → {after}"
const BAY_SIZE_TEXT := "{columns}×{rows}"
const BAY_NONE_TEXT := "none"
const BAY_MAX_TEXT := "Shock bay {now} (maximum)"
const HULL_SERVICE_TEXT := "Mass limit {now} → {after}"
## The cell of a kit image in the shop (SPEC Section 20.2).
const OFFER_CELL := 56.0

var screen: StationScreen
## What the panel shows: the kit offers and Reroll, or the services. The right
## column has one panel of each (SPEC Section 20.2).
var show_services := false
## The parts of each kit offer card, for the checks: {buy: Button, text: String}.
var offer_cards: Array = []
## The text of each service row, by service: clamp, hold, hull.
var service_texts: Dictionary = {}


func _init() -> void:
	add_theme_constant_override("separation", 8)


func refresh() -> void:
	var run: Dictionary = screen.run_data
	Ui.clear(self)
	var s: Dictionary = run["shop"]
	offer_cards.clear()
	if show_services:
		_build_services(s)
		return
	for o: Dictionary in s["offers"]:
		_offer_card(o)
	_price_button(
		self,
		tr(REROLL_TEXT).format({"price": s["reroll_price"]}),
		s["reroll_afford"],
		func() -> void: screen.act(GameState.reroll(), "coin")
	)


func _build_services(s: Dictionary) -> void:
	# Each service shows the value now and after the purchase (SPEC Section 20.2).
	Ui.label(self, SERVICES_TEXT, TextSize.HEADING, Palette.ACCENT)
	var box := Ui.panel(self)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	box.add_child(list)
	service_texts.clear()
	var clamp_text := tr(CLAMP_SERVICE_TEXT).format(
		{"now": s["clamps"], "after": s["clamps_after"], "max": s["clamp_max"]}
	)
	var clamp_row := _service_row(list, "clamp", clamp_text)
	_price_button(
		clamp_row,
		tr(PRICE_TEXT).format({"price": s["clamp_price"]}),
		s["clamp_afford"],
		func() -> void: screen.act(GameState.buy_clamp(), "coin"),
		s["can_buy_clamp"]
	)
	# The shock bay: none → 2×2 → 2×3 (SPEC Sections 17.2 and 31).
	var bay: Dictionary = s["bay"]
	if bay["after"].is_empty():
		_service_row(list, "bay", tr(BAY_MAX_TEXT).format({"now": _bay_size(bay["now"])}))
	else:
		var bay_text := tr(BAY_SERVICE_TEXT).format(
			{"now": _bay_size(bay["now"]), "after": _bay_size(bay["after"])}
		)
		_price_button(
			_service_row(list, "bay", bay_text),
			tr(PRICE_TEXT).format({"price": bay["price"]}),
			bay["afford"],
			func() -> void: screen.act(GameState.buy_shock_bay(), "coin")
		)
	var hull_text := tr(HULL_SERVICE_TEXT).format(
		{"now": s["mass_limit"], "after": s["mass_limit_after"]}
	)
	var hull_row := _service_row(list, "hull", hull_text)
	_price_button(
		hull_row,
		tr(PRICE_TEXT).format({"price": s["reinforce_price"]}),
		s["reinforce_afford"],
		func() -> void: screen.act(GameState.reinforce_hull(), "coin")
	)


func _bay_size(size: Dictionary) -> String:
	return tr(BAY_NONE_TEXT) if size.is_empty() else tr(BAY_SIZE_TEXT).format(size)


## A kit offer: its image, its traits with their rules, how it helps, and Buy (SPEC Section 20.2).
func _offer_card(o: Dictionary) -> void:
	var card := Ui.panel(self)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var chip := CargoChip.new().setup(o, OFFER_CELL)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.mouse_entered.connect(func() -> void: screen.show_tip(o))
	chip.mouse_exited.connect(screen.hide_tip)
	row.add_child(chip)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var text := PackedStringArray()
	var title := Ui.label(info, "", TextSize.BODY)
	title.text = tr(o["name"])
	text.append(title.text)
	for t: String in o["traits"]:
		var rule_text := GameText.trait_line(screen.view_data["terms"], t)
		if rule_text == "":
			continue
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 6)
		info.add_child(line)
		line.add_child(trait_icon(t))
		var rule := Ui.label(line, "", TextSize.SMALL, Palette.TEXT_DIM)
		rule.text = rule_text
		rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.append(rule.text)
	if not o["helps"].is_empty():
		var helps := Ui.label(info, "", TextSize.SMALL, Palette.GOOD)
		helps.text = GameText.format(o["helps"])
		text.append(helps.text)
	var buy: Button
	if o["bought"]:
		buy = screen.add_button(info, tr(SOLD_TEXT), func() -> void: pass, false)
	else:
		var index: int = o["index"]
		buy = _price_button(
			info,
			tr(BUY_TEXT).format({"price": o["price"]}),
			o["afford"],
			func() -> void: screen.act(GameState.buy_kit(index), "coin")
		)
	buy.size_flags_horizontal = Control.SIZE_SHRINK_END
	offer_cards.append({"buy": buy, "text": "\n".join(text)})


## A button with a price. A price that is more than the credits shows in red (SPEC Section 20.2).
func _price_button(
	parent: Control, text: String, afford: bool, action: Callable, enabled := true
) -> Button:
	var b := screen.add_button(parent, text, action, enabled)
	if not afford:
		b.add_theme_color_override("font_color", Palette.BAD)
		b.add_theme_color_override("font_hover_color", Palette.BAD)
	return b


## A row of a service with its text. It returns the row, for a price button.
func _service_row(parent: Control, key: String, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var l := Ui.label(row, "", TextSize.BODY)
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	service_texts[key] = text
	return row


## A small square with the icon of a trait.
static func trait_icon(trait_id: String) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(18, 18)
	c.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var color: Color = Palette.trait_color(trait_id)
	c.draw.connect(func() -> void: CargoDraw.draw_icon(c, trait_id, Vector2(9, 9), 16.0, color))
	return c
