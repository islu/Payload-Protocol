class_name Starfield
extends Control
## A starfield that moves to the left (SPEC Sections 20.1 and 20.3). speed 1 is
## the slow title. A larger speed draws the stars as lines (the warp).

const STARS := 160

var speed := 1.0
var _stars: Array = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.seed = 42
	for i in STARS:
		_stars.append([_rng.randf(), _rng.randf(), _rng.randf_range(0.2, 1.0)])


func _process(delta: float) -> void:
	for s: Array in _stars:
		s[0] -= delta * 0.02 * speed * s[2]
		if s[0] < 0.0:
			s[0] += 1.0
			s[1] = _rng.randf()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.BACKGROUND)
	for s: Array in _stars:
		var p := Vector2(s[0] * size.x, s[1] * size.y)
		var c := Color(Palette.TEXT, 0.25 + 0.6 * s[2])
		var length: float = maxf(0.0, (speed - 1.0) * 6.0 * s[2])
		if length < 1.0:
			draw_circle(p, 1.0 + s[2], c)
		else:
			draw_line(p, p + Vector2(length, 0), c, 1.0 + s[2])
