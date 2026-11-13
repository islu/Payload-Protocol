class_name WarpScreen
extends Control
## The warp and the arrival report (SPEC Sections 20.3 and 20.4). It plays the
## event log of the warp step by step: the banner, the tilt, the slides, the
## hits, and the reactions. Then it shows the report. It calculates nothing: each
## position, hit, and reaction comes from the log.

signal playback_finished

const STEP_TEXT := "Shift {n}: {arrow} {direction}"
const FORK_TEXT := "Shift {n}: {options} ...?"
const OR_TEXT := "or"
const FUEL_TEXT := "Fuel fee: -{fee}"
const ARRIVAL_TEXT := "Arrival"
const TOTAL_TEXT := "Total: {total} credits"
const SOLD_TEXT := "Kit sold from the dock: +{credits}"
const CONTINUE_TEXT := "Continue"
const SKIP_TEXT := "Click or press Space to speed up."
const BONUS_TEXT := "Bonus +{bonus}"
const BONUS_MISSED_TEXT := "Bonus missed"
const BREACH_TEXT := "Breach -{breach}"
const PIECE_STATE_TEXT := {
	Defs.PIECE_DELIVERED: "delivered",
	Defs.PIECE_SCRAP: "scrap",
	Defs.PIECE_SPOILED: "spoiled",
	Defs.PIECE_LOST: "lost",
	Defs.PIECE_BREACHED: "breached",
}
const ARROWS := {Defs.DIR_LEFT: "←", Defs.DIR_RIGHT: "→", Defs.DIR_UP: "↑", Defs.DIR_DOWN: "↓"}
## The space between the hold and the report, in pixels.
const REPORT_GAP := 40.0
## The cells that a slide moves in each second (SPEC Section 21.1).
const CELLS_PER_SECOND := 8.0
## The time between two reactions of a chain (SPEC Section 21.3).
const REACTION_GAP := 0.15

## The play speed: the warp speed setting, and 4 times faster after a click (SPEC Section 20.3).
var speed := 1.0
var finished := false

var _view: Dictionary = {}
var _cargo: Dictionary = {}
var _stars: Starfield
var _stage: Control
var _hold: HoldView
var _fx: FxLayer
## The effects above the report: the gold sparkle (SPEC Section 21.4).
var _top_fx: FxLayer
var _banner: Label
var _skip_label: Label
var _report_head: Label
var _report: PanelContainer
var _report_text: RichTextLabel
var _continue: Button
var _shake := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	speed = float(Settings.get_value("warp_speed"))
	_stars = Starfield.new()
	_stars.speed = 30.0
	add_child(_stars)
	_stage = Control.new()
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_stage)
	_hold = HoldView.new()
	_hold.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hold.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.add_child(_hold)
	_fx = FxLayer.new()
	_fx.hold = _hold
	_hold.add_child(_fx)
	_banner = Label.new()
	_banner.add_theme_font_size_override("font_size", 64)
	_banner.add_theme_color_override("font_color", Palette.WARN)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_banner.offset_top = 40
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_banner)
	_skip_label = Label.new()
	_skip_label.text = tr(SKIP_TEXT)
	_skip_label.add_theme_color_override("font_color", Palette.TEXT_DIM)
	_skip_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_skip_label.offset_top = -50
	_skip_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(_skip_label)
	_build_report()
	_top_fx = FxLayer.new()
	add_child(_top_fx)
	_view = GameState.view()
	_play.call_deferred()


func _build_report() -> void:
	_report = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.PANEL, 0.95)
	style.border_color = Palette.ACCENT
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(24)
	_report.add_theme_stylebox_override("panel", style)
	_report.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	_report.offset_left = -620
	_report.offset_right = -30
	_report.offset_top = 60
	_report.offset_bottom = -60
	_report.visible = false
	add_child(_report)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	_report.add_child(box)
	_report_head = Label.new()
	_report_head.text = tr(ARRIVAL_TEXT)
	_report_head.add_theme_font_size_override("font_size", 44)
	_report_head.add_theme_color_override("font_color", Palette.ACCENT)
	box.add_child(_report_head)
	_report_text = RichTextLabel.new()
	_report_text.bbcode_enabled = true
	_report_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_report_text.add_theme_font_size_override("normal_font_size", 21)
	_report_text.add_theme_font_size_override("bold_font_size", 22)
	box.add_child(_report_text)
	_continue = Button.new()
	_continue.text = tr(CONTINUE_TEXT)
	_continue.custom_minimum_size = Vector2(0, 70)
	_continue.add_theme_font_size_override("font_size", 28)
	_continue.pressed.connect(func() -> void: GameState.continue_run())
	box.add_child(_continue)


