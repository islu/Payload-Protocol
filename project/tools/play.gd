extends SceneTree
## The text player of the playtest skill. It shows only what the player sees,
## and it takes one command in each call.
##
## The game is in a session file: the seed and each action that worked. Each
## call plays the session again from the seed, then runs its command. Thus the
## same seed and the same actions give the same game (SPEC Section 3).
##
## Run it from the repository root:
##   task play -- new 7
##   task play -- do "accept 0; place 3 0 5 0; warp"
##   task play -- look
## Use -s <file> as the first arguments for another session file.

## The errors of the tutorial commands (SPEC Section 23.4).
const NOT_NEXT_TEXT := "Do the action of this step first."
const NOT_FAILED_TEXT := "The try step did not fail."
## The warning of the station when the last Sensor leaves the hold (SPEC Section 18.1).
const SENSOR_LOST_TEXT := "No Sensor: the fork step is hidden again."
const DEFAULT_SESSION := "playtest/sessions/session.json"
const ACTIONS := {
	"accept": "accept <contract>",
	"cancel": "cancel <contract>",
	"place": "place <cargo> <x> <y> [rot 0-3]",
	"dock": "dock <cargo>",
	"rotate": "rotate <cargo>",
	"clamp": "clamp <cargo>",
	"unclamp": "unclamp <cargo>",
	"buy": "buy <offer>",
	"reroll": "reroll",
	"buyclamp": "buyclamp",
	"placebay": "placebay <cargo> <x> <y> [rot 0-3] (puts it in the shock bay)",
	"bay": "bay (buys the shock bay, or makes it larger)",
	"reinforce": "reinforce (adds to the mass limit)",
	"loadall": "loadall (puts each dock cargo in the first place that fits)",
	"sell": "sell <kit>",
	"clear": "clear <scrap>",
	"warp": "warp",
	"continue": "continue",
	"pay": "pay",
	"choose": "choose <choice> (an event choice or a mod)",
	"undo": "undo (takes back the last action at this station)",
}
## The action of each command with no special form (the others: place, placebay, choose).
const COMMANDS := {
	"accept": Defs.ACT_ACCEPT,
	"cancel": Defs.ACT_CANCEL,
	"dock": Defs.ACT_DOCK,
	"rotate": Defs.ACT_ROTATE,
	"clamp": Defs.ACT_CLAMP,
	"unclamp": Defs.ACT_UNCLAMP,
	"buy": Defs.ACT_BUY_KIT,
	"reroll": Defs.ACT_REROLL,
	"buyclamp": Defs.ACT_BUY_CLAMP,
	"bay": Defs.ACT_BUY_BAY,
	"reinforce": Defs.ACT_REINFORCE,
	"loadall": Defs.ACT_LOAD_ALL,
	"sell": Defs.ACT_SELL_KIT,
	"clear": Defs.ACT_CLEAR_SCRAP,
	"warp": Defs.ACT_WARP,
	"continue": Defs.ACT_CONTINUE,
	"pay": Defs.ACT_PAY,
}

var _out: PackedStringArray = []
## The steps of the tutorial, or null in a normal run (SPEC Section 23.4).
var _tut: Tutorial


func _initialize() -> void:
	# The text player is in English, the source language (SPEC Section 4.1). Without
	# this, a translated text follows the locale of the system.
	TranslationServer.set_locale("en")
	var args := Array(OS.get_cmdline_user_args())
	var path := DEFAULT_SESSION
	if args.size() >= 2 and args[0] == "-s":
		path = args[1]
		args = args.slice(2)
	if not path.is_absolute_path():
		path = OS.get_environment("PWD").path_join(path)
	var status := _command(path, args)
	print("\n".join(_out))
	quit(status)


func _say(text: String) -> void:
	_out.append(text)


