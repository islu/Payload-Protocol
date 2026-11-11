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

const DEFAULT_SESSION := "playtest/sessions/session.json"
const LETTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
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
	"upgrade": "upgrade column|row",
	"sell": "sell <kit>",
	"clear": "clear <scrap>",
	"warp": "warp",
	"continue": "continue",
	"pay": "pay",
}

var _out: PackedStringArray = []


func _initialize() -> void:
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
		var run_seed := int(args[1]) if args.size() > 1 else randi() + 1
		var session := {"seed": run_seed, "actions": []}
		_write(path, session)
		_render(Run.new(cat, run_seed))
		return 0
	var session := _read(path)
	if session.is_empty():
		_say("no session at %s. Start one: new [seed]" % path)
		return 1
	var run := Run.new(cat, int(session["seed"]))
	for a: Array in session["actions"]:
		var err := _act(run, a)
		if err != "":
			_say("the session does not replay: %s: %s" % [" ".join(a), err])
			return 1
	match args[0]:
		"look":
			_render(run)
			return 0
		"history":
			for a: Array in session["actions"]:
				_say(" ".join(a))
			return 0
		"do":
			var steps := " ".join(args.slice(1)).split(";", false)
			for s in steps:
				var parts := Array(s.strip_edges().split(" ", false))
				if not _step(run, session, parts):
					break
			_write(path, session)
		_:
			_step(run, session, args)
			_write(path, session)
	_render(run)
	return 0


## Runs one action. It records the action when it works.
func _step(run: Run, session: Dictionary, parts: Array) -> bool:
	var err := _act(run, parts)
	if err != "":
		_say("> %s: %s" % [" ".join(parts), err])
		return false
	_say("> " + " ".join(parts))
	session["actions"].append(parts)
	if parts[0] == "warp":
		_render_warp(run)
	return true


func _act(run: Run, parts: Array) -> String:
	var n := func(i: int) -> int: return int(parts[i]) if parts.size() > i else -1
	match parts[0]:
		"accept":
			return run.accept_contract(n.call(1))
		"cancel":
			return run.cancel_contract(n.call(1))
		"place":
			var rot: int = n.call(4) if parts.size() > 4 else 0
			return run.place_cargo(n.call(1), Vector2i(n.call(2), n.call(3)), rot)
		"dock":
			return run.dock_cargo(n.call(1))
		"rotate":
			return run.rotate_cargo(n.call(1))
		"clamp":
			return run.clamp_cargo(n.call(1))
		"unclamp":
			return run.unclamp_cargo(n.call(1))
		"buy":
			return run.buy_kit(n.call(1))
		"reroll":
			return run.reroll()
		"buyclamp":
			return run.buy_clamp()
		"upgrade":
			return run.upgrade_hold(parts[1] if parts.size() > 1 else "")
		"sell":
			return run.sell_kit(n.call(1))
		"clear":
			return run.clear_scrap(n.call(1))
		"warp":
			return run.warp()
		"continue":
			return run.continue_run()
		"pay":
			return run.pay_toll()
	return "unknown command %s" % parts[0]


func _usage() -> void:
	_say('Commands: new [seed] | look | history | do "<action>; <action>" | <action>')
	_say("Actions:")
	for k: String in ACTIONS:
		_say("  " + ACTIONS[k])
	_say("Cells: x goes right from 0, y goes down from 0. A rotation turns 90° clockwise.")


# --- Render: only what the player sees ---


func _letter(id: int) -> String:
	return LETTERS[(id - 1) % LETTERS.length()]


