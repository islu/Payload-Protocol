class_name ContractCard
extends PanelContainer
## A contract card of the station (SPEC Section 20.2). The first line has the client,
## the total pay, and the mass. The second line has the freight groups and the bonus.
## The mouse on the card shows the details in the tip of the station: the pieces, the
## pay for each piece, the rules of the traits, and the mass after it is accepted.

const ACCEPT_TEXT := "Accept"
const CANCEL_TEXT := "Cancel"
const COUNT_TEXT := "×{count}"
const PAY_TEXT := "{total} cr"
const MASS_TEXT := "Mass {mass}"
const TOTALS_TEXT := "{pieces} pieces · Pay {pay} each · Total {total}"
const MASS_OK_TEXT := "Mass {mass} · After {after}/{limit}"
const MASS_FEE_TEXT := "Mass {mass} · After {after}/{limit} (fuel fee)"
const MASS_OVER_TEXT := "Mass {mass} · After {after}/{limit} (too heavy)"
const LOADED_TEXT := "Loaded {loaded}/{pieces}"
const BONUS_TEXT := "Bonus +{pay}: {text}"
const BONUS_TAG_TEXT := "Bonus +{pay}"
const VIP_TEXT := "VIP · Penalty {penalty} if a piece is not delivered"
const VIP_TAG_TEXT := "VIP"
## The text of each tag of a contract, and its color (SPEC Section 30.4).
const TAG_TEXT := {Defs.TAG_BLACK_MARKET: "Black Market"}
const TAG_COLOR := {Defs.TAG_BLACK_MARKET: Palette.BLACK_MARKET}
const LONG_TEXT := "Long · Delivered after {jumps} jumps"
const LONG_TAG_TEXT := "Long · {jumps}"
const ON_ITS_WAY_TEXT := "On its way · {jumps} jump(s) left"
## The cell of a freight image: a 1 cell freight, and a larger one.
const GROUP_CELL := 36.0
const GROUP_CELL_LARGE := 22.0

## The text of the card, for the checks: all the text on the card.
var text := ""
## The text of the first line, for the checks.
var first_line := ""
## The color of the mass: Palette.TEXT_DIM, WARN, or BAD.
var mass_color := Palette.TEXT_DIM
var screen: StationScreen
## The title and the lines of the tip of the card (SPEC Section 20.2).
var _title := ""
var _details := PackedStringArray()


func setup(station: StationScreen, k: Dictionary) -> void:
	screen = station
	var style := Ui.panel_style(
		Palette.ACCENT if k["accepted"] else Palette.PANEL_LINE, 3 if k["accepted"] else 2
	)
	add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	var details := PackedStringArray()
	var head := _first_line(box, k, details)
	var second := _groups(box, k["groups"])
	var tags := PackedStringArray()
	# The state of an accepted contract is on the second line, so that the name of
	# the client fits on the first line (SPEC Sections 4.2 and 20.2).
	if k.get("carried", false):
		tags.append(
			_tag(second, tr(ON_ITS_WAY_TEXT).format({"jumps": k["jumps_left"]}), Palette.ACCENT)
		)
	elif k["accepted"]:
		tags.append(_tag(second, tr(LOADED_TEXT).format(k), Palette.ACCENT))
	if not k["bonus"].is_empty():
		var b: Dictionary = k["bonus"]
		tags.append(_tag(second, tr(BONUS_TAG_TEXT).format(b), Palette.WARN))
		details.append(tr(BONUS_TEXT).format({"pay": b["pay"], "text": GameText.format(b["text"])}))
	# The marks of a special contract (SPEC Section 30).
	if k.get("penalty", 0) > 0:
		tags.append(_tag(second, tr(VIP_TAG_TEXT), RouteCards.INCIDENT_COLOR))
		details.append(tr(VIP_TEXT).format({"penalty": k["penalty"]}))
	if k.get("jumps", 1) > 1 and not k.get("carried", false):
		tags.append(_tag(second, tr(LONG_TAG_TEXT).format(k), RouteCards.INCIDENT_COLOR))
		details.append(tr(LONG_TEXT).format({"jumps": k["jumps"]}))
	if (k.get("penalty", 0) > 0 or k.get("jumps", 1) > 1) and not k["accepted"]:
		style.border_color = RouteCards.INCIDENT_COLOR
	# The tags of the look: a black market contract is purple (SPEC Section 30.4).
	for tag: String in k.get("tags", []):
		tags.append(_tag(second, tr(TAG_TEXT[tag]), TAG_COLOR[tag]))
		if not k["accepted"]:
			style.border_color = TAG_COLOR[tag]
	details.append_array(_trait_rules(k["groups"]))
	var counts := PackedStringArray()
	for g: Dictionary in k["groups"]:
		counts.append(tr(COUNT_TEXT).format(g))
	text = "\n".join([head, " ".join(counts + tags), "\n".join(details)])
	var index: int = k["index"]
	_title = tr(k["client_name"])
	_details = details
	# The details show in the tip of the station (SPEC Section 20.2).
	mouse_entered.connect(
		func() -> void:
			screen.set_hover_contract(index)
			_show_details()
	)
	mouse_exited.connect(
		func() -> void:
			screen.set_hover_contract(-1)
			screen.hide_tip()
	)


