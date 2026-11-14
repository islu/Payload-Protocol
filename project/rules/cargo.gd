class_name Cargo
extends RefCounted
## One cargo in a run: freight, kit, or scrap (SPEC Section 6).

var id: int
var def: CargoDef
## The kind now. It is scrap after a reaction breaks the cargo.
var kind: String
var rot: int = 0
var pos := Vector2i.ZERO
## Where the cargo is: in the hold, in the shock bay, or on the dock (both false).
var in_hold := false
var in_bay := false
var clamped := false
## The ID of the contract of a freight, or 0.
var contract: int = 0
## True for a freight that became scrap from a spoil.
var spoiled := false


func _init(cargo_id: int, cargo_def: CargoDef) -> void:
	id = cargo_id
	def = cargo_def
	kind = cargo_def.kind


## Returns the cells relative to the origin, in the rotation now.
func shape() -> Array[Vector2i]:
	return Shapes.rotate(def.shape, rot)


## Returns the cells in its area: the hold or the shock bay. Each area has its own
## cells from (0, 0) (SPEC Section 31.1).
func cells() -> Array[Vector2i]:
	return Shapes.cells_at(def.shape, rot, pos)


## Reports whether the cargo has a trait now. Scrap has no traits (SPEC Section 6.4).
func has(trait_id: String) -> bool:
	return kind != Defs.KIND_SCRAP and trait_id in def.traits


## Returns the weight class now. Scrap is light (SPEC Section 6.4).
func weight() -> String:
	return Defs.WEIGHT_LIGHT if kind == Defs.KIND_SCRAP else def.weight


## Reports whether a cell of a shares an edge with a cell of b (SPEC Section 4.4).
static func next_to(a: Cargo, b: Cargo) -> bool:
	# Cargo in different areas is not next to each other (SPEC Section 31.1).
	if a == b or a.in_bay != b.in_bay:
		return false
	var other := b.cells()
	for c in a.cells():
		for d in Shapes.EDGE_NEIGHBORS:
			if c + d in other:
				return true
	return false


## Reports whether two cargo are within n cells: a cell of one is at a distance of
## n or less from a cell of the other. A diagonal step counts as 1 (SPEC Section 27.2).
static func within(a: Cargo, b: Cargo, n: int) -> bool:
	if a == b or a.in_bay != b.in_bay:
		return false
	for c in a.cells():
		for d in b.cells():
			if maxi(absi(c.x - d.x), absi(c.y - d.y)) <= n:
				return true
	return false


## Reports whether a cell of the cargo is in a set of cells.
func touches(area: Dictionary) -> bool:
	for c in cells():
		if area.has(c):
			return true
	return false
