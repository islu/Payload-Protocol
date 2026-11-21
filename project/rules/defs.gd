class_name Defs
## The fixed strings of the rules. Compare with these constants, not with a
## literal string (SPEC Section 4.4 has the terms).

# Kinds (SPEC Section 6)
const KIND_FREIGHT := "freight"
const KIND_KIT := "kit"
const KIND_SCRAP := "scrap"
const KINDS: PackedStringArray = [KIND_FREIGHT, KIND_KIT, KIND_SCRAP]

# Weights (SPEC Section 6.1)
const WEIGHT_LIGHT := "light"
const WEIGHT_STANDARD := "standard"
const WEIGHT_HEAVY := "heavy"
const WEIGHTS: PackedStringArray = [WEIGHT_LIGHT, WEIGHT_STANDARD, WEIGHT_HEAVY]

# Traits (SPEC Section 7)
const TRAIT_FRAGILE := "fragile"
const TRAIT_VOLATILE := "volatile"
const TRAIT_FLUID := "fluid"
const TRAIT_ELECTRONIC := "electronic"
const TRAIT_PERISHABLE := "perishable"
const TRAIT_THRUSTER := "thruster"
const TRAIT_CUSHION := "cushion"
const TRAIT_COOLER := "cooler"
const TRAIT_BATTERY := "battery"
const TRAIT_SHIELD := "shield"
const TRAIT_SENSOR := "sensor"
const TRAITS: PackedStringArray = [
	TRAIT_FRAGILE,
	TRAIT_VOLATILE,
	TRAIT_FLUID,
	TRAIT_ELECTRONIC,
	TRAIT_PERISHABLE,
	TRAIT_THRUSTER,
	TRAIT_CUSHION,
	TRAIT_COOLER,
	TRAIT_BATTERY,
	TRAIT_SHIELD,
	TRAIT_SENSOR,
]
## The traits with a break limit (SPEC Section 7).
const LIMIT_TRAITS: PackedStringArray = [TRAIT_FRAGILE, TRAIT_VOLATILE, TRAIT_FLUID]

# Directions (SPEC Section 10.1)
const DIR_LEFT := "left"
const DIR_RIGHT := "right"
const DIR_UP := "up"
const DIR_DOWN := "down"
const DIRECTIONS: PackedStringArray = [DIR_LEFT, DIR_RIGHT, DIR_UP, DIR_DOWN]

# Phases (SPEC Section 3)
const PHASE_STATION := "station"
const PHASE_ARRIVAL := "arrival"
const PHASE_PAYMENT := "payment"
const PHASE_END := "end"
## A station that shows its event first (SPEC Section 26).
const PHASE_EVENT := "event"
## A mod choice (SPEC Section 27.1).
const PHASE_MOD := "mod"

# Effects of an event choice (SPEC Section 26.2)
const EFFECT_CREDITS := "credits"
const EFFECT_KIT := "kit"
const EFFECT_CLAMP := "clamp"
const EFFECT_SCRAP := "scrap"
const EFFECT_CONTRACT := "contract"
const EFFECT_MOD := "mod"
const EFFECT_PAYMENT := "payment"
const EFFECT_ADD_STEP := "add_step"
const EFFECT_REMOVE_STEP := "remove_step"
const EFFECT_ADD_INCIDENT := "add_incident"
const EFFECT_CANCEL_INCIDENT := "cancel_incident"
const EFFECT_CLEAR_SCRAP := "clear_scrap"
const EFFECTS: PackedStringArray = [
	EFFECT_CREDITS,
	EFFECT_KIT,
	EFFECT_CLAMP,
	EFFECT_SCRAP,
	EFFECT_CONTRACT,
	EFFECT_MOD,
	EFFECT_PAYMENT,
	EFFECT_ADD_STEP,
	EFFECT_REMOVE_STEP,
	EFFECT_ADD_INCIDENT,
	EFFECT_CANCEL_INCIDENT,
	EFFECT_CLEAR_SCRAP,
]

# Route environments (SPEC Section 28.2)
const ENV_LOW_GRAVITY := "low_gravity"
const ENV_MAGNETIC_STORM := "magnetic_storm"
const ENV_RADIATION_BELT := "radiation_belt"
const ENV_HEAT_ZONE := "heat_zone"
const ENVIRONMENTS: PackedStringArray = [
	ENV_LOW_GRAVITY, ENV_MAGNETIC_STORM, ENV_RADIATION_BELT, ENV_HEAT_ZONE
]

# Incidents (SPEC Section 29.2)
const INCIDENT_METEOR := "meteor"
const INCIDENT_ION_PULSE := "ion_pulse"
const INCIDENT_HULL_BREACH := "hull_breach"
const INCIDENTS: PackedStringArray = [INCIDENT_METEOR, INCIDENT_ION_PULSE, INCIDENT_HULL_BREACH]

# Mods (SPEC Section 27.2)
const MOD_SHOCK_FLOOR := "shock_floor"
const MOD_CRYO_LINE := "cryo_line"
const MOD_PADDED_WALLS := "padded_walls"
const MOD_GRAVITY_DAMPER := "gravity_damper"
const MOD_ARRAY_POWER := "array_power"
const MOD_INSURANCE := "insurance"
const MODS: PackedStringArray = [
	MOD_SHOCK_FLOOR,
	MOD_CRYO_LINE,
	MOD_PADDED_WALLS,
	MOD_GRAVITY_DAMPER,
	MOD_ARRAY_POWER,
	MOD_INSURANCE,
]

