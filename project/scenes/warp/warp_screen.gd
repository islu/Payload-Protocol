class_name WarpScreen
extends Control
## The warp and the arrival report (SPEC Sections 20.3 and 20.4). It plays the
## event log of the warp step by step: the banner, the tilt, the slides, the
## hits, and the reactions. Then it shows the report. It calculates nothing: each
## position, hit, and reaction comes from the log.

signal playback_finished

const STEP_TEXT := "Shift {n}: {arrow} {direction}"
const FORK_TEXT := "Shift {n}: {options} ...?"
const SKIP_TEXT := "Click or press Space to speed up."
const CHAIN_TEXT := "Chain ×{count}"
const LOST_TEXT := "Lost -{loss}"
## The space between the hold and the report, in pixels.
const REPORT_GAP := 40.0
## The cells that a slide moves in each second (SPEC Section 21.1).
const CELLS_PER_SECOND := 8.0
## The time between two reactions of a chain (SPEC Section 21.3).
const REACTION_GAP := 0.15
## The speed of a replay, against the warp speed setting (SPEC Section 20.4).
const REPLAY_SPEED := 0.5
## The alpha of delivered freight that stays in the hold during the report (SPEC Section 20.4).
const DELIVERED_ALPHA := 0.35

## The play speed: the warp speed setting, and 4 times faster after a click (SPEC Section 20.3).
var speed := 1.0
var finished := false
## The largest chain count that the warp showed, and the text of the total loss
## (SPEC Section 21.5). The UI check reads them.
var chain_shown := 0
var loss_text := ""
## The text of the incident that the warp played (SPEC Section 29.3). The UI check reads it.
var incident_shown := ""

var _view: Dictionary = {}
var _cargo: Dictionary = {}
var _stars: Starfield
var _stage: Control
var _hold: HoldView
var _bay: HoldView
var _fx: FxLayer
## The effects above the report: the gold sparkle (SPEC Section 21.4).
var _top_fx: FxLayer
var _banner: Label
var _skip_label: Label
## The chain count and the total loss, below the banner (SPEC Section 21.5).
var _loss_label: Label
var _report: ReportPanel
## True while the warp plays again: no coin sound (SPEC Section 20.4).
var _replaying := false
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
	# The shock bay hangs above the hold and moves with it (SPEC Section 31.2).
	_bay = HoldView.new()
	_bay.bay = true
	_bay.visible = false
	_bay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bay.fades = _hold.fades
	_bay.checks = _hold.checks
	_hold.add_child(_bay)
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
	_loss_label = Label.new()
	_loss_label.add_theme_font_size_override("font_size", 48)
	_loss_label.add_theme_color_override("font_color", Palette.BAD)
	_loss_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_loss_label.offset_top = 130
	_loss_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_loss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loss_label.modulate.a = 0.0
	add_child(_loss_label)
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
	_report = ReportPanel.new()
	_report.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	_report.offset_left = -640
	_report.offset_right = -30
	# Below the gear button of the main scene (SPEC Section 20.7).
	_report.offset_top = GearButton.SIZE + 40
	_report.offset_bottom = -40
	_report.visible = false
	# The mouse on a group of pieces marks them in the hold (SPEC Section 20.4).
	_report.pieces_hovered.connect(_mark_pieces)
	_report.replay.pressed.connect(_start_replay)
	add_child(_report)


## Shows the text in the new language (SPEC Section 23.1). The banner of the step
## changes at the next step.
func retranslate() -> void:
	_skip_label.text = tr(SKIP_TEXT)
	_report.retranslate()
	if finished:
		_report.show_report(_view["run"])


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
	for c: Dictionary in warp_log.get("before", []) + warp_log.get("bay", []):
		_cargo[c["id"]] = c.duplicate(true)
	_show_hold(run)
	await _wait(0.4)
	await _play_route(run, warp_log)
	var n := 0
	for step: Dictionary in warp_log.get("steps", []):
		n += 1
		await _play_step(n, step, run)
	_stars.speed = 1.0
	_stage.rotation = 0.0
	var loss: int = warp_log.get("loss", 0)
	if loss > 0:
		# The total lost pay, before the report (SPEC Section 21.5).
		loss_text = tr(LOST_TEXT).format({"loss": loss})
		_pop(loss_text)
		await _wait(0.9)
	await _play_spoils(run)
	_finish(run)


