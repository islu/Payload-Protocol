extends SceneTree
## Runs the rule tests: each method "test_*" of each script tests/rules/test_*.gd.
## Run: godot --headless --path project -s res://tests/run_tests.gd [-- <file filter>]

const DIR := "res://tests/rules"


func _initialize() -> void:
	var filter := ""
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		filter = args[0]
	var total := 0
	var failed := 0
	var files := Array(DirAccess.get_files_at(DIR))
	files.sort()
	for file: String in files:
		if (
			not (file.begins_with("test_") and file.ends_with(".gd"))
			or (filter != "" and not file.contains(filter))
		):
			continue
		var script: GDScript = load(DIR + "/" + file)
		if script == null or not script.can_instantiate():
			failed += 1
			total += 1
			printerr("FAIL %s: the script does not load" % file)
			continue
		for method: Dictionary in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			total += 1
			var test: TestCase = script.new()
			test.call(name)
			if not test.failures.is_empty():
				failed += 1
				for f in test.failures:
					printerr("FAIL %s::%s: %s" % [file, name, f])
	print("tests: %d passed, %d failed" % [total - failed, failed])
	quit(1 if failed > 0 or total == 0 else 0)
