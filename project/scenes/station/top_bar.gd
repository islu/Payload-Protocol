class_name TopBar
extends HBoxContainer
## The top bar of the station: four groups (SPEC Section 20.2). (1) The leg, and a
## dot for each jump. (2) The credits, and a bar of the credits against the payment.
## (3) A bar of the hold mass, with a mark at the mass limit. (4) The environment.
## It reads the run view only. The scene shows the values; it calculates none. The
## station shows the rule of the environment in its tip.

const LEG_TEXT := "Leg {leg}/{legs}"
const CREDITS_TEXT := "Credits: {credits}"
const PAYMENT_TEXT := "Payment {payment} after {jumps} jump(s)"
const MASS_TEXT := "Mass {hold}/{limit}"
const FUEL_TEXT := "Fuel fee {fee}"
const OVER_MAX_TEXT := "Too heavy: {max} at most"
const BAR_WIDTH := 220.0

## The parts, for the checks.
var groups: Array[Control] = []
var dots: JumpDots
var pay_bar: Gauge
var mass_bar: Gauge
var env_badge: PanelContainer
var credits_label: Label

var _leg_label: Label
var _payment_label: Label
var _mass_label: Label
var _env_icon: EnvIcon
var _env_name: Label


func _init() -> void:
	add_theme_constant_override("separation", 14)
	var leg := _group()
	_leg_label = _text(leg, TextSize.HEADING, Palette.TEXT)
	dots = JumpDots.new()
	_row(leg).add_child(dots)
	var money := _group()
	credits_label = _text(money, TextSize.HEADING, Palette.GOOD)
	pay_bar = Gauge.new()
	_row(money).add_child(pay_bar)
	_payment_label = _text(money, TextSize.SMALL, Palette.TEXT_DIM)
	var mass := _group()
	_mass_label = _text(mass, TextSize.BODY, Palette.TEXT)
	mass_bar = Gauge.new()
	_row(mass).add_child(mass_bar)
	env_badge = _group()
	env_badge.name = "Environment"
	env_badge.mouse_filter = Control.MOUSE_FILTER_STOP
	_env_icon = EnvIcon.new()
	_row(env_badge).add_child(_env_icon)
	_env_name = _text(env_badge, TextSize.BODY, Palette.WARN)


## Shows the values of the run view, but the credits: set_credits() counts them.
func set_view(run: Dictionary) -> void:
	_leg_label.text = tr(LEG_TEXT).format(run)
	dots.set_jumps(run["jumps"], run["jump"])
	pay_bar.set_values(run["credits"], run["payment"], [], Palette.GOOD)
	_payment_label.text = tr(PAYMENT_TEXT).format(
		{"payment": run["payment"], "jumps": run["jumps_to_payment"]}
	)
	var m: Dictionary = run["mass"]
	var parts := PackedStringArray([tr(MASS_TEXT).format(m)])
	var color := Palette.TEXT
	if m["hold"] > m["max"]:
		parts.append(tr(OVER_MAX_TEXT).format(m))
		color = Palette.BAD
	elif m["fee"] > 0:
		parts.append(tr(FUEL_TEXT).format(m))
		color = Palette.WARN
	_mass_label.text = " · ".join(parts)
	_mass_label.add_theme_color_override("font_color", color)
	mass_bar.set_values(m["hold"], m["max"], [m["limit"]], color)
	var env: Dictionary = run.get("environment", {})
	env_badge.visible = not env.is_empty()
	if not env.is_empty():
		_env_icon.env = env["id"]
		_env_icon.queue_redraw()
		_env_name.text = tr(env["name"])


func set_credits(value: int) -> void:
	credits_label.text = tr(CREDITS_TEXT).format({"credits": value})


## A group: a panel with a row of parts.
func _group() -> PanelContainer:
	var p := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PANEL
	style.border_color = Palette.PANEL_LINE
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	p.add_child(row)
	add_child(p)
	groups.append(p)
	return p


func _text(group: PanelContainer, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_row(group).add_child(l)
	return l


## The row of parts of a group.
func _row(group: PanelContainer) -> HBoxContainer:
	return group.get_child(0)


## A dot for each jump of the leg. The jumps up to the jump now are filled.
class JumpDots:
	extends Control
	var total := 0
	var current := 0

	func _init() -> void:
		custom_minimum_size = Vector2(60, 24)

	func set_jumps(jumps: int, jump: int) -> void:
		total = jumps
		current = jump
		custom_minimum_size.x = maxf(1.0, total) * 20.0
		queue_redraw()

	func _draw() -> void:
		for i in total:
			var c := Vector2(10.0 + i * 20.0, size.y / 2.0)
			if i < current:
				draw_circle(c, 6.0, Palette.ACCENT)
			else:
				draw_arc(c, 6.0, 0.0, TAU, 20, Palette.TEXT_DIM, 2.0)


## A bar of a value against a maximum, with marks at some values.
class Gauge:
	extends Control
	var value := 0
	var maximum := 1
	var marks: Array = []
	var color := Palette.GOOD

	func _init() -> void:
		custom_minimum_size = Vector2(BAR_WIDTH, 24)

	func set_values(v: int, m: int, at: Array, c: Color) -> void:
		value = v
		maximum = m
		marks = at
		color = c
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(0, size.y / 2.0 - 6.0, size.x, 12.0)
		draw_rect(r, Palette.BACKGROUND)
		var k := clampf(float(value) / maxf(1.0, maximum), 0.0, 1.0)
		draw_rect(Rect2(r.position, Vector2(r.size.x * k, r.size.y)), color)
		draw_rect(r, Palette.PANEL_LINE, false, 1.0)
		for at: int in marks:
			var x := r.size.x * clampf(float(at) / maxf(1.0, maximum), 0.0, 1.0)
			draw_line(Vector2(x, r.position.y - 4), Vector2(x, r.end.y + 4), Palette.TEXT, 2.0)


## A small icon for each environment (SPEC Section 28.2).
class EnvIcon:
	extends Control
	var env := ""

	func _init() -> void:
		custom_minimum_size = Vector2(24, 24)

	func _draw() -> void:
		var c := size / 2.0
		var col := Palette.WARN
		match env:
			Defs.ENV_LOW_GRAVITY:
				draw_arc(c + Vector2(0, 3), 6.0, 0.0, TAU, 16, col, 2.0)
				draw_line(c + Vector2(0, -3), c + Vector2(0, -10), col, 2.0)
				draw_line(c + Vector2(-3, -7), c + Vector2(0, -10), col, 2.0)
				draw_line(c + Vector2(3, -7), c + Vector2(0, -10), col, 2.0)
			Defs.ENV_MAGNETIC_STORM:
				draw_arc(c + Vector2(0, -1), 7.0, 0.0, PI, 16, col, 3.0)
				draw_line(c + Vector2(-7, -1), c + Vector2(-7, -8), col, 3.0)
				draw_line(c + Vector2(7, -1), c + Vector2(7, -8), col, 3.0)
			Defs.ENV_RADIATION_BELT:
				for i in 3:
					var a := -PI / 2.0 + i * TAU / 3.0
					draw_arc(c, 7.0, a - 0.5, a + 0.5, 8, col, 5.0)
				draw_circle(c, 2.0, col)
			Defs.ENV_HEAT_ZONE:
				var pts := PackedVector2Array(
					[c + Vector2(0, -10), c + Vector2(7, 6), c + Vector2(-7, 6)]
				)
				draw_colored_polygon(pts, col)
				draw_circle(c + Vector2(0, 4), 3.0, Palette.BACKGROUND)