func _show_hold(run: Dictionary) -> void:
	var cargo := []
	for id: int in _sorted_ids():
		cargo.append(_cargo[id])
	_hold.set_view({"hold": run["hold"], "cargo": cargo, "links": []})
	_bay.set_view({"shock_bay": run["shock_bay"], "cargo": cargo, "links": []})
	if _bay.visible:
		# Room above the hold for the shock bay: the grid of the hold moves down.
		_hold.offset_top = _bay.custom_minimum_size.y
		_place_bay.call_deferred()


## Puts the shock bay above the grid of the hold, after the hold has its new size.
func _place_bay() -> void:
	_bay.size = _bay.custom_minimum_size
	_bay.position = Vector2((_hold.size.x - _bay.size.x) / 2.0, _hold.grid_origin().y - _bay.size.y)


func _sorted_ids() -> Array:
	var ids := _cargo.keys()
	ids.sort()
	return ids


func _play_step(n: int, step: Dictionary, run: Dictionary) -> void:
	var d: String = step["direction"]
	_banner.modulate.a = 1.0
	if step.has("options"):
		# A fork step: show the two directions, then the one that happens (SPEC Section 20.3).
		var names := PackedStringArray()
		for o: String in step["options"]:
			names.append(StationScreen.direction_text(o, _view))
		_banner.text = tr(FORK_TEXT).format({"n": n, "options": StationScreen.or_join(names)})
		Sound.play(self, "alarm")
		await _wait(0.9)
	_banner.text = (
		tr(STEP_TEXT)
		. format(
			{
				"n": n,
				"arrow": StationScreen.ARROWS.get(d, "?"),
				"direction": StationScreen.direction_name(d, _view),
			}
		)
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
		_play_loss(r)
		_show_hold(run)
		await _wait(REACTION_GAP)
		if r["kind"] == Defs.REACT_EXPLOSION:
			await _wait(0.1)  # The hit stop of an explosion (SPEC Section 21.3).
	_apply_after(step, run)
	var fade := create_tween()
	fade.tween_property(_banner, "modulate:a", 0.0, 0.3 / speed)
	await _wait(0.35)


## Plays the environment of the leg and the incident before the first step
## (SPEC Sections 28.1 and 29.3).
func _play_route(run: Dictionary, warp_log: Dictionary) -> void:
	var env: Dictionary = run.get("environment", {})
	if not env.is_empty():
		_banner.modulate.a = 1.0
		_banner.text = tr(env["name"])
		await _wait(0.8)
	var inc: Dictionary = warp_log.get("incident", {})
	if inc.is_empty():
		return
	incident_shown = RouteCards.incident_text(inc)
	_banner.modulate.a = 1.0
	_banner.text = incident_shown
	Sound.play(self, "alarm")
	await _wait(0.6)
	if inc.has("debris_view"):
		var d: Dictionary = inc["debris_view"].duplicate(true)
		_cargo[d["id"]] = d
		_show_hold(run)
		_fx.shards(_hold.cargo_center(d))
		Sound.play(self, "metal_hit")
	_play_hits(inc, Defs.DIR_DOWN)
	await _wait(0.3)
	for r: Dictionary in inc["reactions"]:
		_play_reaction(r)
		_play_loss(r)
		_show_hold(run)
		await _wait(REACTION_GAP)
	_apply_after(inc, run)
	await _wait(0.3)


## Keeps the hold the same as the log after a step or an incident.
func _apply_after(step: Dictionary, run: Dictionary) -> void:
	var kept := {}
	for spot: Dictionary in step["after"]:
		kept[spot["cargo"]] = true
		if _cargo.has(spot["cargo"]):
			var c: Dictionary = _cargo[spot["cargo"]]
			c["x"] = spot["x"]
			c["y"] = spot["y"]
			c["kind"] = spot["kind"]
	for id: int in _cargo.keys():
		# The log of a step has the hold only: the shock bay does not change (SPEC Section 31.1).
		if not kept.has(id) and not _cargo[id].get("in_bay", false):
			_remove(id)
	_show_hold(run)


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
	# The log tells what the reaction does to the cargo; the kind picks the effect.
	match r.get("result", Defs.RESULT_KEPT):
		Defs.RESULT_SCRAP:
			_to_scrap(c)
		Defs.RESULT_REMOVED:
			_remove(r["cargo"])
	match r["kind"]:
		Defs.REACT_BREAK, Defs.REACT_BLAST:
			_fx.shards(at)
			Sound.play(self, "glass_break")
		Defs.REACT_LEAK:
			_fx.leak(at)
			Sound.play(self, "splash")
		Defs.REACT_SHORT:
			_fx.bolts(at)
			Sound.play(self, "buzz")
		Defs.REACT_EXPLOSION:
			var cells := []
			for cell: Dictionary in r.get("area", []):
				cells.append(Vector2i(cell["x"], cell["y"]))
			_fx.explosion(at, cells)
			Sound.play(self, "explosion")
			_shake_screen(28.0)
		Defs.REACT_CLEAR:
			_fx.shards(at)
		Defs.REACT_SHIELD:
			_fx.bubble(at)
			Sound.play(self, "shield")


## Shows the lost pay of a reaction, and the chain count from the second
## reaction of a chain (SPEC Section 21.5).
func _play_loss(r: Dictionary) -> void:
	var c: Dictionary = _cargo.get(r["cargo"], {})
	if r.get("loss", 0) > 0 and not c.is_empty():
		_fx.loss(_hold.cargo_center(c), r["loss"])
	var chain: int = r.get("chain", 1)
	if chain >= 2:
		chain_shown = maxi(chain_shown, chain)
		_pop(tr(CHAIN_TEXT).format({"count": chain}))


## Shows a text below the banner with a small pop, then fades it.
func _pop(text: String) -> void:
	_loss_label.text = text
	_loss_label.modulate.a = 1.0
	_loss_label.pivot_offset = _loss_label.size / 2.0
	_loss_label.scale = Vector2.ONE * 1.3
	var t := create_tween()
	t.tween_property(_loss_label, "scale", Vector2.ONE, 0.15 / speed)
	t.tween_interval(0.6 / speed)
	t.tween_property(_loss_label, "modulate:a", 0.0, 0.3 / speed)


## Hides a cargo that a reaction removed. It stays in the view, so that the report
## can mark its place (SPEC Section 20.4).
func _remove(id: int) -> void:
	_hold.fades[id] = 0.0
	_hold.queue_redraw()


func _to_scrap(c: Dictionary) -> void:
	c["kind"] = Defs.KIND_SCRAP
	c["traits"] = []


## Plays the spoils of the arrival: a green cloud on each spoiled cargo (SPEC Section 21.3).
func _play_spoils(run: Dictionary) -> void:
	for id: int in run["arrival"].get("spoiled", []):
		if _cargo.has(id):
			_fx.cloud(_center_of(_cargo[id]))
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
		if not stays.has(id) and _hold.fades.get(id, 1.0) > 0.0:
			# Delivered freight stays at half alpha with a check mark (SPEC Section 20.4).
			if fade == null:
				fade = create_tween().set_parallel(true)
			_hold.fades[id] = 1.0
			_hold.checks[id] = true
			fade.tween_method(func(a: float) -> void: _fade(id, a), 1.0, DELIVERED_ALPHA, 0.6)
	if run["arrival"]["total"] != 0 and not _replaying:
		Sound.play(self, "coin")
		_coin_on_report.call_deferred()
	_report.show_report(run)
	_report.visible = true
	_make_room_for_report.call_deferred()
	_skip_label.visible = false
	_banner.text = ""
	finished = true
	_report.continue_button.grab_focus()
	playback_finished.emit()


## Plays the warp again from the start at half speed (SPEC Section 20.4).
func _start_replay() -> void:
	if not finished:
		return
	finished = false
	_replaying = true
	_report.visible = false
	_skip_label.visible = true
	_mark_pieces([])
	_cargo.clear()
	_hold.fades.clear()
	_hold.checks.clear()
	_hold.offsets.clear()
	speed = float(Settings.get_value("warp_speed")) * REPLAY_SPEED
	_fx.speed = speed
	_stars.speed = 30.0
	_play()


func _mark_pieces(ids: Array) -> void:
	_hold.marked = ids
	_hold.queue_redraw()
	_bay.marked = ids
	_bay.queue_redraw()


## The report has its place after one frame: the containers sort it then.
func _coin_on_report() -> void:
	await get_tree().process_frame
	_top_fx.coin(_report.head.get_global_rect().get_center())


## Moves the hold to the left when the report covers it (SPEC Section 20.4).
func _make_room_for_report() -> void:
	await get_tree().process_frame
	var right := _hold.global_position.x + _hold.grid_origin().x + _hold.columns * _hold.cell
	var overlap := right + REPORT_GAP - _report.global_position.x
	if overlap > 0.0:
		create_tween().tween_property(_hold, "position:x", _hold.position.x - overlap, 0.4)


## Returns the center of a cargo in the coordinates of the hold, also for a cargo in
## the shock bay.
func _center_of(c: Dictionary) -> Vector2:
	if c.get("in_bay", false):
		return _bay.position + _bay.cargo_center(c)
	return _hold.cargo_center(c)


func _fade(id: int, a: float) -> void:
	_hold.fades[id] = a
	_hold.queue_redraw()
	_bay.queue_redraw()


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
