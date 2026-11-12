class_name TutorialPicture
extends Control
## The picture of a How to Play page (SPEC Section 23.2): a small hold drawn with
## CargoDraw. The pictures are examples only. Their numbers come from the view.

const CELL := 56.0
const COLUMNS := 6
const ROWS := 3
const FORCE_TEXT := "{weight} × {cells} = {force}"

var page := 0
var names: Dictionary = {}


func _init() -> void:
	custom_minimum_size = Vector2(COLUMNS * CELL + 220, ROWS * CELL + 24)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_page(index: int, view_names: Dictionary) -> void:
	page = index
	names = view_names
	queue_redraw()


func _origin() -> Vector2:
	return Vector2((size.x - COLUMNS * CELL) / 2.0, 12)


func _cargo(traits: Array, weight := Defs.WEIGHT_STANDARD, kind := Defs.KIND_FREIGHT) -> Dictionary:
	return {
		"traits": traits,
		"kind": kind,
		"weight_value": names.get("weight_values", {}).get(weight, 2),
		"clamped": false,
	}


func _at(x: float, y: float) -> Vector2:
	return _origin() + Vector2(x, y) * CELL


func _one() -> Array:
	return [{"x": 0, "y": 0}]


func _draw() -> void:
	var o := _origin()
	for y in ROWS:
		for x in COLUMNS:
			var r := Rect2(o + Vector2(x, y) * CELL, Vector2(CELL, CELL))
			draw_rect(r, Palette.GRID)
			draw_rect(r, Palette.GRID_LINE, false, 1.0)
	match page:
		0:
			_draw_place()
		1:
			_draw_slide()
		2:
			_draw_reactions()
		3:
			_draw_links()


## Page 1: a cargo from the dock goes into the hold, with a green preview.
func _draw_place() -> void:
	var bar := [{"x": 0, "y": 0}, {"x": 1, "y": 0}]
	var dock := _origin() + Vector2(-CELL * 2.6, CELL)
	CargoDraw.draw(self, _cargo([]), bar, dock, CELL * 0.8)
	for c: Dictionary in bar:
		var r := Rect2(_at(2 + c["x"], 1), Vector2(CELL, CELL)).grow(-2)
		draw_rect(r, Color(Palette.GOOD, 0.25))
		draw_rect(r, Palette.GOOD, false, 2.0)
	draw_dashed_line(dock + Vector2(CELL * 1.7, CELL * 0.4), _at(2, 1.5), Palette.ACCENT, 3.0, 10.0)


## Page 2: a heavy cargo slides 3 cells into the wall. Its force is weight × cells.
func _draw_slide() -> void:
	var heavy := _cargo([], Defs.WEIGHT_HEAVY)
	CargoDraw.draw(self, heavy, _one(), _at(3, 1), CELL, 0.3)
	CargoDraw.draw(self, heavy, _one(), _at(0, 1), CELL)
	draw_line(_at(3.2, 1.5), _at(1.1, 1.5), Palette.WARN, 3.0)
	draw_colored_polygon(
		PackedVector2Array([_at(1.0, 1.5), _at(1.3, 1.3), _at(1.3, 1.7)]), Palette.WARN
	)
	var weight: int = heavy["weight_value"]
	var label := tr(FORCE_TEXT).format({"weight": weight, "cells": 3, "force": weight * 3})
	draw_string(
		ThemeDB.fallback_font, _at(4.2, 1.6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Palette.WARN
	)


## Page 3: an explosion breaks the cargo around it, and a leak shorts the cargo next to it.
func _draw_reactions() -> void:
	for y in 3:
		for x in 3:
			draw_rect(
				Rect2(_at(x, y), Vector2(CELL, CELL)), Color(Palette.TRAIT_COLORS["volatile"], 0.25)
			)
	CargoDraw.draw(self, _cargo([Defs.TRAIT_VOLATILE], Defs.WEIGHT_LIGHT), _one(), _at(1, 1), CELL)
	CargoDraw.draw(self, _cargo([], Defs.WEIGHT_STANDARD, Defs.KIND_SCRAP), _one(), _at(2, 0), CELL)
	CargoDraw.draw(self, _cargo([Defs.TRAIT_FLUID]), _one(), _at(4, 1), CELL)
	CargoDraw.draw(self, _cargo([], Defs.WEIGHT_LIGHT, Defs.KIND_SCRAP), _one(), _at(5, 1), CELL)
	CargoDraw.draw_icon(
		self, Defs.TRAIT_ELECTRONIC, _at(5.5, 1.5), 22.0, Palette.TRAIT_COLORS["electronic"]
	)


## Page 4: a Cooler and Perishable cargo, a Battery and a Shield, and a clamp.
func _draw_links() -> void:
	CargoDraw.draw(self, _cargo([Defs.TRAIT_COOLER]), _one(), _at(0, 0), CELL)
	CargoDraw.draw(self, _cargo([Defs.TRAIT_PERISHABLE]), _one(), _at(1, 0), CELL)
	draw_line(_at(0.5, 0.5), _at(1.5, 0.5), Palette.TRAIT_COLORS["cooler"], 3.0)
	CargoDraw.draw(self, _cargo([Defs.TRAIT_BATTERY]), _one(), _at(3, 0), CELL)
	CargoDraw.draw(self, _cargo([Defs.TRAIT_SHIELD]), _one(), _at(4, 0), CELL)
	draw_line(_at(3.5, 0.5), _at(4.5, 0.5), Palette.TRAIT_COLORS["battery"], 3.0)
	draw_arc(_at(4.5, 0.5), CELL * 0.9, 0, TAU, 40, Palette.TRAIT_COLORS["shield"], 2.0)
	var clamped := _cargo([], Defs.WEIGHT_HEAVY)
	clamped["clamped"] = true
	CargoDraw.draw(self, clamped, _one(), _at(2, 2), CELL)
