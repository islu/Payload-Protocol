class_name TestCase
extends RefCounted
## The base of a test file. run_tests.gd makes a new instance for each method
## whose name starts with "test_", so the methods do not share state.
## Give the spec section in each check: "a vase breaks (SPEC Section 11.1)".

var failures: PackedStringArray = []


func check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)


func eq(got: Variant, want: Variant, what: String) -> void:
	if typeof(got) != typeof(want) or got != want:
		failures.append("%s: got %s, want %s" % [what, var_to_str(got), var_to_str(want)])
