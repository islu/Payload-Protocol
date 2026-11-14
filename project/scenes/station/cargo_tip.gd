class_name CargoTip
extends PanelContainer
## The tooltip of a cargo (SPEC Section 8.4): its name, kind, weight, traits with
## their rules, mass, and prices. It follows the mouse inside its parent.

const TIP_WEIGHT_TEXT := "{kind} · {weight} (weight {value})"
const TIP_PAY_TEXT := "Pays {pay} at the arrival"
const TIP_SELL_TEXT := "Sells for {price}"
const TIP_CLEAR_TEXT := "Clear for {price}"
const NO_COOLER_TEXT := "No Cooler next to it: it spoils at the arrival."
const NO_POWER_TEXT := "No Battery next to it: no power."
const TIP_MASS_TEXT := "Mass {mass}"

var _label: RichTextLabel


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	z_index = 10
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.custom_minimum_size.x = 360
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for key in ["normal_font_size", "bold_font_size"]:
		_label.add_theme_font_size_override(key, TextSize.BODY)
	add_child(_label)


## Shows the tooltip of a cargo view. view is GameState.view(): its names and terms.
func show_cargo(c: Dictionary, view: Dictionary) -> void:
	if c.is_empty():
		return
	var names: Dictionary = view["names"]
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
		for term: Dictionary in view["terms"]:
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
	_label.text = "\n".join(lines)
	visible = true
	reset_size()
	_place()


func _place() -> void:
	var area: Vector2 = get_parent_area_size()
	var p := get_global_mouse_position() + Vector2(18, 18)
	var max_p := area - size - Vector2(8, 8)
	position = Vector2(maxf(8.0, minf(p.x, max_p.x)), maxf(8.0, minf(p.y, max_p.y)))


func _process(_delta: float) -> void:
	if visible:
		_place()