func _render(run: Run) -> void:
	var v := RunView.view(run)
	_say("")
	_say(
		(
			"== Sector %d/%d · Jump %d/%d · %s · credits %d · toll %d after %d jump(s) · clamps %d/%d free"
			% [
				v["sector"],
				v["sectors"],
				v["jump"],
				v["jumps"],
				v["phase"],
				v["credits"],
				v["toll"],
				v["jumps_to_toll"],
				v["free_clamps"],
				v["clamps"]
			]
		)
	)
	if v["line"] != "":
		_say("PIP: " + v["line"])
	match v["phase"]:
		Defs.PHASE_STATION:
			_render_station(run, v)
		Defs.PHASE_ARRIVAL:
			_render_arrival(v)
			_render_hold(run, v)
		Defs.PHASE_TOLL:
			var t: Dictionary = v["toll_gate"]
			_say(
				(
					"Toll gate: toll %d, credits %d, after %d. %s"
					% [
						t["toll"],
						t["credits"],
						t["after"],
						"Command: pay" if t["can_pay"] else "You cannot pay: pay ends the run."
					]
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


func _render_station(run: Run, v: Dictionary) -> void:
	var dirs := []
	for d: String in v["hazard"]:
		dirs.append(d.to_upper())
	_say("Hazard of the next jump: " + " then ".join(dirs))
	_render_hold(run, v)
	_say("Dock:" + ("" if not v["dock"].is_empty() else " (empty)"))
	for c: Dictionary in v["cargo"]:
		if not c["in_hold"]:
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
			bonus = " · bonus +%d: %s" % [k["bonus"]["pay"], _text(k["bonus"]["text"])]
		_say(
			(
				"  [%d]%s %s: %s · pay %d each%s"
				% [
					k["index"],
					" ACCEPTED" if k["accepted"] else "",
					k["client_name"],
					", ".join(names),
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
			"  reroll %d · clamp %d (max %d) · upgrade %d%s%s · clear scrap 2/cell · sell kit at half"
			% [
				s["reroll_price"],
				s["clamp_price"],
				s["clamp_max"],
				s["upgrade_price"],
				" column" if s["can_column"] else "",
				" row" if s["can_row"] else ""
			]
		)
	)


func _render_hold(_run: Run, v: Dictionary) -> void:
	var cols: int = v["hold"]["columns"]
	var rows: int = v["hold"]["rows"]
	var grid := []
	for y in rows:
		var row := []
		row.resize(cols)
		row.fill(".")
		grid.append(row)
	for c: Dictionary in v["cargo"]:
		if not c["in_hold"]:
			continue
		for cell: Dictionary in c["shape"]:
			grid[c["y"] + cell["y"]][c["x"] + cell["x"]] = _letter(c["id"])
	var header := "    "
	for x in cols:
		header += str(x) + " "
	_say("Hold %dx%d:" % [cols, rows])
	_say(header)
	for y in rows:
		_say("  %d %s" % [y, " ".join(grid[y])])
	for c: Dictionary in v["cargo"]:
		if c["in_hold"]:
			_say("  " + _cargo_line(c))
	for l: Dictionary in v["links"]:
		_say("  link %s: %s-%s" % [l["kind"], _letter(l["from"]), _letter(l["to"])])


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
	var where := " at (%d,%d) rot %d" % [c["x"], c["y"], c["rot"]] if c["in_hold"] else ""
	return (
		"%s id %d %s [%s %s%s]%s %s"
		% [
			_letter(c["id"]),
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


func _text(t: Dictionary) -> String:
	var s: String = t["key"]
	for k: String in t.get("args", {}):
		s = s.replace("{" + k + "}", str(t["args"][k]))
	return s


func _render_warp(run: Run) -> void:
	var w := run.last_warp
	for s in w.get("sold", []):
		_say("  sold %s from the dock for %d" % [s["name"], s["price"]])
	var i := 0
	for step: Dictionary in w["steps"]:
		i += 1
		_say("-- Shift step %d: %s" % [i, step["direction"].to_upper()])
		for h: Dictionary in step["hits"]:
			var target := "the wall" if h["wall"] else _letter(h["other"])
			_say("  %s hits %s with force %d" % [_letter(h["cargo"]), target, h["force"]])
		for r: Dictionary in step["reactions"]:
			var extra := ""
			if r["kind"] == Defs.REACT_SHIELD:
				extra = " (Shield %s cancels a %s)" % [_letter(r["shield"]), r["canceled"]]
			_say("  %s: %s%s" % [r["kind"].to_upper(), _letter(r["cargo"]), extra])


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
				"  %s: %s · pay %d%s · breach %d"
				% [k["client_name"], ", ".join(pieces), k["pay"], bonus, k["breach"]]
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