func _command(path: String, args: Array) -> int:
	if args.is_empty() or args[0] == "help":
		_usage()
		return 0
	var cat := DataFiles.catalog()
	if not cat.errors.is_empty():
		_say("the data is not valid: " + ", ".join(cat.errors))
		return 1
	if args[0] == "new":
		var tutorial: bool = args.size() > 1 and args[1] == "tutorial"
		var run_seed := 1 if tutorial else (int(args[1]) if args.size() > 1 else randi() + 1)
		var session := {"seed": run_seed, "actions": [], "tutorial": tutorial}
		_write(path, session)
		var first := RunRecord.new(cat, run_seed, tutorial)
		if tutorial:
			_tut = Tutorial.new(cat.tutorial)
			_tut.update(first.run)
		_render(first.run)
		return 0
	var session := _read(path)
	if session.is_empty():
		_say("no session at %s. Start one: new [seed]" % path)
		return 1
	var rec := RunRecord.new(cat, int(session["seed"]), session.get("tutorial", false))
	if session.get("tutorial", false):
		_tut = Tutorial.new(cat.tutorial)
		_tut.update(rec.run)
	for a: Array in session["actions"]:
		var err := _act(rec, a)
		if err != "":
			_say("the session does not replay: %s: %s" % [" ".join(a), err])
			return 1
	match args[0]:
		"look":
			_render(rec.run)
			return 0
		"history":
			for a: Array in session["actions"]:
				_say(" ".join(a))
			return 0
		"do":
			var steps := " ".join(args.slice(1)).split(";", false)
			for s in steps:
				var parts := Array(s.strip_edges().split(" ", false))
				if not _step(rec, session, parts):
					break
			_write(path, session)
		_:
			_step(rec, session, args)
			_write(path, session)
	_render(rec.run)
	return 0


## Runs one action. It records the action when it works.
## An undo takes back the last action of the session (SPEC Section 20.2).
func _step(rec: RunRecord, session: Dictionary, parts: Array) -> bool:
	var undo: bool = parts[0] == "undo"
	var last: Array = session["actions"].back() if not session["actions"].is_empty() else []
	if undo and _tut != null and last in [["next"], ["retry"]]:
		_say("> undo: a tutorial step cannot be undone")
		return false
	# The traits of each cargo before the warp: a delivered cargo leaves the run.
	var traits := {}
	for c: Dictionary in RunView.view(rec.run)["cargo"]:
		traits[c["id"]] = c["traits"]
	var known := _fork_known(rec.run)
	var at := [rec.run.leg, rec.run.jump]
	var err := rec.undo() if undo else _act(rec, parts)
	if err != "":
		_say("> %s: %s" % [" ".join(parts), err])
		return false
	_say("> " + " ".join(parts))
	# The same station, and its fork step is hidden again (SPEC Section 18.1).
	if known and at == [rec.run.leg, rec.run.jump] and not _fork_known(rec.run):
		_say("WARNING: " + SENSOR_LOST_TEXT)
	if undo:
		session["actions"].pop_back()
	else:
		session["actions"].append(parts)
	if parts[0] == "warp":
		_render_warp(rec.run, traits)
	return true


## Returns the action of a command: {name, args}, or {} for an unknown command.
func _action(run: Run, parts: Array) -> Dictionary:
	var args := parts.slice(1).map(func(v: String) -> int: return int(v))
	match parts[0]:
		"place", "placebay":
			while args.size() < 4:
				args.append(0 if args.size() == 3 else -1)
			args.append(parts[0] == "placebay")
			return {"name": Defs.ACT_PLACE, "args": args}
		"choose":
			var mod := run.phase == Defs.PHASE_MOD
			return {"name": Defs.ACT_CHOOSE_MOD if mod else Defs.ACT_CHOOSE_EVENT, "args": args}
	if not COMMANDS.has(parts[0]):
		return {}
	return {"name": COMMANDS[parts[0]], "args": args}


