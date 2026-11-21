class_name EventPanel
extends Overlay
## The event on top of the station (SPEC Section 20.8): the speaker stands at the left
## of the dialogue box, and the box has the name of the speaker, the name of the event,
## its text, and a button for each choice. The player must select a choice: Esc does
## not close it. After the choice, the box fades out, the speaker replies in a speech
## bubble, and Continue closes the panel.

const COST_TEXT := "Cost {cost}"
const CONTINUE_TEXT := "Continue"
## The portraits of the speakers (task art). Each head has the same size.
const PORTRAIT_PATH := "res://art/speakers/%s.png"
## The height of the speaker that shows, from the top of the head. The shortest
## portrait (the mechanic) is 416 pixels high. All heads are at the same height.
const FIGURE_HEIGHT := 410
## The height of each head in a portrait: HEAD_SIZE of tools/art/import_art.py. A bust
## portrait shorter than FIGURE_HEIGHT stands at the bottom of the box (SPEC Section 20.8).
const HEAD_SIZE := 120
## The part of the speaker at the bottom that fades out.
const FADE := 0.15
## The width of the place of the speaker. A wider portrait goes past it at the left.
const SPEAKER_WIDTH := 360.0
const BOX_WIDTH := 680.0
const TITLE_SIZE := 36
const BUBBLE_WIDTH := 460.0
## The tail of the bubble: its length, and its height at the bubble.
const TAIL := Vector2(32, 26)
## The tip of the tail: the gap at the right of the head, and the depth below the top of
## the head (the mouth).
const TAIL_TIP := Vector2(10, 78)
## The time of the fade of the box and of the pop of the bubble (SPEC Section 20.8).
const POP_TIME := 0.15
const FADE_SHADER := """
shader_type canvas_item;
uniform float fade = 0.15;
// The UV of the cut: the texture is a region of the portrait from its top.
uniform float bottom = 1.0;
void fragment() {
	COLOR = texture(TEXTURE, UV);
	COLOR.a *= clamp((bottom - UV.y) / (fade * bottom), 0.0, 1.0);
}
"""

## The parts, for the checks.
var choices: Array[Button] = []
## The pilot hint of the first event, or null (SPEC Section 23.3).
var hint: Label
var speaker_portrait: TextureRect
## The dialogue box at the right of the speaker.
var dialogue: Control
var speaker_name: Label
## The tip of the panel: why a choice is disabled (SPEC Section 26.2). The station tip
## is below the panel, so the panel has its own.
var tip: CargoTip
## The reply of the speaker and its Continue button, after a choice (SPEC Section 20.8).
var reply_label: Label
var continue_button: Button
## The speech bubble of the reply and its tail, or null before the choice.
var bubble: PanelContainer
var bubble_tail: Control
## The index of the selected choice. Continue does its action (SPEC Section 20.8).
var picked := -1
## The reply after the choice, or "" before the choice.
var _reply := ""
## The place of the speaker: the bubble is in it, at the right of the head.
var _area: Control
var _speaker_name := ""


func _build() -> void:
	choices.clear()
	var run: Dictionary = GameState.view()["run"]
	if run.get("phase", "") != Defs.PHASE_EVENT:
		return
	var e: Dictionary = run["event"]
	# The speaker stands outside a frame: the overlay panel shows no frame here.
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	_speaker_name = e["speaker"]["name"]
	_area = _speaker(e["speaker"])
	row.add_child(_area)
	row.add_child(_dialogue(e))
	if _reply != "":
		dialogue.modulate.a = 0.0
		_add_bubble(false)
	if tip == null:
		tip = CargoTip.new()
		add_child(tip)
	tip.visible = false
	if continue_button != null:
		continue_button.grab_focus.call_deferred()
	for b in choices:
		if not b.disabled:
			b.grab_focus.call_deferred()
			break


## The speaker: the top FIGURE_HEIGHT pixels of the portrait, from the top of the
## head. The bottom fades out at the bottom edge of the dialogue box.
func _speaker(speaker: Dictionary) -> Control:
	var area := Control.new()
	area.custom_minimum_size = Vector2(SPEAKER_WIDTH, FIGURE_HEIGHT)
	area.size_flags_vertical = Control.SIZE_SHRINK_END
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speaker_portrait = TextureRect.new()
	speaker_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path := PORTRAIT_PATH % speaker["id"]
	if ResourceLoader.exists(path):
		var full: Texture2D = load(path)
		var cut := AtlasTexture.new()
		cut.atlas = full
		cut.region = Rect2(0, 0, full.get_width(), mini(full.get_height(), FIGURE_HEIGHT))
		speaker_portrait.texture = cut
		var fade := ShaderMaterial.new()
		fade.shader = Shader.new()
		fade.shader.code = FADE_SHADER
		fade.set_shader_parameter("fade", FADE)
		fade.set_shader_parameter("bottom", cut.region.size.y / full.get_height())
		speaker_portrait.material = fade
	var fig := speaker_portrait.texture.get_size() if speaker_portrait.texture else Vector2.ZERO
	# Centered in its place, but never past the dialogue box at the right.
	var x := minf((SPEAKER_WIDTH - fig.x) / 2.0, SPEAKER_WIDTH - fig.x)
	speaker_portrait.position = Vector2(x, FIGURE_HEIGHT - fig.y)
	speaker_portrait.size = fig
	area.add_child(speaker_portrait)
	return area


