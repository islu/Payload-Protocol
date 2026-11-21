class_name Tutorial
extends RefCounted
## The steps of the tutorial (SPEC Section 23.4). A step ends when the run shows its
## action, or with Next for a step with no action. A try step ends at the arrival when
## each piece is delivered. Else it fails, and the tutorial goes back to the station
## before the warp (RunRecord.back_to_warp). The steps read the run; they do not change it.

## Each step: {text, target, until, cargo, try, fail, jump}.
var _steps: Array[Dictionary] = []
var _index := 0
var _failed := false


func _init(data: Dictionary) -> void:
	var jumps: Array = data.get("jumps", [])
	for j in jumps.size():
		for s: Dictionary in jumps[j]["steps"]:
			var step := s.duplicate()
			step["jump"] = j + 1
			_steps.append(step)


## Reports whether each step is done.
func done() -> bool:
	return _index >= _steps.size()


## Reports whether the goal of the try step failed.
func failed() -> bool:
	return _failed


## Returns the step now for the screen: {done, text, target, try, next, failed, fail,
## index, count, jump}. fail is the text of a failed try step. next is true for a
## step with no action.
func view() -> Dictionary:
	if done():
		return {"done": true, "index": _index, "count": _steps.size()}
	var s := _steps[_index]
	return {
		"done": false,
		"text": s["text"],
		"target": s["target"],
		"try": s["try"],
		"next": s["until"] == Defs.TUT_NEXT,
		"failed": _failed,
		"fail": s["fail"],
		"index": _index,
		"count": _steps.size(),
		"jump": s["jump"],
	}


## Ends a step with no action. It returns false for a step with an action.
func next() -> bool:
	if done() or _steps[_index]["until"] != Defs.TUT_NEXT:
		return false
	_index += 1
	return true


## Starts the try step again after the tutorial went back before the warp.
func retry() -> void:
	_failed = false


## Ends each step whose action the run shows, in order. A try step that ends with a
## piece that is not delivered fails, and does not end.
func update(run: Run) -> void:
	while not done() and not _failed:
		var s := _steps[_index]
		if s["until"] == Defs.TUT_NEXT or not _met(run, s):
			return
		if s["try"] and not _all_delivered(run):
			_failed = true
			return
		_index += 1


## Reports whether the run shows the action of a step.
static func _met(run: Run, s: Dictionary) -> bool:
	var after_warp: bool = run.jump > s["jump"] or run.phase != Defs.PHASE_STATION
	match s["until"]:
		Defs.TUT_ACCEPT:
			return (
				not run.contracts.is_empty()
				and run.contracts.all(func(k: Contract) -> bool: return k.accepted)
			)
		Defs.TUT_ALL_IN_HOLD:
			return (
				run.contracts.any(func(k: Contract) -> bool: return k.accepted)
				and run.dock.all(
					func(id: int) -> bool: return run.cargo[id].kind != Defs.KIND_FREIGHT
				)
			)
		Defs.TUT_ROTATE:
			return run.cargo.values().any(
				func(c: Cargo) -> bool: return c.def.id == s["cargo"] and c.rot != 0
			)
		Defs.TUT_CLAMP:
			return run.cargo.values().any(func(c: Cargo) -> bool: return c.clamped)
		Defs.TUT_BUY:
			return run.cargo.values().any(func(c: Cargo) -> bool: return c.def.id == s["cargo"])
		Defs.TUT_FRESH:
			var cold := run.hold_cargo().filter(
				func(c: Cargo) -> bool: return c.has(Defs.TRAIT_PERISHABLE)
			)
			return not cold.is_empty() and Arrival.spoil_check(run).is_empty()
		Defs.TUT_WARP:
			return after_warp
		Defs.TUT_CONTINUE:
			return run.jump > s["jump"] or run.phase in [Defs.PHASE_PAYMENT, Defs.PHASE_END]
		Defs.TUT_PAY:
			return run.phase == Defs.PHASE_END
	return false


## Reports whether each piece of the last arrival is delivered.
static func _all_delivered(run: Run) -> bool:
	for k: Dictionary in run.last_arrival.get("contracts", []):
		for p: Dictionary in k["pieces"]:
			if p["state"] != Defs.PIECE_DELIVERED:
				return false
	return true