## Does a command on the record. It records the action when it works.
func _act(rec: RunRecord, parts: Array) -> String:
	if _tut != null and parts[0] == "next":
		if not _tut.next():
			return NOT_NEXT_TEXT
		_tut.update(rec.run)
		return ""
	if _tut != null and parts[0] == "retry":
		if not _tut.failed():
			return NOT_FAILED_TEXT
		rec.back_to_warp()
		_tut.retry()
		_tut.update(rec.run)
		return ""
	var a := _action(rec.run, parts)
	if a.is_empty():
		return "unknown command %s" % parts[0]
	var err := rec.act(a["name"], a["args"])
	if err == "" and _tut != null:
		_tut.update(rec.run)
	return err


## Reports whether the fork step of the next jump is known: a Sensor shows it
## (SPEC Section 18.1).
func _fork_known(run: Run) -> bool:
	var hazard := RunView.hazard(run)
	return not hazard.is_empty() and hazard[-1]["fork"] and hazard[-1]["known"] != ""


func _usage() -> void:
	_say(
		'Commands: new [seed] | new tutorial | look | history | do "<action>; <action>" | <action>'
	)
	_say("In the tutorial: next (a step with no action) | retry (after a failed try step)")
	_say("Actions:")
	for k: String in ACTIONS:
		_say("  " + ACTIONS[k])
	_say("Cells: x goes right from 0, y goes down from 0. A rotation turns 90° clockwise.")
	_say("A cargo has one ID. The grids show it, and the actions take it.")


# --- Render: only what the player sees ---


## The width of a cell of a grid: the digits of the largest cargo ID.
func _cell_width(cargo: Array) -> int:
	var top := 1
	for c: Dictionary in cargo:
		top = maxi(top, c["id"])
	return str(top).length()


func _render(run: Run) -> void:
	_render_run(run)
	if _tut != null:
		_render_tutorial()


## Prints the tutorial step now (SPEC Section 23.4).
func _render_tutorial() -> void:
	var t := _tut.view()
	if t["done"]:
		_say("TUTORIAL complete.")
		return
	_say("")
	_say("TUTORIAL step %d/%d: %s" % [t["index"] + 1, t["count"], t["text"]])
	var target: Dictionary = t["target"]
	if target.get("kind", "none") != "none":
		_say("  target: %s" % target)
	if t["failed"]:
		_say("  FAILED: %s Use: retry" % t["fail"])
	elif t["next"]:
		_say("  Use: next")
	elif t["try"]:
		_say("  TRY STEP: you can move cargo freely.")


