class_name UiCheckTitle
## The cargo ship of the title part of the UI check (ui_check.gd): SPEC Section 20.1.
## It is in its own file, so that ui_check.gd stays under the line limit.


## A cargo ship flies behind the menu: in at the middle of the right edge, down to the left
## of the menu, a stop where cells of cargo fly up into it, out at the bottom left, and a
## pause. It grows as it comes in, and more as it flies out (SPEC Section 20.1).
static func check(ui: Node, main: Control) -> void:
	var screen: Control = main.screen()
	var ship: Control = screen.find_child("TitleShip", true, false)
	var menu: Control = screen.find_child("TitleMenu", true, false)
	ui._check(
		ship != null and ship.get("texture") != null,
		"the title shows a cargo ship (SPEC Section 20.1)"
	)
	if ship == null or not ship.has_method("ship_center"):
		ui._check(false, "the title ship has a cycle of its flight (SPEC Section 20.1)")
		return
	var behind := true
	for n in screen.get_children():
		if n == menu or n.is_ancestor_of(menu):
			behind = screen.get_children().find(n) > screen.get_children().find(ship)
	ui._check(
		behind and ship.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"the ship is behind the menu, and it does not take the clicks (SPEC Section 20.1)"
	)
	var view := ui.get_viewport().get_visible_rect().size
	var enter: float = ship.ENTER_TIME
	var dock_end: float = enter + ship.DOCK_TIME
	var leave_end: float = dock_end + ship.LEAVE_TIME
	ship.time = 0.0
	var start: Vector2 = ship.ship_center()
	var start_scale: float = ship.ship_scale()
	ui._check(
		start.x >= view.x * 0.95 and absf(start.y - view.y / 2.0) < view.y * 0.05,
		"the ship comes in at the middle of the right edge: %s (SPEC Section 20.1)" % start
	)
	ship.time = enter / 2.0
	var mid: Vector2 = ship.ship_center()
	ship.time = enter + 0.5
	var dock: Vector2 = ship.ship_center()
	var dock_scale: float = ship.ship_scale()
	ship.time = dock_end - 0.5
	var dock_late: Vector2 = ship.ship_center()
	var menu_rect := menu.get_global_rect()
	ui._check(
		(
			mid.x < start.x
			and mid.y > start.y
			and dock.x + ship.ship_size().x / 2.0 < menu_rect.position.x
			and dock.y > menu_rect.get_center().y
			and absf(dock.x - dock_late.x) < 1.0
		),
		"the ship flies down to the left of the menu and stops there: %s (SPEC Section 20.1)" % dock
	)
	ship.time = enter + 1.0
	var cells: Array = ship.cargo_cells()
	ship.time = enter + 1.1
	var later: Array = ship.cargo_cells()
	ui._check(
		(
			not cells.is_empty()
			and later.size() == cells.size()
			and later[0]["position"].y < cells[0]["position"].y
		),
		"at the stop, cells of cargo fly up into the ship (SPEC Section 20.1)"
	)
	ship.time = leave_end - 0.01
	var out: Vector2 = ship.ship_center()
	var out_scale: float = ship.ship_scale()
	ui._check(
		out.x + ship.ship_size().x / 2.0 <= 0.0 and out.y > dock.y,
		"the ship flies out at the bottom left: %s (SPEC Section 20.1)" % out
	)
	ui._check(
		start_scale < dock_scale and out_scale > dock_scale,
		(
			(
				"the ship grows as it comes in (%.1f to %.1f) and more as it flies out (%.1f)"
				% [start_scale, dock_scale, out_scale]
			)
			+ " (SPEC Section 20.1)"
		)
	)
	ship.time = leave_end + 0.5
	ui._check(not ship.ship_visible(), "after the ship flies out, a pause (SPEC Section 20.1)")
	ship.time = ship.CYCLE - 0.01
	for i in 5:
		await ui.get_tree().process_frame
	ui._check(
		ship.time < enter and ship.ship_visible(),
		"after the pause, the ship comes back (SPEC Section 20.1)"
	)
