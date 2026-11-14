class_name Route
## The route of a run: the hazard of each jump (SPEC Section 18), the environment of
## each leg (SPEC Section 28), and the incident of each jump (SPEC Section 29). The
## functions take the rng of the run, so keep the order of the calls.


## Selects the shift steps of the next jump (SPEC Section 18). Two steps next
## to each other have different directions.
## In a leg with fork steps, the last step is a fork step (SPEC Section 18): two
## directions that are not the step before it and not opposite to each other. The
## seed selects the direction that happens now. It sets run.fork_options.
static func make_hazard(run: Run) -> PackedStringArray:
	var s: Dictionary = run.cat.legs[run.leg - 1]
	var span: Vector2i = s["hazard_steps"][run.jump - 1]
	var n := run.rng.randi_range(span.x, span.y)
	var steps: PackedStringArray = []
	run.fork_options = PackedStringArray()
	for i in n:
		var choices: PackedStringArray = []
		for d in Defs.DIRECTIONS:
			if steps.is_empty() or steps[-1] != d:
				choices.append(d)
		if i == n - 1 and s["fork"]:
			var pairs: Array = []
			for a in choices.size():
				for b in range(a + 1, choices.size()):
					if Defs.delta(choices[a]) != -Defs.delta(choices[b]):
						pairs.append(PackedStringArray([choices[a], choices[b]]))
			run.fork_options = pairs[run.rng.randi_range(0, pairs.size() - 1)]
			steps.append(run.fork_options[run.rng.randi_range(0, 1)])
		else:
			steps.append(choices[run.rng.randi_range(0, choices.size() - 1)])
	return steps


## Selects the environment of a new leg. Two legs do not have the same one
## (SPEC Section 28.1).
static func pick_environment(run: Run) -> void:
	var last := run.environment
	run.environment = ""
	if not run.cat.legs[run.leg - 1].get("environment", false):
		return
	var pool: Array = []
	for id in Defs.ENVIRONMENTS:
		if id != last and run.cat.environments.has(id):
			pool.append(id)
	if not pool.is_empty():
		run.environment = pool[run.rng.randi_range(0, pool.size() - 1)]


## Selects the incident of the next jump, with its place (SPEC Section 29.1). The
## place has a cargo when the hold has one.
static func make_incident(run: Run) -> Dictionary:
	var percent: int = run.cat.legs[run.leg - 1].get("incident_percent", 0)
	if percent <= 0 or run.rng.randi_range(1, 100) > percent:
		return {}
	var kind: String = Defs.INCIDENTS[run.rng.randi_range(0, Defs.INCIDENTS.size() - 1)]
	var cells: Array = run.occupancy().keys()
	cells.sort()
	if cells.is_empty():
		for y in run.rows:
			for x in run.columns:
				cells.append(Vector2i(x, y))
	var cell: Vector2i = cells[run.rng.randi_range(0, cells.size() - 1)]
	match kind:
		Defs.INCIDENT_METEOR:
			return {"kind": kind, "x": cell.x}
		Defs.INCIDENT_ION_PULSE:
			return {"kind": kind, "y": cell.y}
	return {"kind": kind, "x": cell.x, "y": cell.y}