## Shows the text in the new language (SPEC Section 23.1). The banner of the step
## changes at the next step.
func retranslate() -> void:
	_skip_label.text = tr(SKIP_TEXT)
	_report_head.text = tr(ARRIVAL_TEXT)
	_continue.text = tr(CONTINUE_TEXT)
	if finished:
		_report_text.text = _report_lines(_view["run"])


func _unhandled_input(event: InputEvent) -> void:
	if finished:
		return
	var click: bool = event is InputEventMouseButton and event.pressed
	var space: bool = event is InputEventKey and event.pressed and event.keycode == KEY_SPACE
	if click or space:
		speed_up()
		get_viewport().set_input_as_handled()


## Plays the rest of the warp at 4 times the speed (SPEC Section 20.3).
func speed_up() -> void:
	speed = float(Settings.get_value("warp_speed")) * 4.0
	_fx.speed = speed


func _wait(seconds: float) -> void:
	# process_always is false, so that the pause menu stops the warp.
	await get_tree().create_timer(seconds / speed, false).timeout


# --- Playback ---


func _play() -> void:
	var run: Dictionary = _view["run"]
	var warp_log: Dictionary = run["warp"]
	for c: Dictionary in warp_log.get("before", []):
		_cargo[c["id"]] = c.duplicate(true)
	_show_hold(run)
	await _wait(0.4)
	var n := 0
	for step: Dictionary in warp_log.get("steps", []):
		n += 1
		await _play_step(n, step, run)
	_stars.speed = 1.0
	_stage.rotation = 0.0
	await _play_spoils(run)
	_finish(run)


func _show_hold(run: Dictionary) -> void:
	var cargo := []
	for id: int in _sorted_ids():
		cargo.append(_cargo[id])
	_hold.set_view({"hold": run["hold"], "cargo": cargo, "links": []})


func _sorted_ids() -> Array:
	var ids := _cargo.keys()
	ids.sort()
	return ids


func _play_step(n: int, step: Dictionary, run: Dictionary) -> void:
	var d: String = step["direction"]
	var name: String = _view["names"]["directions"].get(d, d)
	_banner.modulate.a = 1.0
	if step.has("options"):
		# A fork step: show the two directions, then the one that happens (SPEC Section 20.3).
		var names := PackedStringArray()
		for o: String in step["options"]:
			names.append(StationScreen.direction_text(o, _view))
		_banner.text = tr(FORK_TEXT).format({"n": n, "options": (" %s " % tr(OR_TEXT)).join(names)})
		Sound.play(self, "alarm")
		await _wait(0.9)
	_banner.text = tr(STEP_TEXT).format(
		{"n": n, "arrow": ARROWS.get(d, "?"), "direction": tr(name)}
	)
	Sound.play(self, "alarm")
	await _wait(0.6)
	_tilt(d)
	# The slides: all cargo moves at the same time, at the same speed (SPEC Section 21.1).
	var tween: Tween = null
	for s: Dictionary in step["slides"]:
		if tween == null:
			tween = create_tween().set_parallel(true)
			tween.set_speed_scale(speed)
		var c: Dictionary = _cargo[s["cargo"]]
		c["x"] = s["to"]["x"]
		c["y"] = s["to"]["y"]
		var from := Vector2(s["from"]["x"] - s["to"]["x"], s["from"]["y"] - s["to"]["y"])
		_hold.offsets[s["cargo"]] = from
		var time: float = s["distance"] / CELLS_PER_SECOND
		tween.tween_method(_set_offset.bind(s["cargo"], from), 0.0, 1.0, time)
	if tween != null:
		Sound.play(self, "rumble")
		await tween.finished
	_hold.offsets.clear()
	_show_hold(run)
	_play_hits(step, d)
	await _wait(0.3)
	for r: Dictionary in step["reactions"]:
		_play_reaction(r)
		_show_hold(run)
		await _wait(REACTION_GAP)
		if r["kind"] == Defs.REACT_EXPLOSION:
			await _wait(0.1)  # The hit stop of an explosion (SPEC Section 21.3).
	# Keep the hold the same as the log after the step.
	var kept := {}
	for spot: Dictionary in step["after"]:
		kept[spot["cargo"]] = true
		if _cargo.has(spot["cargo"]):
			var c: Dictionary = _cargo[spot["cargo"]]
			c["x"] = spot["x"]
			c["y"] = spot["y"]
			c["kind"] = spot["kind"]
	for id: int in _cargo.keys():
		if not kept.has(id):
			_cargo.erase(id)
	_show_hold(run)
	var fade := create_tween()
	fade.tween_property(_banner, "modulate:a", 0.0, 0.3 / speed)
	await _wait(0.35)


