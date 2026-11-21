class_name UiCheckPhase
## The report, the payment, and the run end part of the UI check (ui_check.gd):
## SPEC Sections 19.2, 20.4, 20.5, and 20.6. It is in its own file, so that
## ui_check.gd stays under the line limit.

## The smallest size of a large number: display text (SPEC Section 4.2).
const LARGE := 40


## The report fits its content, the hold and the report are one group at the center,
## and the bar of the leg shows (SPEC Section 20.4).
static func report(ui: Node, warp: WarpScreen) -> void:
	await ui.get_tree().process_frame
	await ui.get_tree().process_frame
	var panel := warp._report
	var rect := panel.get_global_rect()
	ui._check(
		absf(rect.size.y - panel.get_combined_minimum_size().y) < 2.0,
		(
			"the report fits its content: %d px high, content %d px (SPEC Section 20.4)"
			% [rect.size.y, panel.get_combined_minimum_size().y]
		)
	)
	var hold := warp._hold
	var left := hold.global_position.x + hold.grid_origin().x - HoldView.FRAME
	if warp._bay.visible:
		left = minf(left, warp._bay.get_global_rect().position.x)
	var screen := ui.get_viewport().get_visible_rect().size
	ui._check(
		absf(left - (screen.x - rect.end.x)) < 4.0,
		(
			"the hold and the report are centered: %d px left, %d px right (SPEC Section 20.4)"
			% [left, screen.x - rect.end.x]
		)
	)
	var p: Dictionary = GameState.view()["run"]["leg_progress"]
	ui._check(
		(
			panel.progress_bar != null
			and panel.progress_bar.value == p["credits"]
			and panel.progress_bar.maximum == p["payment"]
			and str(p["payment"]) in panel.progress_label.text
		),
		"the report shows the credits against the payment of the leg (SPEC Section 20.4)"
	)


## Pay shows the Paid stamp, and the next screen opens after it (SPEC Section 20.5).
static func payment(ui: Node, main: Control) -> void:
	await ui.get_tree().process_frame
	var panel: PhasePanel = main.screen()
	var t: Dictionary = GameState.view()["run"]["payment_screen"]
	UiCheckText.check(ui, panel, "the payment screen")
	ui._check(
		(
			panel.receipt.size() == 3
			and panel.receipt.all(
				func(l: Label) -> bool: return l.get_theme_font_size("font_size") >= LARGE
			)
			and panel.receipt[0].text == str(t["credits"])
		),
		"the payment screen shows a receipt in large numbers (SPEC Section 20.5)"
	)
	ui._check(
		panel.jump_rows.size() == t["jumps"].size(),
		"the payment screen has a row for each jump of the leg (SPEC Section 20.5)"
	)
	var next: Dictionary = t["next"]
	ui._check(
		(
			(next.is_empty() and panel.next_label == null)
			or (panel.next_label != null and str(next["payment"]) in panel.next_label.text)
		),
		"the payment screen shows the next leg (SPEC Section 20.5)"
	)
	if not t["can_pay"]:
		Sound.requested.clear()
		await _wait_hit(ui, panel)
		ui._check(
			(
				panel.stamp.visible
				and panel.stamp.text == ui.tr(PhasePanel.MISSED_TEXT)
				and Sound.requested.has("stamp")
				and panel.shake > PhasePanel.PAID_SHAKE
			),
			(
				"a missed payment stamps a red Missed mark, with a stronger shake"
				+ " (SPEC Section 20.5)"
			)
		)
		panel.pay_button.pressed.emit()
		await ui.get_tree().process_frame
		return
	ui._check(not panel.stamp.visible, "the stamp shows after Pay (SPEC Section 20.5)")
	Sound.requested.clear()
	panel.pay_button.pressed.emit()
	await _wait_hit(ui, panel)
	var tool: Control = panel.stamp.handle
	ui._check(
		(
			GameState.view()["run"]["phase"] == Defs.PHASE_PAYMENT
			and panel.stamp.visible
			and panel.stamp.text == ui.tr(PhasePanel.PAID_TEXT)
			and tool.visible
		),
		"after Pay, a rubber stamp comes down before the next screen (SPEC Section 20.5)"
	)
	ui._check(
		(
			Sound.requested.has("stamp")
			and panel.shake == PhasePanel.PAID_SHAKE
			and panel.stamp.played.has("ink")
		),
		(
			"at the hit, the stamp sound plays, the receipt shakes, and ink flies out"
			+ " (SPEC Section 20.5)"
		)
	)
	var frames := 0
	var lifted := false
	while GameState.view()["run"]["phase"] == Defs.PHASE_PAYMENT and frames < 2000:
		frames += 1
		if panel.stamp.played.has("lift") and not lifted:
			lifted = true
			ui._check(
				not tool.visible and panel.stamp.mark.visible and panel.stamp.mark.material != null,
				(
					"the stamp lifts away, and the worn ink mark stays on the receipt"
					+ " (SPEC Section 20.5)"
				)
			)
		await ui.get_tree().process_frame
	ui._check(lifted, "the stamp lifts away before the next screen opens (SPEC Section 20.5)")
	ui._check(
		GameState.view()["run"]["phase"] != Defs.PHASE_PAYMENT,
		"after the stamp, the next screen opens (SPEC Section 20.5)"
	)


## Waits until the rubber stamp hits the receipt, or for 3 seconds.
static func _wait_hit(ui: Node, panel: PhasePanel) -> void:
	var end := Time.get_ticks_msec() + 3000
	while not panel.stamp.played.has("hit") and Time.get_ticks_msec() < end:
		await ui.get_tree().process_frame


## The run end shows the score, the tiles, a row for each leg, and the ship
## (SPEC Sections 19.2 and 20.6).
static func end(ui: Node, main: Control) -> void:
	await ui.get_tree().process_frame
	var panel: PhasePanel = main.screen()
	var e: Dictionary = GameState.view()["run"]["end"]
	UiCheckText.check(ui, panel, "the run end")
	ui._check(
		(
			panel.score_label != null
			and panel.score_label.text == str(e["score"])
			and panel.score_label.get_theme_font_size("font_size") >= LARGE
		),
		"the run end shows the score in large numbers (SPEC Section 20.6)"
	)
	ui._check(
		panel.tiles.size() == 4,
		"the run end has a tile for delivered, scrap, explosions, and the best jump (SPEC 19.2)"
	)
	ui._check(
		panel.leg_rows.size() == e["legs"].size(),
		"the run end has a row for each leg that started (SPEC Section 19.2)"
	)
	var ship := ""
	for n in panel.ship_card.find_children("*", "Label", true, false):
		ship += (n as Label).text + "\n"
	var mods_ok := true
	for m: Dictionary in e["ship"]["mods"]:
		mods_ok = mods_ok and ui.tr(m["name"]) in ship
	ui._check(
		mods_ok and e["seed"] in ship and panel.copy_button != null,
		"the run end shows the ship, the seed, and a Copy button (SPEC Section 19.2)"
	)