func _render_run(run: Run) -> void:
	var v := RunView.view(run)
	_say("")
	var head := (
		"== Leg %d/%d · Jump %d/%d · %s · credits %d"
		% [v["leg"], v["legs"], v["jump"], v["jumps"], v["phase"], v["credits"]]
	)
	# The run end has no payment and no clamps to use.
	if v["phase"] != Defs.PHASE_END:
		head += (
			" · payment %d after %d jump(s) · clamps %d/%d free"
			% [v["payment"], v["jumps_to_payment"], v["free_clamps"], v["clamps"]]
		)
	_say(head)
	var m: Dictionary = v["mass"]
	var over := ""
	match m["state"]:
		Defs.MASS_OVER:
			over = " · TOO HEAVY TO WARP (max %d)" % m["max"]
		Defs.MASS_FEE:
			over = " · fuel fee %d at the warp" % m["fee"]
	_say("Mass %d/%d (max %d)%s" % [m["hold"], m["limit"], m["max"], over])
	if v["line"] != "":
		_say(GameText.PILOT_NAME + ": " + v["line"])
	if not v["mods"].is_empty():
		var mods := PackedStringArray()
		for mod: Dictionary in v["mods"]:
			mods.append("%s (%s)" % [mod["name"], GameText.format(mod["text"])])
		_say("Mods: " + "; ".join(mods))
	match v["phase"]:
		Defs.PHASE_EVENT:
			_render_event(v["event"])
			_render_station(v)
			_render_traits(run)
		Defs.PHASE_MOD:
			_say("Select a ship mod. Command: choose <n>")
			for i in v["mod_offer"].size():
				var mo: Dictionary = v["mod_offer"][i]
				_say("  %d: %s: %s" % [i, mo["name"], GameText.format(mo["text"])])
		Defs.PHASE_STATION:
			_render_station(v)
			_render_traits(run)
		Defs.PHASE_ARRIVAL:
			_render_arrival(v)
			_render_hold(v)
			var p: Dictionary = v["leg_progress"]
			_say(
				(
					"Leg: credits %d of payment %d, %d more jump(s) before it"
					% [p["credits"], p["payment"], p["jumps_left"]]
				)
			)
		Defs.PHASE_PAYMENT:
			var t: Dictionary = v["payment_screen"]
			_say(
				(
					"Payment: payment %d, credits %d, after %d. %s"
					% [
						t["payment"],
						t["credits"],
						t["after"],
						"Command: pay" if t["can_pay"] else "You cannot pay: pay ends the run."
					]
				)
			)
			for j: Dictionary in t["jumps"]:
				_say(
					(
						"  Jump %d: net %+d, %d delivered, %d scrap, %d explosions"
						% [j["jump"], j["net"], j["delivered"], j["scrapped"], j["explosions"]]
					)
				)
			if not t["next"].is_empty():
				_say(
					(
						"Next: leg %d, %d jumps, payment %d"
						% [t["next"]["leg"], t["next"]["jumps"], t["next"]["payment"]]
					)
				)
		Defs.PHASE_END:
			var e: Dictionary = v["end"]
			_say(
				(
					"Run end: %s · score %d · seed %s · %s"
					% ["WIN" if e["won"] else "LOSS", e["score"], e["seed"], e["stats"]]
				)
			)
			for l: Dictionary in e["legs"]:
				_say(
					(
						"  Leg %d: payment %d, %s, net %+d"
						% [l["leg"], l["payment"], "paid" if l["paid"] else "missed", l["net"]]
					)
				)
			if not e["best_jump"].is_empty():
				var b: Dictionary = e["best_jump"]
				_say("Best jump: leg %d jump %d, net %+d" % [b["leg"], b["jump"], b["net"]])
			var sh: Dictionary = e["ship"]
			var mod_names: Array = sh["mods"].map(func(m: Dictionary) -> String: return m["name"])
			_say(
				(
					"Ship: mods %s, clamps %d, shock bay %s, mass limit %d"
					% [mod_names, sh["clamps"], sh["shock_bay"], sh["mass_limit"]]
				)
			)


## The rule and the break force of each trait in this leg (SPEC Sections 8.4 and 28.2).
func _render_traits(run: Run) -> void:
	_say("Traits:")
	for t: Dictionary in RunView.terms(run.cat, run):
		_say("  %s: %s" % [t["name"], GameText.format(t["rule"])])


func _render_event(e: Dictionary) -> void:
	_say(
		(
			"EVENT: %s (%s speaks). %s Command: choose <n>"
			% [e["name"], e["speaker"]["name"], e["text"]]
		)
	)
	for c: Dictionary in e["choices"]:
		var notes := PackedStringArray()
		if c["cost"] > 0:
			notes.append("cost %d" % c["cost"])
		for f: Dictionary in c["effects"]:
			notes.append(GameText.format(f))
		var off := "" if c["can"] else " (%s)" % c["why"]
		_say("  %d: %s [%s]%s" % [c["index"], c["text"], ", ".join(notes), off])