# Reactions (SPEC Section 11)
const REACT_BREAK := "break"
const REACT_EXPLOSION := "explosion"
const REACT_LEAK := "leak"
const REACT_SHORT := "short"
## A freight or a kit in a blast area that becomes scrap.
const REACT_BLAST := "blast"
## A scrap in a blast area that is removed.
const REACT_CLEAR := "clear"
## A reaction that a Shield canceled.
const REACT_SHIELD := "shield"

# Pieces of a contract at the arrival (SPEC Section 20.4)
const PIECE_DELIVERED := "delivered"
const PIECE_SCRAP := "scrap"
const PIECE_SPOILED := "spoiled"
## A freight that an explosion removed.
const PIECE_LOST := "lost"
const PIECE_BREACHED := "breached"

# Bonus conditions (SPEC Section 15.3)
const BONUS_ALL_INTACT := "all_intact"
const BONUS_ZONE := "zone"
const BONUS_NOT_NEXT_TO := "not_next_to"
const BONUSES: PackedStringArray = [BONUS_ALL_INTACT, BONUS_ZONE, BONUS_NOT_NEXT_TO]

# Sides of a zone (SPEC Section 15.3)
const SIDE_LEFT := "left"
const SIDE_RIGHT := "right"
const SIDE_TOP := "top"
const SIDE_BOTTOM := "bottom"
const SIDES: PackedStringArray = [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]

# Links (SPEC Section 12.3)
const LINK_COLD := "cold"
const LINK_POWER := "power"

# Line events of the pilot (SPEC Section 22)
const LINE_HAZARD := "hazard"
const LINE_ALL_INTACT := "all_intact"
const LINE_BREAK := "break"
const LINE_EXPLOSION := "explosion"
const LINE_CHAIN := "chain"
const LINE_LEAK := "leak"
const LINE_SPOIL := "spoil"
const LINE_EMPTY := "empty"
const LINE_PAYMENT := "payment"
const LINE_WIN := "win"
const LINE_LOSE := "lose"
const LINE_EVENTS: PackedStringArray = [
	LINE_HAZARD,
	LINE_ALL_INTACT,
	LINE_BREAK,
	LINE_EXPLOSION,
	LINE_CHAIN,
	LINE_LEAK,
	LINE_SPOIL,
	LINE_EMPTY,
	LINE_PAYMENT,
	LINE_WIN,
	LINE_LOSE,
]

## The state of a mass: at the limit or less, above the limit (a fuel fee), or above
## the maximum (no warp) (SPEC Section 25).
const MASS_OK := "ok"
const MASS_FEE := "fee"
const MASS_OVER := "over"

## What a reaction does to its cargo (SPEC Sections 11 and 21): it becomes scrap, it
## leaves the hold, or it stays (a Shield canceled the reaction).
const RESULT_SCRAP := "scrap"
const RESULT_REMOVED := "removed"
const RESULT_KEPT := "kept"

## The actions of the player. A recorded action is {name, args} (RunRecord).
const ACT_PLACE := "place"
const ACT_LOAD_ALL := "load_all"
const ACT_DOCK := "dock"
const ACT_ROTATE := "rotate"
const ACT_CLAMP := "clamp"
const ACT_UNCLAMP := "unclamp"
const ACT_ACCEPT := "accept"
const ACT_CANCEL := "cancel"
const ACT_BUY_KIT := "buy_kit"
const ACT_REROLL := "reroll"
const ACT_BUY_CLAMP := "buy_clamp"
const ACT_REINFORCE := "reinforce"
const ACT_BUY_BAY := "buy_bay"
const ACT_SELL_KIT := "sell_kit"
const ACT_CLEAR_SCRAP := "clear_scrap"
const ACT_WARP := "warp"
const ACT_CONTINUE := "continue"
const ACT_PAY := "pay"
const ACT_CHOOSE_EVENT := "choose_event"
const ACT_CHOOSE_MOD := "choose_mod"

## The actions that end a step of the tutorial (SPEC Section 23.4). TUT_NEXT is the Next
## button of a step with no action.
const TUT_NEXT := "next"
const TUT_ACCEPT := "accept"
const TUT_ALL_IN_HOLD := "all_in_hold"
const TUT_ROTATE := "rotate"
const TUT_CLAMP := "clamp"
const TUT_BUY := "buy"
const TUT_FRESH := "fresh"
const TUT_WARP := "warp"
const TUT_CONTINUE := "continue"
const TUT_PAY := "pay"
const TUT_UNTILS: PackedStringArray = [
	TUT_NEXT,
	TUT_ACCEPT,
	TUT_ALL_IN_HOLD,
	TUT_ROTATE,
	TUT_CLAMP,
	TUT_BUY,
	TUT_FRESH,
	TUT_WARP,
	TUT_CONTINUE,
	TUT_PAY,
]
## The step actions that name a cargo definition in "cargo".
const TUT_WITH_CARGO: PackedStringArray = [TUT_ROTATE, TUT_BUY]
## The kinds of the target of a tutorial step: the screen shows it bright (SPEC Section 23.4).
const TARGETS: PackedStringArray = [
	"none", "contract", "cargo", "cell", "button", "hazard", "shop", "clamps", "top_bar"
]

# --- Contract tags (SPEC Section 30.4) ---

const TAG_BLACK_MARKET := "black_market"
## The tags that a contract template can have.
const CONTRACT_TAGS: PackedStringArray = [TAG_BLACK_MARKET]


## Returns the cell step of a direction.
static func delta(direction: String) -> Vector2i:
	match direction:
		DIR_LEFT:
			return Vector2i.LEFT
		DIR_RIGHT:
			return Vector2i.RIGHT
		DIR_UP:
			return Vector2i.UP
		DIR_DOWN:
			return Vector2i.DOWN
	return Vector2i.ZERO
