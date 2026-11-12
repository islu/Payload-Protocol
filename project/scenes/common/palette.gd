class_name Palette
## The colors of the sci-fi dashboard style (SPEC Section 4.2). Take each color
## of a drawn shape from here.

const BACKGROUND := Color("0b1020")
const PANEL := Color("131a30")
const PANEL_LINE := Color("2a3a66")
const GRID := Color("1c2747")
const GRID_LINE := Color("33467a")
const TEXT := Color("d8e4ff")
const TEXT_DIM := Color("7f8db3")
const ACCENT := Color("5fd3ff")
const GOOD := Color("4dff9a")
const BAD := Color("ff4d6a")
const WARN := Color("ffc84d")
const SCRAP := Color("5a6070")
const PLAIN := Color("8a9bb5")
const CLAMP := Color("ffb347")
const ZONE := Color(0.37, 0.83, 1.0, 0.18)

## One color for each trait (SPEC Section 4.2).
const TRAIT_COLORS := {
	"fragile": Color("7fdcff"),
	"volatile": Color("ff5a3c"),
	"fluid": Color("3c8cff"),
	"electronic": Color("ffd23c"),
	"perishable": Color("7ce05a"),
	"thruster": Color("b07cff"),
	"cushion": Color("ff9ad5"),
	"cooler": Color("a8f0ff"),
	"battery": Color("c8ff3c"),
	"shield": Color("3cffc8"),
}


## Returns the body color of a cargo view: its first trait, or plain, or scrap.
static func cargo_color(cargo: Dictionary) -> Color:
	if cargo.get("kind", "") == Defs.KIND_SCRAP:
		return SCRAP
	var traits: Array = cargo.get("traits", [])
	if traits.is_empty():
		return PLAIN
	return TRAIT_COLORS.get(traits[0], PLAIN)
