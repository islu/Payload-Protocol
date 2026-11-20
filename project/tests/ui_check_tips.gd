class_name UiCheckTips
extends RefCounted
## The checks of the tooltips for ui_check.gd (SPEC Section 20.10).


## The keyboard focus on a button shows the tooltip of its card. A control that the
## player can only read has a question mark cursor.
static func station(ui: Node, station: StationScreen) -> void:
	station.hide_tip()
	if not station._shop.offer_cards.is_empty():
		var o: Dictionary = station.run_data["shop"]["offers"][0]
		station._shop.offer_cards[0]["buy"].focus_entered.emit()
		ui._check(
			station._tip.visible and ui.tr(o["name"]) in station._tip.text(),
			"the focus on a Buy button shows the tooltip of its kit (SPEC Section 20.10)"
		)
		station.hide_tip()
	if not station._contract_cards.is_empty():
		var card: ContractCard = station._contract_cards[0]
		card.button.focus_entered.emit()
		ui._check(
			station._tip.visible and ui.tr(card._title) in station._tip.text(),
			"the focus on a contract button shows the details of the card (SPEC Section 20.10)"
		)
		station.hide_tip()
	var read_only: Array[Control] = [station._top_bar.env_badge, station._clamp_row]
	read_only.append_array(station._mod_bar.cards)
	var band := station.route_bar.env_band
	if band != null:
		read_only.append(band)
	for c in read_only:
		(
			ui
			. _check(
				not c.visible or c.mouse_default_cursor_shape == Control.CURSOR_HELP,
				(
					"a control that the player can only read has a question mark cursor: %s (SPEC Section 20.10)"
					% c.name
				)
			)
		)
	if not station._shop.offer_cards.is_empty():
		ui._check(
			station._shop.offer_cards[0]["buy"].mouse_default_cursor_shape != Control.CURSOR_HELP,
			"a button keeps its cursor (SPEC Section 20.10)"
		)