func _set_offset(k: float, id: int, from: Vector2) -> void:
	# Ease out: fast at the start, slow at the stop.
	_hold.offsets[id] = from * pow(1.0 - k, 2.0)
	_hold.queue_redraw()


## Tilts the ship a little in the direction of the step (SPEC Section 20.3).
func _tilt(d: String) -> void:
	var angle: float = {Defs.DIR_LEFT: -0.03, Defs.DIR_RIGHT: 0.03}.get(d, 0.0)
	_stage.pivot_offset = _stage.size / 2.0
	var t := create_tween()
	t.tween_property(_stage, "rotation", angle, 0.25 / speed)


func _play_hits(step: Dictionary, d: String) -> void:
	var delta := Defs.delta(d)
	var strongest := 0
	for h: Dictionary in step["hits"]:
		var c: Dictionary = _cargo.get(h["cargo"], {})
		if c.is_empty():
			continue
		# The contact edge: the middle of the contact cells, half a cell in the direction.
		var sum := Vector2.ZERO
		for cell: Dictionary in h["contact"]:
			sum += Vector2(cell["x"], cell["y"]) + Vector2(0.5, 0.5) + Vector2(delta) * 0.5
		var at: Vector2 = _hold.grid_origin() + sum / h["contact"].size() * _hold.cell
		_fx.spark(at, -Vector2(delta))
		_fx.number(_hold.cargo_center(c), h["force"])
		strongest = maxi(strongest, h["force"])
	if step["hits"].is_empty():
		return
	if strongest == 0:
		Sound.play(self, "soft_hit")
	else:
		Sound.play(self, "metal_hit", linear_to_db(clampf(0.4 + strongest * 0.08, 0.4, 1.0)))
	_shake_screen(strongest * 2.0)


func _play_reaction(r: Dictionary) -> void:
	var c: Dictionary = _cargo.get(r["cargo"], {})
	if c.is_empty():
		return
	var at := _hold.cargo_center(c)
	match r["kind"]:
		Defs.REACT_BREAK, Defs.REACT_BLAST:
			_fx.shards(at)
			_to_scrap(c)
			Sound.play(self, "glass_break")
		Defs.REACT_LEAK:
			_fx.leak(at)
			_to_scrap(c)
			Sound.play(self, "splash")
		Defs.REACT_SHORT:
			_fx.bolts(at)
			_to_scrap(c)
			Sound.play(self, "buzz")
		Defs.REACT_EXPLOSION:
			var cells := []
			for cell: Dictionary in r.get("area", []):
				cells.append(Vector2i(cell["x"], cell["y"]))
			_fx.explosion(at, cells)
			_cargo.erase(r["cargo"])
			Sound.play(self, "explosion")
			_shake_screen(28.0)
		Defs.REACT_CLEAR:
			_fx.shards(at)
			_cargo.erase(r["cargo"])
		Defs.REACT_SHIELD:
			_fx.bubble(at)
			Sound.play(self, "shield")


func _to_scrap(c: Dictionary) -> void:
	c["kind"] = Defs.KIND_SCRAP
	c["traits"] = []
	c["clamped"] = c.get("clamped", false)


