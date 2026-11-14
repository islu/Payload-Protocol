# The hint texts are sentences for the player, so their lines are long.
# gdlint: disable=max-line-length
class_name Hints
## The hints of the first runs (SPEC Section 23.3). The pilot gives one hint for
## each new thing, in order. A hint ends when the player does its thing. The
## hints that ended are in the setting "hints_seen". This is presentation: the
## hints read the view, and they keep no game state.

const ACCEPT := "accept"
const DRAG := "drag"
const ROTATE := "rotate"
const HAZARD := "hazard"
const WARP := "warp"
const ORDER: PackedStringArray = [ACCEPT, DRAG, ROTATE, HAZARD, WARP]
## The game turns the hints off when this many runs started before a new run (SPEC Section 23.3).
const RUNS_WITH_HINTS := 3

const HINT_TEXT := {
	ACCEPT: "Accept a contract on the left. Its freight goes to the dock.",
	DRAG: "Drag a cargo from the dock into the hold. Or click it, then click a cell.",
	ROTATE: "Right click a cargo in the hold to rotate it. While you hold one, press R.",
	HAZARD:
	"Read the hazard at the top: each step slides all cargo that way. Fragile cargo breaks at a strong hit.",
	WARP: "When the hold is ready, press WARP.",
}


## Returns the hint to show now, or "" (SPEC Section 23.3).
static func current(run: Dictionary) -> String:
	if not Settings.get_value("hints") or run.is_empty() or run["phase"] != Defs.PHASE_STATION:
		return ""
	var seen: Array = Array(Settings.get_value("hints_seen")).duplicate()
	for id in ORDER:
		if id in seen:
			continue
		if _done(id, run):
			seen.append(id)
			Settings.set_value("hints_seen", seen)
			continue
		return id
	return ""


## Ends a hint that the view cannot show: a rotation, or a warp.
static func done(id: String) -> void:
	var seen: Array = Array(Settings.get_value("hints_seen")).duplicate()
	if not id in seen:
		seen.append(id)
		Settings.set_value("hints_seen", seen)


static func text(id: String) -> String:
	return HINT_TEXT.get(id, "")


static func _done(id: String, run: Dictionary) -> bool:
	match id:
		ACCEPT:
			for k: Dictionary in run["contracts"]:
				if k["accepted"]:
					return true
		DRAG:
			for c: Dictionary in run["cargo"]:
				if (c["in_hold"] or c["in_bay"]) and c["kind"] != Defs.KIND_SCRAP:
					return true
	return false


## Counts a new run. After the first runs, the game turns the hints off (SPEC Section 23.3).
static func run_started() -> void:
	var runs: int = Settings.get_value("runs_started") + 1
	Settings.set_value("runs_started", runs)
	if runs > RUNS_WITH_HINTS:
		Settings.set_value("hints", false)


## The first win turns the hints off (SPEC Section 23.3).
static func run_won() -> void:
	Settings.set_value("hints", false)