func _render_station(v: Dictionary) -> void:
	var dirs := []
	for step: Dictionary in v["hazard"]:
		if step["fork"] and step["known"] == "":
			dirs.append("(%s)" % " or ".join(step["directions"]).to_upper())
		elif step["fork"]:
			# A fork step that a Sensor shows (SPEC Section 18.1).
			dirs.append("%s (fork, Sensor)" % str(step["known"]).to_upper())
		else:
			dirs.append(str(step["known"]).to_upper())
	if not v["environment"].is_empty():
		_say(
			"Environment of the leg: %s (%s)" % [v["environment"]["name"], v["environment"]["text"]]
		)
	if not v["incident"].is_empty():
		_say("Incident before the first step: " + _incident_text(v["incident"]))
	_say("Hazard of the next jump: " + " then ".join(dirs))
	if v["front_wall"] != "":
		var wall_text := (
			"Front wall of step 1: %s (cargo there takes a wall jolt; cargo that does not slide"
			+ " presses on the cargo in front; JOLT RISK marks a reaction)"
		)
		_say(wall_text % v["front_wall"].to_upper())
	_render_hold(v)
	_say("Dock:" + ("" if not v["dock"].is_empty() else " (empty)"))
	for c: Dictionary in v["cargo"]:
		if not c["in_hold"] and not c["in_bay"]:
			_say("  " + _cargo_line(c) + "  shape " + _shape_text(c["shape"]))
	_say("Contracts:")
	for k: Dictionary in v["contracts"]:
		var names := []
		for f: Dictionary in k["freight"]:
			names.append(
				(
					"%s(%s%s %s)"
					% [f["name"], f["weight"], _traits(f["traits"]), _shape_text(f["shape"])]
				)
			)
		var bonus := ""
		if not k["bonus"].is_empty():
			bonus = " · bonus +%d: %s" % [k["bonus"]["pay"], GameText.format(k["bonus"]["text"])]
		if k["penalty"] > 0:
			bonus += " · VIP penalty %d if a piece is not delivered" % k["penalty"]
		if k["carried"]:
			bonus += " · ON ITS WAY, %d jump(s) left, cannot cancel" % k["jumps_left"]
		elif k["jumps"] > 1:
			bonus += " · LONG: delivered after %d jumps" % k["jumps"]
		_say(
			(
				"  [%d]%s %s: %s · mass %d · pay %d each%s"
				% [
					k["index"],
					" ACCEPTED" if k["accepted"] else "",
					k["client_name"],
					", ".join(names),
					k["mass"],
					k["pay"],
					bonus
				]
			)
		)
	var s: Dictionary = v["shop"]
	_say("Shop:")
	for o: Dictionary in s["offers"]:
		_say(
			(
				"  [%d] %s %d cr (%s%s %s)%s"
				% [
					o["index"],
					o["name"],
					o["price"],
					o["weight"],
					_traits(o["traits"]),
					_shape_text(o["shape"]),
					" SOLD" if o["bought"] else ""
				]
			)
		)
	_say(
		(
			(
				"  reroll %d · clamp %d (max %d) · shock bay %s · reinforce +%d mass for %d"
				+ " · clear scrap %d/cell · sell kit at half"
			)
			% [
				s["reroll_price"],
				s["clamp_price"],
				s["clamp_max"],
				(
					"max"
					if s["bay"]["after"].is_empty()
					else (
						"%dx%d for %d"
						% [
							s["bay"]["after"]["columns"],
							s["bay"]["after"]["rows"],
							s["bay"]["price"]
						]
					)
				),
				s["reinforce_amount"],
				s["reinforce_price"],
				s["scrap_cell"],
			]
		)
	)


func _render_hold(v: Dictionary) -> void:
	var cols: int = v["hold"]["columns"]
	var rows: int = v["hold"]["rows"]
	var grid := _grid(cols, rows, v["cargo"], false)
	var w := _cell_width(v["cargo"])
	var header := "    "
	for x in cols:
		header += str(x).rpad(w) + " "
	_say("Hold %dx%d:" % [cols, rows])
	_say(header.strip_edges(false, true))
	for y in rows:
		_say(("  %d %s" % [y, " ".join(grid[y])]).strip_edges(false, true))
	for c: Dictionary in v["cargo"]:
		if c["in_hold"]:
			_say("  " + _cargo_line(c))
	_render_bay(v)
	for l: Dictionary in v["links"]:
		_say("  link %s: %s-%s" % [l["kind"], str(l["from"]), str(l["to"])])


