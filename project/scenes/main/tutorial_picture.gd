class_name TutorialPicture
extends Control
## The picture of a How to Play page (SPEC Section 23.2): a small hold drawn with
## CargoDraw. The pictures are examples only. Their numbers come from the view.

const CELL := 84.0
const COLUMNS := 6
const ROWS := 3
const FORCE_TEXT := "{weight} × {cells} = {force}"
## The cargo of each page: the definition IDs, so that the pictures show the cargo
## images of SPEC Section 4.2.
const PAGE_CARGO := [
	["steel_ingot"],
	["steel_ingot"],
	["plasma_cell", "energy_crystal", "antique_soda", "helper_bot"],
	["cooler_unit", "space_cheese", "battery_pack", "shield_generator", "cargo_crate"],
]

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


func _cargo(
	def_id: String, traits: Array, weight := Defs.WEIGHT_STANDARD, kind := Defs.KIND_FREIGHT
) -> Dictionary:
	return {
		"def_id": def_id,
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
	var bar := _line(2, true)
	var dock := _origin() + Vector2(-CELL * 2.6, CELL)
	CargoDraw.draw(self, _cargo("steel_ingot", [], Defs.WEIGHT_HEAVY), bar, dock, CELL * 0.8)
	for c: Dictionary in bar:
		var r := Rect2(_at(2 + c["x"], 1), Vector2(CELL, CELL)).grow(-2)
		draw_rect(r, Color(Palette.GOOD, 0.25))
		draw_rect(r, Palette.GOOD, false, 2.0)
	draw_dashed_line(dock + Vector2(CELL * 1.7, CELL * 0.4), _at(2, 1.5), Palette.ACCENT, 3.0, 10.0)


## Page 2: a heavy cargo slides 3 cells into the wall. Its force is weight × cells.
func _draw_slide() -> void:
	var heavy := _cargo("steel_ingot", [], Defs.WEIGHT_HEAVY)
	CargoDraw.draw(self, heavy, _line(2, true), _at(3, 1), CELL, 0.3)
	CargoDraw.draw(self, heavy, _line(2, true), _at(0, 1), CELL)
	draw_line(_at(3.2, 1.5), _at(2.1, 1.5), Palette.WARN, 3.0)
	draw_colored_polygon(
		PackedVector2Array([_at(2.0, 1.5), _at(2.3, 1.3), _at(2.3, 1.7)]), Palette.WARN
	)
	var weight: int = heavy["weight_value"]
	var label := tr(FORCE_TEXT).format({"weight": weight, "cells": 3, "force": weight * 3})
	draw_string(
		ThemeDB.fallback_font, _at(5.2, 1.6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Palette.WARN
	)


## Page 3: an explosion breaks the cargo around it, and a leak shorts the cargo next to it.
func _draw_reactions() -> void:
	for y in 3:
		for x in 3:
			draw_rect(
				Rect2(_at(x, y), Vector2(CELL, CELL)),
				Color(Palette.TRAIT_COLORS[Defs.TRAIT_VOLATILE], 0.25)
			)
	var bomb := _cargo("plasma_cell", [Defs.TRAIT_VOLATILE], Defs.WEIGHT_LIGHT)
	CargoDraw.draw(self, bomb, _one(), _at(1, 1), CELL)
	var broken := _cargo("energy_crystal", [], Defs.WEIGHT_LIGHT, Defs.KIND_SCRAP)
	CargoDraw.draw(self, broken, _one(), _at(2, 0), CELL)
	var soda := _cargo("antique_soda", [Defs.TRAIT_FLUID], Defs.WEIGHT_LIGHT)
	CargoDraw.draw(self, soda, _one(), _at(4, 1), CELL)
	var bot := _cargo("helper_bot", [], Defs.WEIGHT_STANDARD, Defs.KIND_SCRAP)
	CargoDraw.draw(self, bot, _one(), _at(5, 1), CELL)
	CargoDraw.draw_icon(
		self,
		Defs.TRAIT_ELECTRONIC,
		_at(5.5, 1.5),
		22.0,
		Palette.TRAIT_COLORS[Defs.TRAIT_ELECTRONIC]
	)


## Page 4: a Cooler and Perishable cargo, a Battery and a Shield, and a clamp.
func _draw_links() -> void:
	CargoDraw.draw(
		self, _cargo("cooler_unit", [Defs.TRAIT_COOLER]), _line(2, false), _at(0, 0), CELL
	)
	CargoDraw.draw(self, _cargo("space_cheese", [Defs.TRAIT_PERISHABLE]), _one(), _at(1, 0), CELL)
	draw_line(_at(0.5, 0.5), _at(1.5, 0.5), Palette.TRAIT_COLORS[Defs.TRAIT_COOLER], 3.0)
	CargoDraw.draw(self, _cargo("battery_pack", [Defs.TRAIT_BATTERY]), _one(), _at(3, 0), CELL)
	CargoDraw.draw(self, _cargo("shield_generator", [Defs.TRAIT_SHIELD]), _one(), _at(4, 0), CELL)
	draw_line(_at(3.5, 0.5), _at(4.5, 0.5), Palette.TRAIT_COLORS[Defs.TRAIT_BATTERY], 3.0)
	draw_arc(_at(4.5, 0.5), CELL * 0.9, 0, TAU, 40, Palette.TRAIT_COLORS[Defs.TRAIT_SHIELD], 2.0)
	var clamped := _cargo("cargo_crate", [])
	clamped["clamped"] = true
	CargoDraw.draw(self, clamped, _one(), _at(2, 2), CELL)


## A line of cells: a row, or a column.
func _line(n: int, row: bool) -> Array:
	var out := []
	for i in n:
		out.append({"x": i if row else 0, "y": 0 if row else i})
	return out
