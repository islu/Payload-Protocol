class_name TitleShip
extends Control
## The cargo ship of the title (SPEC Section 20.1). It flies behind the menu in a cycle:
## in at the middle of the right edge, down to the left of the menu, a stop where cells of
## cargo fly up into it, out at the bottom left, and a pause. It grows as it comes in, and
## more as it flies out. The time in the cycle gives each position, so a check can set it.

const SHIP_PATH := "res://art/ship.png"
## The times of the parts of the cycle, in seconds.
const ENTER_TIME := 4.0
const DOCK_TIME := 3.0
const LEAVE_TIME := 3.0
const PAUSE_TIME := 5.0
const CYCLE := ENTER_TIME + DOCK_TIME + LEAVE_TIME + PAUSE_TIME
## The ship is on the screen when the title opens: the cycle starts here.
const START_TIME := 1.0
## The scale of the art: far at the right edge, 2 at the stop (sharp pixels), and near
## at the end.
const FAR_SCALE := 1.0
const DOCK_SCALE := 2.0
const NEAR_SCALE := 3.0
## The stop at the left of the menu, as a part of the screen.
const DOCK := Vector2(0.2, 0.72)
## At the stop, the ship moves up and down a little.
const BOB := 5.0
const BOB_SPEED := 2.0
## The cells of cargo that fly up into the ship at the stop: each starts CARGO_GAP
## seconds after the one before, and flies for CARGO_TIME seconds.
const CARGO_CELLS := 3
const CARGO_GAP := 0.7
const CARGO_TIME := 1.2
const CELL := 80.0
## The cargo in the cells: 1x1 cargo of the game. It is art only.
const CARGO := [
	"burger",
	"instant_noodles",
	"cargo_crate",
	"energy_crystal",
	"medkit",
	"battery_pack",
	"fuel_drum",
	"space_cheese",
]

var texture: Texture2D
## The time in the cycle, from 0 to CYCLE.
var time := START_TIME
## The number of the cycle: it selects the cargo of the cells.
var _cycle := 0


func _ready() -> void:
	name = "TitleShip"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture = load(SHIP_PATH)
	# Nearest filtering keeps the pixels of the art sharp.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta: float) -> void:
	time += delta
	if time >= CYCLE:
		time -= CYCLE
		_cycle += 1
	queue_redraw()


## The center of the ship on the screen.
func ship_center() -> Vector2:
	var view := get_viewport_rect().size
	var dock := view * DOCK
	if time < ENTER_TIME:
		var start := Vector2(view.x + texture.get_width() * FAR_SCALE / 2.0, view.y / 2.0)
		return start.lerp(dock, ease(time / ENTER_TIME, 0.5))
	if time < ENTER_TIME + DOCK_TIME:
		return dock + Vector2(0, sin((time - ENTER_TIME) * BOB_SPEED) * BOB)
	# Out at the bottom left: at the end, the ship is past the left edge.
	var out := Vector2(-texture.get_width() * NEAR_SCALE / 2.0 - 20.0, view.y)
	var t := clampf((time - ENTER_TIME - DOCK_TIME) / LEAVE_TIME, 0.0, 1.0)
	return dock.lerp(out, ease(t, 2.0))


## The scale of the art of the ship.
func ship_scale() -> float:
	if time < ENTER_TIME:
		return lerpf(FAR_SCALE, DOCK_SCALE, ease(time / ENTER_TIME, 0.5))
	if time < ENTER_TIME + DOCK_TIME:
		return DOCK_SCALE
	var t := clampf((time - ENTER_TIME - DOCK_TIME) / LEAVE_TIME, 0.0, 1.0)
	return lerpf(DOCK_SCALE, NEAR_SCALE, ease(t, 2.0))


func ship_size() -> Vector2:
	return texture.get_size() * ship_scale()


## In the pause, no ship shows.
func ship_visible() -> bool:
	return time < ENTER_TIME + DOCK_TIME + LEAVE_TIME


## The cells of cargo that fly now: {id, position (the center), scale, alpha}. They fly up
## from below the screen into the bottom of the ship, get smaller, and fade at the end.
func cargo_cells() -> Array[Dictionary]:
	var cells: Array[Dictionary] = []
	var view := get_viewport_rect().size
	var dock := view * DOCK
	var hold := dock + Vector2(0, texture.get_height() * DOCK_SCALE * 0.3)
	for i in CARGO_CELLS:
		var t := (time - ENTER_TIME - i * CARGO_GAP) / CARGO_TIME
		if t < 0.0 or t > 1.0:
			continue
		var from := Vector2(dock.x + (i - 1) * CELL * 1.2, view.y + CELL)
		(
			cells
			. append(
				{
					"id": CARGO[(_cycle * CARGO_CELLS + i) % CARGO.size()],
					"position": from.lerp(hold, ease(t, 0.6)),
					"scale": lerpf(1.0, 0.6, t),
					"alpha": clampf((1.0 - t) * 4.0, 0.0, 1.0),
				}
			)
		)
	return cells


func _draw() -> void:
	if texture == null or not ship_visible():
		return
	# The cells come from below the ship, so they show behind it.
	for c: Dictionary in cargo_cells():
		_draw_cell(c)
	var s := ship_size()
	draw_texture_rect(texture, Rect2(ship_center() - s / 2.0, s), false)


## A cell of the hold with its cargo: Palette.GRID with a GRID_LINE border.
func _draw_cell(c: Dictionary) -> void:
	var side := CELL * float(c["scale"])
	var rect := Rect2(c["position"] - Vector2(side, side) / 2.0, Vector2(side, side))
	var a: float = c["alpha"]
	draw_rect(rect, Color(Palette.GRID, a))
	draw_rect(rect, Color(Palette.GRID_LINE, a), false, 2.0)
	var art := CargoArt.texture(c["id"])
	if art != null:
		draw_texture_rect(art, rect.grow(-side * 0.1), false, Color(1, 1, 1, a))
