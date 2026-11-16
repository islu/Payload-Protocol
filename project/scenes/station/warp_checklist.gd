class_name WarpChecklist
extends PanelContainer
## The warp checklist above the Warp button (SPEC Section 20.2): the fuel fee, the cargo
## on the dock, the cargo with a wall jolt warning, and the incident of the jump. Each
## row has a mark: a green check when it is clear, a yellow warning when it is not. It
## reads view.run.checklist. It calculates nothing.

const FEE_TEXT := "Fuel fee: {fee} cr"
const NO_FEE_TEXT := "No fuel fee"
const DOCK_TEXT := "Dock: {count} cargo left"
const DOCK_EMPTY_TEXT := "Dock empty"
const JOLT_TEXT := "Wall jolt: {count} cargo"
const NO_JOLT_TEXT := "No wall jolt"
const INCIDENT_TEXT := "Incident: {text}"
const NO_INCIDENT_TEXT := "No incident"

## The text of each row and its state, for the checks.
var rows: Array[Label] = []
var warnings: Array[bool] = []
var _marks: Array[Mark] = []


func _init() -> void:
	add_theme_stylebox_override("panel", Ui.panel_style(Palette.PANEL_LINE, 1, 6, 10, 6))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	add_child(box)
	for i in 4:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		box.add_child(row)
		var mark := Mark.new()
		row.add_child(mark)
		_marks.append(mark)
		var l := Label.new()
		l.add_theme_font_size_override("font_size", TextSize.SMALL)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(l)
		rows.append(l)
		warnings.append(false)


func set_view(run: Dictionary) -> void:
	var c: Dictionary = run["checklist"]
	_row(0, c["fee"] > 0, tr(FEE_TEXT).format({"fee": c["fee"]}), tr(NO_FEE_TEXT))
	_row(1, c["dock"] > 0, tr(DOCK_TEXT).format({"count": c["dock"]}), tr(DOCK_EMPTY_TEXT))
	_row(2, c["jolts"] > 0, tr(JOLT_TEXT).format({"count": c["jolts"]}), tr(NO_JOLT_TEXT))
	var incident := ""
	if c["incident"] != "":
		incident = tr(INCIDENT_TEXT).format({"text": RouteCards.incident_text(run["incident"])})
	_row(3, c["incident"] != "", incident, tr(NO_INCIDENT_TEXT))


func _row(i: int, warn: bool, warn_text: String, clear_text: String) -> void:
	warnings[i] = warn
	rows[i].text = warn_text if warn else clear_text
	rows[i].add_theme_color_override("font_color", Palette.WARN if warn else Palette.TEXT_DIM)
	_marks[i].warn = warn
	_marks[i].queue_redraw()


## A check mark, or a warning mark. The font has no check glyph, so it is drawn.
class Mark:
	extends Control
	var warn := false

	func _init() -> void:
		custom_minimum_size = Vector2(18, 18)

	func _draw() -> void:
		var c := size / 2.0
		if warn:
			draw_circle(c, 8.0, Palette.WARN)
			draw_line(c + Vector2(0, -4), c + Vector2(0, 1), Palette.BACKGROUND, 2.5)
			draw_circle(c + Vector2(0, 4.5), 1.4, Palette.BACKGROUND)
		else:
			var pts := PackedVector2Array(
				[c + Vector2(-6, 0), c + Vector2(-2, 4), c + Vector2(6, -5)]
			)
			draw_polyline(pts, Palette.GOOD, 2.5)