## Plays the spoils of the arrival: a green cloud on each spoiled cargo (SPEC Section 21.3).
func _play_spoils(run: Dictionary) -> void:
	for id: int in run["arrival"].get("spoiled", []):
		if _cargo.has(id):
			_fx.cloud(_hold.cargo_center(_cargo[id]))
			_to_scrap(_cargo[id])
			Sound.play(self, "squelch")
	_show_hold(run)
	if not run["arrival"].get("spoiled", []).is_empty():
		await _wait(0.8)


## Fades out the freight that left the hold, and shows the report (SPEC Section 20.4).
func _finish(run: Dictionary) -> void:
	var stays := {}
	for c: Dictionary in run["cargo"]:
		stays[c["id"]] = true
	var fade: Tween = null
	for id: int in _cargo.keys():
		if not stays.has(id):
			if fade == null:
				fade = create_tween().set_parallel(true)
			_hold.fades[id] = 1.0
			fade.tween_method(func(a: float) -> void: _fade(id, a), 1.0, 0.0, 0.6)
	if run["arrival"]["total"] != 0:
		Sound.play(self, "coin")
		_coin_on_report.call_deferred()
	_report_text.text = _report_lines(run)
	_report.visible = true
	_make_room_for_report.call_deferred()
	_skip_label.visible = false
	_banner.text = ""
	finished = true
	_continue.grab_focus()
	playback_finished.emit()


## The report has its place after one frame: the containers sort it then.
func _coin_on_report() -> void:
	await get_tree().process_frame
	_top_fx.coin(_report_head.get_global_rect().get_center())


## Moves the hold to the left when the report covers it (SPEC Section 20.4).
func _make_room_for_report() -> void:
	await get_tree().process_frame
	var right := _hold.global_position.x + _hold.grid_origin().x + _hold.columns * _hold.cell
	var overlap := right + REPORT_GAP - _report.global_position.x
	if overlap > 0.0:
		create_tween().tween_property(_hold, "position:x", _hold.position.x - overlap, 0.4)


func _fade(id: int, a: float) -> void:
	_hold.fades[id] = a
	_hold.queue_redraw()


func _report_lines(run: Dictionary) -> String:
	var a: Dictionary = run["arrival"]
	var lines := PackedStringArray()
	for k: Dictionary in a["contracts"]:
		lines.append("[b]%s[/b]  +%d" % [tr(k["client_name"]), k["pay"]])
		for p: Dictionary in k["pieces"]:
			var color: Color = Palette.GOOD if p["state"] == Defs.PIECE_DELIVERED else Palette.BAD
			lines.append(
				(
					"   [color=#%s]%s: %s[/color]"
					% [
						color.to_html(false),
						tr(p["name"]),
						tr(PIECE_STATE_TEXT.get(p["state"], p["state"]))
					]
				)
			)
		if k["has_bonus"]:
			lines.append(
				"   " + (tr(BONUS_TEXT).format(k) if k["bonus_met"] else tr(BONUS_MISSED_TEXT))
			)
		if k["breach"] > 0:
			lines.append("   " + tr(BREACH_TEXT).format(k))
	if a.get("sold", 0) > 0:
		lines.append(tr(SOLD_TEXT).format({"credits": a["sold"]}))
	if run["warp"].get("fuel_fee", 0) > 0:
		lines.append(tr(FUEL_TEXT).format({"fee": run["warp"]["fuel_fee"]}))
	lines.append("")
	lines.append("[b]%s[/b]" % tr(TOTAL_TEXT).format(a))
	lines.append("")
	lines.append(GameText.PILOT_NAME + ": " + tr(run["line"]))
	return "\n".join(lines)


# --- Shake (SPEC Section 21.2) ---


func _shake_screen(amount: float) -> void:
	if not Settings.get_value("shake"):
		return
	_shake = maxf(_shake, amount)


func _process(delta: float) -> void:
	if _shake > 0.1:
		_stage.position = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
		_shake = lerpf(_shake, 0.0, minf(1.0, delta * 10.0 * speed))
	elif _stage.position != Vector2.ZERO:
		_stage.position = Vector2.ZERO