## The dialogue box: the name of the speaker, the name of the event, its text, and a
## button for each choice with its cost and its effects.
func _dialogue(e: Dictionary) -> Control:
	var frame := PanelContainer.new()
	dialogue = frame
	frame.size_flags_vertical = Control.SIZE_SHRINK_END
	frame.add_theme_stylebox_override("panel", Ui.panel_style(Palette.ACCENT, 2, 8, 28))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.custom_minimum_size.x = BOX_WIDTH
	frame.add_child(col)
	# The hint is in the box, above the text: it does not cover the station (SPEC Section 23.3).
	hint = pilot_hint(Hints.EVENT, col)
	speaker_name = Ui.label(col, e["speaker"]["name"], TextSize.HEADING, Palette.ACCENT)
	TextSize.display(Ui.label(col, e["name"], TITLE_SIZE, Palette.TEXT))
	var body := Ui.label(col, e["text"], TextSize.HEADING, Palette.TEXT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var gap := Control.new()
	gap.custom_minimum_size.y = 4
	col.add_child(gap)
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
		var b := Button.new()
		b.text = "\n".join(lines)
		b.custom_minimum_size = Vector2(BOX_WIDTH, 72)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", TextSize.BUTTON)
		b.disabled = not c["can"] or _reply != ""
		var why := tr(c["why"])
		if why != "":
			b.mouse_entered.connect(func() -> void: tip.show_text(why, PackedStringArray()))
			b.mouse_exited.connect(func() -> void: tip.visible = false)
		var reply: String = c["reply"]
		b.pressed.connect(func() -> void: _pick(index, reply))
		col.add_child(b)
		if _reply == "":
			choices.append(b)
	return frame


## The speech bubble at the right of the head: the name of the speaker, the reply, and
## the Continue button. Its tail points to the speaker. With pop, it pops out from the
## tail (SPEC Section 20.8).
func _add_bubble(pop: bool) -> void:
	var portrait := speaker_portrait.get_rect()
	var tip := Vector2(
		portrait.get_center().x + HEAD_SIZE / 2.0 + TAIL_TIP.x, portrait.position.y + TAIL_TIP.y
	)
	bubble = PanelContainer.new()
	bubble.add_theme_stylebox_override("panel", Ui.panel_style(Palette.ACCENT, 3, 14, 22))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	bubble.add_child(col)
	Ui.label(col, _speaker_name, TextSize.BODY, Palette.ACCENT)
	reply_label = Ui.label(col, "“%s”" % tr(_reply), TextSize.HEADING, Palette.TEXT)
	reply_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reply_label.custom_minimum_size.x = BUBBLE_WIDTH
	continue_button = Button.new()
	continue_button.text = tr(CONTINUE_TEXT)
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	continue_button.custom_minimum_size = Vector2(180, 52)
	continue_button.add_theme_font_size_override("font_size", TextSize.BUTTON)
	continue_button.pressed.connect(close)
	col.add_child(continue_button)
	_area.add_child(bubble)
	bubble.reset_size()
	bubble.position = Vector2(tip.x + TAIL.x - 3.0, tip.y - 48.0)
	bubble_tail = Control.new()
	bubble_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble_tail.position = Vector2(tip.x, tip.y - TAIL.y / 2.0)
	bubble_tail.size = Vector2(TAIL.x, TAIL.y)
	bubble_tail.draw.connect(_draw_tail)
	_area.add_child(bubble_tail)
	if not pop:
		return
	dialogue.create_tween().tween_property(dialogue, "modulate:a", 0.0, POP_TIME)
	for part: Control in [bubble, bubble_tail]:
		part.pivot_offset = tip - part.position
		part.scale = Vector2(0.6, 0.6)
		part.modulate.a = 0.0
		var tw := part.create_tween().set_parallel()
		tw.tween_property(part, "scale", Vector2.ONE, POP_TIME).set_trans(Tween.TRANS_BACK)
		tw.tween_property(part, "modulate:a", 1.0, POP_TIME)


## The tail: a triangle from the tip at the left to the edge of the bubble, in the color
## of the bubble, with the border on its two long sides.
func _draw_tail() -> void:
	var s := bubble_tail.size
	var tip := Vector2(0, s.y / 2.0)
	var top := Vector2(s.x, 0)
	var bottom := Vector2(s.x, s.y)
	bubble_tail.draw_colored_polygon(PackedVector2Array([tip, top, bottom]), Palette.PANEL)
	bubble_tail.draw_polyline(PackedVector2Array([top, tip, bottom]), Palette.ACCENT, 3.0)


## Shows the reply of a choice. The action of the choice waits for Continue, so that
## its effects play after the reply (SPEC Section 20.8). A choice that the player cannot
## select is disabled (SPEC Section 26.2).
func _pick(index: int, reply: String) -> void:
	picked = index
	_reply = reply
	Hints.done(Hints.EVENT)
	for b in choices:
		b.disabled = true
	choices.clear()
	_add_bubble(true)
	continue_button.grab_focus.call_deferred()


## The player must select a choice: Esc does nothing.
func _unhandled_input(_event: InputEvent) -> void:
	pass


## After the choice, a click, Enter, or Space closes the reply (SPEC Section 20.8). The
## dark backdrop takes the clicks, so the panel reads them before the controls do.
func _input(event: InputEvent) -> void:
	if _reply == "" or is_queued_for_deletion():
		return
	var click: bool = event is InputEventMouseButton and event.pressed
	var key: bool = (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]
	)
	if click or key:
		get_viewport().set_input_as_handled()
		close()