## The shock bay: its own cells from (0, 0). The warp does not move or hit it (SPEC Section 31).
func _render_bay(v: Dictionary) -> void:
	var size: Dictionary = v["shock_bay"]
	if size.is_empty():
		return
	var grid := _grid(size["columns"], size["rows"], v["cargo"], true)
	_say(
		"Shock bay %dx%d (no slide, no hits; command: placebay):" % [size["columns"], size["rows"]]
	)
	for y: int in size["rows"]:
		_say(("  %d %s" % [y, " ".join(grid[y])]).strip_edges(false, true))
	for c: Dictionary in v["cargo"]:
		if c["in_bay"]:
			_say("  " + _cargo_line(c))


## Returns the rows of an area (the hold, or the shock bay with in_bay): "." for an
## empty cell, and the ID of the cargo in a cell. Each cell has the same width.
func _grid(cols: int, rows: int, cargo: Array, in_bay: bool) -> Array:
	var w := _cell_width(cargo)
	var grid := []
	for y in rows:
		var row := []
		row.resize(cols)
		row.fill(".".rpad(w))
		grid.append(row)
	for c: Dictionary in cargo:
		if c["in_bay"] if in_bay else c["in_hold"]:
			for cell: Dictionary in c["shape"]:
				grid[c["y"] + cell["y"]][c["x"] + cell["x"]] = str(c["id"]).rpad(w)
	return grid


func _cargo_line(c: Dictionary) -> String:
	var tags := []
	if c["clamped"]:
		tags.append("CLAMPED")
	if c["contract"] >= 0:
		tags.append("contract %d, pay %d" % [c["contract"], c["pay"]])
	if c["kind"] == Defs.KIND_KIT:
		tags.append("sells %d" % c["sell_price"])
	if c["kind"] == Defs.KIND_SCRAP:
		tags.append("clear %d" % c["clear_price"])
	if c["no_cooler"]:
		tags.append("NO COOLER")
	if c["no_power"]:
		tags.append("NO POWER")
	if c.get("jolt_risk", false):
		tags.append("JOLT RISK at the front wall")
	var where := ""
	if c["in_hold"] or c["in_bay"]:
		where = (
			" %s(%d,%d) rot %d" % ["in bay at " if c["in_bay"] else "at ", c["x"], c["y"], c["rot"]]
		)
	return (
		"%d %s [%s %s%s]%s %s"
		% [
			c["id"],
			c["name"],
			c["kind"],
			c["weight"],
			_traits(c["traits"]),
			where,
			" · ".join(tags)
		]
	)


func _traits(traits: Array) -> String:
	return "" if traits.is_empty() else " " + "+".join(traits)


func _shape_text(shape: Array) -> String:
	var cells := []
	for c: Dictionary in shape:
		cells.append("%d,%d" % [c["x"], c["y"]])
	return "[" + " ".join(cells) + "]"


## Prints the log of the last warp. traits has the traits of each cargo by ID.
func _render_warp(run: Run, traits: Dictionary) -> void:
	var w := run.last_warp
	if w.get("fuel_fee", 0) > 0:
		_say("  fuel fee -%d" % w["fuel_fee"])
	for s in w.get("sold", []):
		_say("  sold %s from the dock for %d" % [s["name"], s["price"]])
	if w.get("scrap_cleared", 0) > 0:
		_say("  scrap cleared from the dock -%d" % w["scrap_cleared"])
	var i := 0
	var steps: Array = w["steps"]
	if w.has("incident"):
		steps = [w["incident"]] + steps
	for step: Dictionary in steps:
		if not step.has("direction"):
			_say("-- Incident: " + _incident_text(step))
			if step["debris"] != 0:
				_say("  a debris %s appears" % str(step["debris"]))
			_render_events(step)
			continue
		i += 1
		var fork := ""
		if step.has("options"):
			fork = " (fork: %s)" % " or ".join(step["options"]).to_upper()
		_say("-- Shift step %d: %s%s" % [i, step["direction"].to_upper(), fork])
		_render_slides(step, traits)
		_render_events(step)


