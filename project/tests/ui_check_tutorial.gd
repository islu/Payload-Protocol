class_name UiCheckTutorial
## The tutorial part of the UI check (ui_check.gd): the first New Run, the guide, the
## open areas of each step, a failed try step, the end, and Skip (SPEC Sections 20.1
## and 23.4). It is in its own file, so that ui_check.gd stays under the line limit.
## At the end, the tutorial is done and the title shows.

## The places of the known solution, as in test_data.gd: [cargo, x, y, rotation].
const PLAN := [
	[["steel_ingot", 5, 2, 1], ["cargo_crate", 5, 1, 0], ["energy_crystal", 5, 0, 0]],
	[
		["steel_ingot", 0, 5, 0],
		["coolant_pipe", 0, 3, 0],
		["plasma_cell", 3, 5, 0],
		["specimen_tube", 4, 0, 0]
	],
	[
		["cooler_unit", 0, 0, 0],
		["space_cheese", 1, 0, 0],
		["space_cheese", 1, 1, 0],
		["cargo_crate", 0, 2, 0],
		["cargo_crate", 1, 2, 0]
	],
]


static func check(ui: Node, main: Control) -> void:
	var title: Control = main.screen()
	ui._check(
		title.find_child("TutorialButton", true, false) != null,
		"the title has a Tutorial button (SPEC Section 20.1)"
	)
	Settings.set_value("tutorial_done", false)
	var runs: int = Settings.get_value("runs_started")
	var new_run: Button = title.find_child("NewRunButton", true, false)
	new_run.pressed.emit()
	await _frames(ui, 3)
	var guide: TutorialGuide = main.guide
	ui._check(
		not GameState.view()["tutorial"].is_empty() and guide.visible,
		"the first New Run starts the tutorial with its guide (SPEC Section 23.4)"
	)
	ui._check(
		Settings.get_value("runs_started") == runs,
		"the tutorial does not count as a run for the hints (SPEC Section 23.3)"
	)
	ui._check(
		guide.next_button.visible and not guide.retry_button.visible and guide.skip_button.visible,
		"a step with no action has Next, and Skip Tutorial is on the screen (SPEC Section 23.4)"
	)
	guide.next_button.pressed.emit()
	await _frames(ui, 2)
	ui._check(
		guide.step["index"] == 1 and guide.open_rects.size() == 1,
		"Next ends the step; the contract step opens one area (SPEC Section 23.4)"
	)
	if guide.open_rects.size() == 1:
		var inside := guide.open_rects[0].get_center()
		ui._check(
			not guide._has_point(inside) and guide._has_point(Vector2(2, 2)),
			"only the target takes the mouse: the rest of the screen is dark (SPEC Section 23.4)"
		)
	# The first try step fails: the crystal at the left wall slides 5 cells.
	await _do(ui, guide, func() -> String: return GameState.accept_contract(0))
	await _place(
		ui, guide, [["steel_ingot", 0, 2, 1], ["cargo_crate", 0, 1, 0], ["energy_crystal", 0, 0, 0]]
	)
	await _warp(ui, main, guide)
	ui._check(
		guide.step["failed"] and guide.retry_button.visible and guide.open_rects.is_empty(),
		"a failed try step shows why, and Try Again (SPEC Section 23.4)"
	)
	guide.retry_button.pressed.emit()
	await _frames(ui, 3)
	ui._check(
		GameState.view()["run"]["phase"] == Defs.PHASE_STATION and not guide.step["failed"],
		"Try Again goes back to the station before the warp (SPEC Section 23.4)"
	)
	for j in 3:
		if j > 0:
			await _do(ui, guide, func() -> String: return GameState.accept_contract(0))
			if not GameState.view()["run"]["shop"]["offers"].is_empty():
				await _do(ui, guide, func() -> String: return GameState.buy_kit(0))
		await _place(ui, guide, PLAN[j])
		if j == 1:
			var tube := _id_of("specimen_tube")
			await _do(ui, guide, func() -> String: return GameState.clamp_cargo(tube))
		await _warp(ui, main, guide)
		ui._check(not guide.step["failed"], "the try step of jump %d is met" % (j + 1))
		await _do(ui, guide, func() -> String: return GameState.continue_run())
	await _do(ui, guide, func() -> String: return GameState.make_payment())
	ui._check(
		guide.step["done"] and guide.start_button.visible and not guide.skip_button.visible,
		"the end of the tutorial shows Tutorial complete and Start a Run (SPEC Section 23.4)"
	)
	guide.start_button.pressed.emit()
	await _frames(ui, 3)
	ui._check(
		GameState.view()["tutorial"].is_empty() and Settings.get_value("tutorial_done"),
		"after the tutorial, a normal run starts, and the tutorial is done (SPEC Section 23.4)"
	)
	# Skip: the Tutorial button starts it again, and Skip Tutorial ends it.
	GameState.start_tutorial()
	await _frames(ui, 2)
	guide.skip_button.pressed.emit()
	ui._check(guide._confirm.visible, "Skip Tutorial asks to confirm (SPEC Section 23.4)")
	guide._confirm.confirmed.emit()
	guide._confirm.hide()
	await _frames(ui, 2)
	ui._check(
		GameState.view()["tutorial"].is_empty() and not GameState.view()["run"].is_empty(),
		"after Skip Tutorial, a normal run starts (SPEC Section 23.4)"
	)
	GameState.abandon_run()
	await _frames(ui, 2)


## Does an action, then checks that the step now opens an area on the screen when
## it has a target.
static func _do(ui: Node, guide: TutorialGuide, action: Callable, look := true) -> void:
	var err: String = action.call()
	ui._check(err == "", "tutorial action: %s" % err)
	await _frames(ui, 2)
	while guide.step.get("next", false) and not guide.step["failed"]:
		guide.next_button.pressed.emit()
		await _frames(ui, 2)
	if look:
		_check_open(ui, guide)


## Checks that the step now opens an area on the screen when it has a target.
static func _check_open(ui: Node, guide: TutorialGuide) -> void:
	var t: Dictionary = guide.step.get("target", {})
	if not guide.step["done"] and not guide.step["failed"] and t.get("kind", "none") != "none":
		ui._check(
			not guide.open_rects.is_empty(),
			'the step "%s" opens its target on the screen (SPEC Section 23.4)' % guide.step["text"]
		)


static func _place(ui: Node, guide: TutorialGuide, places: Array) -> void:
	for p: Array in places:
		var id := _id_of(p[0])
		await _do(ui, guide, func() -> String: return GameState.place_cargo(id, p[1], p[2], p[3]))


## Plays the warp to its report.
static func _warp(ui: Node, main: Control, guide: TutorialGuide) -> void:
	await _do(ui, guide, func() -> String: return GameState.warp(), false)
	var warp: Control = main.screen()
	if warp is WarpScreen:
		warp.speed_up()
		warp.speed = 200.0
		var frames := 0
		while not warp.finished and frames < 2000:
			frames += 1
			await ui.get_tree().process_frame
	await _frames(ui, 2)
	_check_open(ui, guide)


## Returns the ID of the first cargo of a definition on the dock, else in the hold.
static func _id_of(def_id: String) -> int:
	var found := -1
	for c: Dictionary in GameState.view()["run"]["cargo"]:
		if c["def_id"] != def_id:
			continue
		if not c["in_hold"] and not c["in_bay"]:
			return c["id"]
		if found < 0:
			found = c["id"]
	return found


static func _frames(ui: Node, n: int) -> void:
	for i in n:
		await ui.get_tree().process_frame
