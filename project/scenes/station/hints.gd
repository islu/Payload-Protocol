# The hint texts are sentences for the player, so their lines are long.
# gdlint: disable=max-line-length
class_name Hints
## The hints of the first runs (SPEC Section 23.3). The pilot gives one hint for
## each new thing that the tutorial does not teach, the first time that the player
## sees it. A hint of the station ends at the warp, and a hint of an event or a mod
## choice ends at the pick. The hints that ended are in the setting "hints_seen". This is presentation: the
## hints read the view, and they keep no game state.

const ENVIRONMENT := "environment"
const INCIDENT := "incident"
const FORK := "fork"
const LONG := "long"
const VIP := "vip"
const SENSOR := "sensor"
const BAY := "bay"
const EVENT := "event"
const MOD := "mod"
## The hints of the station, in order: one shows at a time.
const ORDER: PackedStringArray = [ENVIRONMENT, INCIDENT, FORK, LONG, VIP, SENSOR, BAY]
## The game turns the hints off when this many runs started before a new run (SPEC Section 23.3).
const RUNS_WITH_HINTS := 3

const HINT_TEXT := {
	ENVIRONMENT:
	"This leg has an environment. Its rule is below the route. It holds for each jump of the leg.",
	INCIDENT: "An incident hits before the first step. The hold marks its place.",
	FORK: "The last step is a fork: one of two directions. A Sensor in the hold shows which one.",
	LONG: "A LONG contract stays in the hold for more than one jump. It pays at its last jump.",
	VIP: "A VIP contract pays a penalty for each piece that does not arrive intact.",
	SENSOR: "The Sensor shows the fork step only while it is in the hold or the shock bay.",
	BAY:
	"Cargo in the shock bay does not slide, takes no hits, and has no mass. Only kit and scrap go in it.",
	EVENT: "An event: each choice has a cost and an effect. Read both before you pick.",
	MOD: "A mod changes a rule of the ship for the rest of the run. Pick one.",
}


## Returns the hint of the station now, or "": the first hint in ORDER that the
## player did not see, for a thing that the station shows (SPEC Section 23.3).
static func current(run: Dictionary) -> String:
	if not Settings.get_value("hints") or run.is_empty() or run["phase"] != Defs.PHASE_STATION:
		return ""
	var seen: Array = Settings.get_value("hints_seen")
	for id in ORDER:
		if not id in seen and _shows(id, run):
			return id
	return ""


## Returns the hint of an event or a mod choice (EVENT or MOD), or "" when the player
## saw it or the hints are off (SPEC Section 23.3).
static func for_panel(id: String) -> String:
	if not Settings.get_value("hints") or id in Settings.get_value("hints_seen"):
		return ""
	return id


## Ends a hint: the station warps, or the player picks a choice. It does not show again.
static func done(id: String) -> void:
	if id == "":
		return
	var seen: Array = Array(Settings.get_value("hints_seen")).duplicate()
	if not id in seen:
		seen.append(id)
		Settings.set_value("hints_seen", seen)


static func text(id: String) -> String:
	return HINT_TEXT.get(id, "")


## Reports whether the station shows the thing of a hint.
static func _shows(id: String, run: Dictionary) -> bool:
	var fork: bool = run["hazard"].any(func(s: Dictionary) -> bool: return s["fork"])
	match id:
		ENVIRONMENT:
			return not run.get("environment", {}).is_empty()
		INCIDENT:
			return not run.get("incident", {}).is_empty()
		FORK:
			return fork
		LONG:
			return run["contracts"].any(func(k: Dictionary) -> bool: return k["jumps"] > 1)
		VIP:
			return run["contracts"].any(func(k: Dictionary) -> bool: return k["penalty"] > 0)
		SENSOR:
			return (
				fork
				and run["cargo"].any(
					func(c: Dictionary) -> bool: return Defs.TRAIT_SENSOR in c["traits"]
				)
			)
		BAY:
			return not run.get("shock_bay", {}).is_empty()
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
