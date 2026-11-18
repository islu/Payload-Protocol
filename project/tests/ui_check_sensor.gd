class_name UiCheckSensor
## The Sensor warning part of the UI check (ui_check.gd). It is in its own file, so
## that ui_check.gd stays under the line limit of gdlint.


## Gives the station a fork step and a Sensor in the hold, then moves the Sensor to
## the dock: the station warns that the fork step is hidden again (SPEC Section 18.1).
## At the end, the run has its hazard again and no Sensor.
static func check(ui: Node, station: StationScreen) -> void:
	var saved := {}
	var sensor := [0]
	GameState.set_up(
		func(r: Run) -> void:
			saved["hazard"] = r.hazard
			saved["fork"] = r.fork_options
			r.hazard = PackedStringArray([Defs.DIR_LEFT, Defs.DIR_UP])
			r.fork_options = PackedStringArray([Defs.DIR_UP, Defs.DIR_RIGHT])
			var c := r.new_cargo(r.cat.cargo["sensor_array"])
			sensor[0] = c.id
			for y in r.rows:
				for x in r.columns:
					if not c.in_hold and r.fits(c, Vector2i(x, y), 0):
						r.place_cargo(c.id, Vector2i(x, y), 0)
	)
	await ui.get_tree().process_frame
	ui._check(
		station._toast.text != station.tr(StationScreen.SENSOR_LOST_TEXT),
		"a Sensor that shows the fork step gives no warning (SPEC Section 18.1)"
	)
	GameState.set_up(func(r: Run) -> void: r.dock_cargo(sensor[0]))
	await ui.get_tree().process_frame
	ui._check(
		station._toast.text == station.tr(StationScreen.SENSOR_LOST_TEXT),
		"the last Sensor leaves the hold: the station warns (SPEC Section 18.1)"
	)
	station._toast.text = ""
	GameState.set_up(
		func(r: Run) -> void:
			r.hazard = saved["hazard"]
			r.fork_options = saved["fork"]
			r.dock.erase(sensor[0])
			r.cargo.erase(sensor[0])
	)
	await ui.get_tree().process_frame
	ui._check(station._toast.text == "", "a hazard with no known fork step gives no warning")