func _incident_text(inc: Dictionary) -> String:
	match inc["kind"]:
		Defs.INCIDENT_METEOR:
			return "METEOR on column x=%d (the top cargo takes force 3)" % inc["x"]
		Defs.INCIDENT_ION_PULSE:
			return "ION PULSE on row y=%d (each Electronic cargo there shorts)" % inc["y"]
	return (
		"HULL BREACH at cell %d %d (a debris, or the cargo there becomes scrap)"
		% [inc["x"], inc["y"]]
	)


## Prints the slides of a shift step. A Thruster slides 1 cell at most, and it makes
## no hit when it stops by itself (SPEC Section 10.2).
func _render_slides(step: Dictionary, traits: Dictionary) -> void:
	for sl: Dictionary in step["slides"]:
		var thruster: bool = Defs.TRAIT_THRUSTER in traits.get(sl["cargo"], [])
		var note := " (Thruster: 1 cell at most)" if thruster else ""
		_say(
			(
				"  %d slides %d to (%d,%d)%s"
				% [sl["cargo"], sl["distance"], sl["to"]["x"], sl["to"]["y"], note]
			)
		)


## Prints the hits and the reactions of a step or an incident. A hit shows the
## reactions that it starts, and a reaction of a chain shows its cause.
func _render_events(step: Dictionary) -> void:
	var reactions: Array = step["reactions"]
	for h: Dictionary in step["hits"]:
		var line := ""
		if h.get("meteor", false):
			line = "METEOR hits %d with force %d" % [h["cargo"], h["force"]]
		elif h["jolt"]:
			line = "%d is jolted at the front wall with force %d" % [h["cargo"], h["force"]]
		elif h.get("press", false):
			line = "%d presses on %d with force %d" % [h["cargo"], h["other"], h["force"]]
		else:
			var target := "the wall" if h["wall"] else str(h["other"])
			line = "%d hits %s with force %d" % [h["cargo"], target, h["force"]]
		var started := PackedStringArray()
		for r: Dictionary in reactions:
			if r["cause"] < 0 and (r["cargo"] == h["cargo"] or r["cargo"] == h["other"]):
				started.append("%d %s" % [r["cargo"], r["kind"].to_upper()])
		_say("  " + line + (" -> " + ", ".join(started) if not started.is_empty() else ""))
	for r: Dictionary in reactions:
		var extra := ""
		if r["kind"] == Defs.REACT_SHIELD:
			extra = " (Shield %d cancels a %s)" % [r["shield"], r["canceled"]]
		if r["cause"] >= 0:
			var from: Dictionary = reactions[r["cause"]]
			extra += " (after %s of %d)" % [from["kind"].to_upper(), from["cargo"]]
		_say("  %s: %d%s" % [r["kind"].to_upper(), r["cargo"], extra])


func _render_arrival(v: Dictionary) -> void:
	var a: Dictionary = v["arrival"]
	_say("Arrival report:")
	for k: Dictionary in a["contracts"]:
		var pieces := []
		for p: Dictionary in k["pieces"]:
			pieces.append("%s %s" % [p["name"], p["state"]])
		var bonus := ""
		if k["has_bonus"]:
			bonus = " · bonus %s" % (str(k["bonus"]) if k["bonus_met"] else "missed")
		_say(
			(
				"  %s: %s · pay %d%s · insurance %d · breach %d"
				% [
					k["client_name"],
					", ".join(pieces),
					k["pay"],
					bonus,
					k["insurance"],
					k["breach"]
				]
			)
		)
	_say("  total %+d credits. Command: continue" % a["total"])


# --- Session file ---


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _write(path: String, session: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(session, "  "))
