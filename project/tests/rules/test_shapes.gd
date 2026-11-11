extends RuleTest

const ELL: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]


func _same_cells(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for c in a:
		if not c in b:
			return false
	return true


func test_rotation_turns_clockwise() -> void:
	var line: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0)]
	check(
		_same_cells(Shapes.rotate(line, 1), [Vector2i(0, 0), Vector2i(0, 1)]),
		"a rotation turns a line 90° clockwise (SPEC Section 6.1)"
	)
	check(
		_same_cells(Shapes.rotate(ELL, 1), [Vector2i(1, 0), Vector2i(0, 0), Vector2i(0, 1)]),
		"after a rotation the smallest x and y are 0 (SPEC Section 6.1)"
	)
	check(
		_same_cells(Shapes.rotate(ELL, 2), [Vector2i(1, 1), Vector2i(1, 0), Vector2i(0, 0)]),
		"two rotations turn an L upside down (SPEC Section 6.1)"
	)
	check(
		_same_cells(Shapes.rotate(ELL, 4), ELL),
		"four rotations give the same shape (SPEC Section 6.1)"
	)


func test_connected() -> void:
	check(Shapes.connected(ELL), "the cells of an L are connected (SPEC Section 6.1)")
	var gap: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 1)]
	check(not Shapes.connected(gap), "diagonal cells are not connected (SPEC Section 6.1)")


func test_next_to() -> void:
	var a := put("box", 0, 0)
	var b := put("box", 1, 0)
	var c := put("box", 2, 1)
	check(Cargo.next_to(a, b), "cells that share an edge are next to each other (SPEC Section 4.4)")
	check(not Cargo.next_to(b, c), "diagonal cells are not next to each other (SPEC Section 4.4)")
