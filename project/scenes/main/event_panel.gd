class_name EventPanel
extends Overlay
## The event on top of the station (SPEC Section 20.8): the speaker stands at the left
## of the dialogue box, and the box has the name of the speaker, the name of the event,
## its text, and a button for each choice. The player must select a choice: Esc does
## not close it.

const COST_TEXT := "Cost {cost}"
## The portraits of the speakers (task art). Each head has the same size.
const PORTRAIT_PATH := "res://art/speakers/%s.png"
## The height of the speaker that shows, from the top of the head. The shortest
## portrait (the mechanic) is 416 pixels high. All heads are at the same height.
const FIGURE_HEIGHT := 410
## The part of the speaker at the bottom that fades out.
const FADE := 0.15
## The width of the place of the speaker. A wider portrait goes past it at the left.
const SPEAKER_WIDTH := 360.0
const BOX_WIDTH := 680.0
const TITLE_SIZE := 36
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
var speaker_portrait: TextureRect
var speaker_name: Label
## The tip of the panel: why a choice is disabled (SPEC Section 26.2). The station tip
## is below the panel, so the panel has its own.
var tip: CargoTip


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
	row.add_child(_speaker(e["speaker"]))
	row.add_child(_dialogue(e))
	if tip == null:
		tip = CargoTip.new()
		add_child(tip)
	tip.visible = false
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
	frame.size_flags_vertical = Control.SIZE_SHRINK_END
	frame.add_theme_stylebox_override("panel", Ui.panel_style(Palette.ACCENT, 2, 8, 28))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.custom_minimum_size.x = BOX_WIDTH
	frame.add_child(col)
	speaker_name = Ui.label(col, e["speaker"]["name"], TextSize.HEADING, Palette.ACCENT)
	Ui.label(col, e["name"], TITLE_SIZE, Palette.TEXT)
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
		b.disabled = not c["can"]
		var why := tr(c["why"])
		if why != "":
			b.mouse_entered.connect(func() -> void: tip.show_text(why, PackedStringArray()))
			b.mouse_exited.connect(func() -> void: tip.visible = false)
		b.pressed.connect(func() -> void: _pick(GameState.choose_event(index)))
		col.add_child(b)
		choices.append(b)
	return frame


func _pick(err: String) -> void:
	if err != "":
		Sound.play(self, "deny")


## The player must select a choice: Esc does nothing.
func _unhandled_input(_event: InputEvent) -> void:
	pass
