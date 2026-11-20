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
## The amber of the icon and of the first word of the title (SPEC Section 20.1).
const TITLE_AMBER := Color("ffba46")
const GOOD := Color("4dff9a")
const BAD := Color("ff4d6a")
const WARN := Color("ffc84d")
const SCRAP := Color("5a6070")
const PLAIN := Color("8a9bb5")
const CLAMP := Color("ffb347")
## The color of a black market contract (SPEC Section 30.4).
const BLACK_MARKET := Color("b77dff")
const ZONE := Color(0.37, 0.83, 1.0, 0.18)

## One color for each trait (SPEC Section 4.2).
const TRAIT_COLORS := {
	Defs.TRAIT_FRAGILE: Color("7fdcff"),
	Defs.TRAIT_VOLATILE: Color("ff5a3c"),
	Defs.TRAIT_FLUID: Color("3c8cff"),
	Defs.TRAIT_ELECTRONIC: Color("ffd23c"),
	Defs.TRAIT_PERISHABLE: Color("7ce05a"),
	Defs.TRAIT_THRUSTER: Color("b07cff"),
	Defs.TRAIT_CUSHION: Color("ff9ad5"),
	Defs.TRAIT_COOLER: Color("a8f0ff"),
	Defs.TRAIT_BATTERY: Color("c8ff3c"),
	Defs.TRAIT_SHIELD: Color("3cffc8"),
}


## Returns the color of a trait, or Palette.TEXT for a trait with no color.
static func trait_color(trait_id: String) -> Color:
	return TRAIT_COLORS.get(trait_id, TEXT)


## Returns the color of a link: the Cooler color for a cold link, else the Battery color.
static func link_color(kind: String) -> Color:
	return TRAIT_COLORS[Defs.TRAIT_COOLER if kind == Defs.LINK_COLD else Defs.TRAIT_BATTERY]


## Returns the body color of a cargo view: its first trait, or plain, or scrap.
static func cargo_color(cargo: Dictionary) -> Color:
	if cargo.get("kind", "") == Defs.KIND_SCRAP:
		return SCRAP
	var traits: Array = cargo.get("traits", [])
	if traits.is_empty():
		return PLAIN
	return TRAIT_COLORS.get(traits[0], PLAIN)
