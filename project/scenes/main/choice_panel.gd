class_name ChoicePanel
extends Overlay
## The event of a station and the mod choice (SPEC Sections 20.8 and 20.9). The
## player must select one choice: Esc does not close it.

const MOD_CHOICE_TEXT := "Select a ship mod"
const COST_TEXT := "Cost {cost}"

## The buttons of the choices, in order. The UI check reads them.
var choices: Array[Button] = []


func _build() -> void:
	choices.clear()
	var run: Dictionary = GameState.view()["run"]
	if run.get("phase", "") == Defs.PHASE_EVENT:
		_build_event(run["event"])
	elif run.get("phase", "") == Defs.PHASE_MOD:
		_build_mods(run["mod_offer"])
	if not choices.is_empty():
		for b in choices:
			if not b.disabled:
				b.grab_focus.call_deferred()
				break


func _build_event(e: Dictionary) -> void:
	heading(e["name"])
	var body := Label.new()
	body.text = tr(e["text"])
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 640
	body.add_theme_font_size_override("font_size", TextSize.BODY)
	box.add_child(body)
	for c: Dictionary in e["choices"]:
		var lines := PackedStringArray([tr(c["text"])])
		var notes := PackedStringArray()
		if c["cost"] > 0:
			notes.append(tr(COST_TEXT).format({"cost": c["cost"]}))
		for f: Dictionary in c["effects"]:
			notes.append(GameText.format(f))
		if not notes.is_empty():
			lines.append(" · ".join(notes))
		var index: int = c["index"]
		var b := _choice("\n".join(lines), func() -> void: _pick(GameState.choose_event(index)))
		b.disabled = not c["can"]


func _build_mods(offer: Array) -> void:
	heading(MOD_CHOICE_TEXT)
	for i in offer.size():
		var m: Dictionary = offer[i]
		var text := "%s\n%s" % [tr(m["name"]), tr(m["text"])]
		_choice(text, func() -> void: _pick(GameState.choose_mod(i)))


func _choice(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(640, 72)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", TextSize.BODY)
	b.pressed.connect(action)
	box.add_child(b)
	choices.append(b)
	return b


func _pick(err: String) -> void:
	if err != "":
		Sound.play(self, "deny")


## The player must select a choice: Esc does nothing.
func _unhandled_input(_event: InputEvent) -> void:
	pass
