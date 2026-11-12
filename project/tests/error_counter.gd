class_name ErrorCounter
extends Logger
## Counts the script errors, so that the test runner can fail a test method that
## stops on a runtime error. GDScript has no try and catch: an error only stops the
## method, and the runner goes on.

var count := 0


func _log_error(
	_function: String,
	_file: String,
	_line: int,
	_code: String,
	_rationale: String,
	_editor_notify: bool,
	error_type: int,
	_script_backtraces: Array[ScriptBacktrace]
) -> void:
	if error_type == ERROR_TYPE_SCRIPT or error_type == ERROR_TYPE_ERROR:
		count += 1


func _log_message(_message: String, _error: bool) -> void:
	pass
