class_name PhasePanel
extends Control
## A simple panel for the arrival, the toll gate, and the run end (SPEC Sections
## 20.4 to 20.6). Day 5 replaces it with the screens of each phase.

const ARRIVAL_TEXT := "Arrival"
const TOTAL_TEXT := "Total: {total} credits"
const CONTINUE_TEXT := "Continue"
const TOLL_TITLE_TEXT := "Toll gate"
const TOLL_BODY_TEXT := "Toll {toll} · credits {credits} · after {after}"
const PAY_TEXT := "Pay"
const CANNOT_PAY_TEXT := "You cannot pay the toll."
const WIN_TEXT := "Route complete!"
const LOSS_TEXT := "Run over."
# gdlint:ignore = max-line-length
const END_BODY_TEXT := "Score {score} · delivered {delivered} · scrap {scrapped} · explosions {explosions} · seed {seed}"
const NEW_RUN_TEXT := "New Run"
const TITLE_BUTTON_TEXT := "Title"
const BONUS_TEXT := "bonus +{bonus}"
const BONUS_MISSED_TEXT := "bonus missed"
const BREACH_TEXT := "breach -{breach}"

var _body: RichTextLabel
var _buttons: HBoxContainer
var _heading: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Palette.BACKGROUND
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 360
	box.offset_right = -360
	box.offset_top = 120
	box.offset_bottom = -120
	box.add_theme_constant_override("separation", 24)
	add_child(box)
	_heading = Label.new()
	_heading.add_theme_font_size_override("font_size", 48)
	_heading.add_theme_color_override("font_color", Palette.ACCENT)
	box.add_child(_heading)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_font_size_override("normal_font_size", 22)
	box.add_child(_body)
	_buttons = HBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 20)
	box.add_child(_buttons)
	GameState.state_changed.connect(refresh)
	refresh()


func refresh() -> void:
	var run: Dictionary = GameState.view()["run"]
	if run.is_empty():
		return
	for b in _buttons.get_children():
		b.queue_free()
	var lines := PackedStringArray()
	match run["phase"]:
		Defs.PHASE_ARRIVAL:
			_heading.text = tr(ARRIVAL_TEXT)
			var a: Dictionary = run["arrival"]
			for k: Dictionary in a["contracts"]:
				var pieces := PackedStringArray()
				for p: Dictionary in k["pieces"]:
					pieces.append("%s (%s)" % [tr(p["name"]), tr(p["state"])])
				var extra := ""
				if k["has_bonus"]:
					extra = (
						" · "
						+ (tr(BONUS_TEXT).format(k) if k["bonus_met"] else tr(BONUS_MISSED_TEXT))
					)
				if k["breach"] > 0:
					extra += " · " + tr(BREACH_TEXT).format(k)
				lines.append(
					(
						"[b]%s[/b]: %s · +%d%s"
						% [tr(k["client_name"]), ", ".join(pieces), k["pay"], extra]
					)
				)
			lines.append(tr(TOTAL_TEXT).format(a))
			_add_button(CONTINUE_TEXT, func() -> void: GameState.continue_run())
		Defs.PHASE_TOLL:
			_heading.text = tr(TOLL_TITLE_TEXT)
			var t: Dictionary = run["toll_gate"]
			lines.append(tr(TOLL_BODY_TEXT).format(t))
			if not t["can_pay"]:
				lines.append(
					"[color=#%s]%s[/color]" % [Palette.BAD.to_html(false), tr(CANNOT_PAY_TEXT)]
				)
			_add_button(
				PAY_TEXT if t["can_pay"] else CONTINUE_TEXT, func() -> void: GameState.pay_toll()
			)
		Defs.PHASE_END:
			var e: Dictionary = run["end"]
			_heading.text = tr(WIN_TEXT if e["won"] else LOSS_TEXT)
			var values: Dictionary = e["stats"].duplicate()
			values["score"] = e["score"]
			values["seed"] = e["seed"]
			lines.append(tr(END_BODY_TEXT).format(values))
			_add_button(NEW_RUN_TEXT, func() -> void: GameState.new_run())
			_add_button(TITLE_BUTTON_TEXT, func() -> void: GameState.abandon_run())
	lines.append("")
	lines.append("PIP: " + tr(run["line"]))
	_body.text = "\n".join(lines)


func _add_button(text: String, action: Callable) -> void:
	var b := Button.new()
	b.text = tr(text)
	b.custom_minimum_size = Vector2(240, 60)
	b.pressed.connect(action)
	_buttons.add_child(b)