## Shows the details of the card in the tip of the station.
func _show_details() -> void:
	screen.show_text_tip(_title, _details)


## The mouse leaves a freight image: the tip shows the details of the card again when
## the mouse is still on the card. The card gets no new mouse_entered from its child.
func _on_chip_exited() -> void:
	if get_global_rect().has_point(get_global_mouse_position()):
		_show_details()
	else:
		screen.hide_tip()


## The first line: the client, the total pay, the mass, and the state or the button.
## It adds the totals and the mass after to the details. It returns its text.
func _first_line(box: Control, k: Dictionary, details: PackedStringArray) -> String:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	box.add_child(head)
	var client := Ui.label(
		head, "", TextSize.BODY, Palette.ACCENT if k["accepted"] else Palette.TEXT
	)
	client.text = tr(k["client_name"])
	client.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	client.clip_text = true
	var pay := Ui.label(head, "", TextSize.BODY, Palette.GOOD)
	pay.text = tr(PAY_TEXT).format({"total": k["total_pay"]})
	details.append(
		tr(TOTALS_TEXT).format({"pieces": k["pieces"], "pay": k["pay"], "total": k["total_pay"]})
	)
	if not k["accepted"]:
		var texts := {
			Defs.MASS_OK: MASS_OK_TEXT, Defs.MASS_FEE: MASS_FEE_TEXT, Defs.MASS_OVER: MASS_OVER_TEXT
		}
		var colors := {
			Defs.MASS_OK: Palette.TEXT_DIM, Defs.MASS_FEE: Palette.WARN, Defs.MASS_OVER: Palette.BAD
		}
		mass_color = colors[k["mass_state"]]
		var limit: int = screen.run_data["mass"]["limit"]
		var after := {"mass": k["mass"], "after": k["mass_after"], "limit": limit}
		details.append(tr(texts[k["mass_state"]]).format(after))
	var mass := Ui.label(head, "", TextSize.BODY, mass_color)
	mass.text = tr(MASS_TEXT).format(k)
	var line := PackedStringArray([client.text, pay.text, mass.text])
	var index: int = k["index"]
	# A long contract on its way cannot be canceled (SPEC Section 30.2).
	if k["accepted"] and not k.get("carried", false):
		screen.add_button(
			head, tr(CANCEL_TEXT), func() -> void: screen.act(GameState.cancel_contract(index))
		)
	elif not k["accepted"]:
		screen.add_button(
			head, tr(ACCEPT_TEXT), func() -> void: screen.act(GameState.accept_contract(index))
		)
	first_line = " ".join(line)
	return first_line


## A short tag on the second line. It returns its text.
func _tag(row: Control, tag: String, color: Color) -> String:
	var l := Ui.label(row, "", TextSize.SMALL, color)
	l.text = tag
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return tag


## The rule of each trait of the freight, for the details.
func _trait_rules(groups: Array) -> PackedStringArray:
	var out := PackedStringArray()
	var seen := {}
	for g: Dictionary in groups:
		for t: String in g["traits"]:
			if seen.has(t):
				continue
			seen[t] = true
			var line := GameText.trait_line(screen.view_data["terms"], t)
			if line != "":
				out.append(line)
	return out


## Shows each freight group: its image, ×N, and its trait icons. It returns the row, so
## that the tags of the second line go after the groups.
func _groups(parent: Control, groups: Array) -> HFlowContainer:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 14)
	row.add_theme_constant_override("v_separation", 6)
	parent.add_child(row)
	for g: Dictionary in groups:
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 4)
		row.add_child(item)
		var size := CargoDraw.shape_size(g["shape"])
		var cell := GROUP_CELL if maxi(size.x, size.y) <= 1 else GROUP_CELL_LARGE
		var chip := CargoChip.new().setup(g, cell)
		chip.mouse_filter = Control.MOUSE_FILTER_PASS
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		chip.mouse_entered.connect(func() -> void: screen.show_tip(g))
		chip.mouse_exited.connect(_on_chip_exited)
		item.add_child(chip)
		var count := Ui.label(item, "", TextSize.BODY)
		count.text = tr(COUNT_TEXT).format(g)
		count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		for t: String in g["traits"]:
			var icon := ShopPanel.trait_icon(t)
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			item.add_child(icon)
	return row
