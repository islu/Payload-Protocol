#!/bin/sh
# Runs Godot headless, prints its output, and fails on a script error. Godot exits
# with 0 after a script error in some cases, so the text of the output decides too.
#
# Usage: tools/godot_check.sh <seconds> <result> <godot arguments...>
#   <seconds>  stops a run that hangs (for example when nothing calls quit()).
#   <result>   a line that the output must have, or "" for none.
# GODOT selects the binary (default: godot).

seconds=$1
result=$2
shift 2
out=$(timeout "$seconds" "${GODOT:-godot}" --headless "$@" 2>&1) && status=0 || status=$?
if [ "$status" -eq 124 ]; then
	echo "$out" | tail -20
	echo "godot_check: stopped after $seconds seconds"
	exit 1
fi
echo "$out" | grep -v -e '^Godot Engine' -e '^$'
if [ "$status" -ne 0 ]; then exit "$status"; fi
if echo "$out" | grep -q -e "SCRIPT ERROR" -e "Parse Error" -e "ERROR:"; then exit 1; fi
if [ -n "$result" ] && ! echo "$out" | grep -q "$result"; then
	echo "godot_check: no line \"$result\" in the output"
	exit 1
fi
